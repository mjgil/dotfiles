#!/usr/bin/env bash

# debug-install-loop.sh - Runs installation and checks in a loop until stable.

# Import logging utilities from log_utils.sh if it exists in shared/
SCRIPT_PARENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_UTILS="${SCRIPT_PARENT_DIR}/shared/log_utils.sh"

if [[ -f "$LOG_UTILS" ]]; then
  source "$LOG_UTILS"
else
  # Fallback logging functions
  function log_info() { echo -e "\\033[0;34m[INFO]\\033[0m $1"; }
  function log_success() { echo -e "\\033[0;32m[SUCCESS]\\033[0m $1"; }
  function log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m $1"; }
  function log_error() { echo -e "\\033[0;31m[ERROR]\\033[0m $1"; }
fi

# Exit on error within the loop iterations where appropriate
# set -e # Disabled globally to allow capturing check script exit status

MAX_ITERATIONS=5
CHECK_SCRIPT="./check_installed_orig.sh"
INSTALL_SCRIPT="./install-local.sh"
SOURCE_DIR="." # Assuming current directory is the dotfiles root

# Function to run check_installed_orig.sh and extract failed packages
get_failed_packages() {
    local output_file
    output_file=$(mktemp)
    local failed_list=""
    # Run the check script, redirect stderr to stdout to capture all output, allow non-zero exit code
    if bash "$CHECK_SCRIPT" > "$output_file" 2>&1; then
        # Zero exit code means no failures
        failed_list=""
    else
        # Non-zero exit code, extract failed packages
        failed_list=$(awk '/Programs not installed:/{flag=1; next} /^$/{flag=0} flag {gsub(/\\033\[[0-9;]*m/, ""); sub(/^- /, ""); print}' "$output_file" | sort)
    fi
    rm "$output_file"
    echo "$failed_list"
}


log_info "Starting debug installation loop..."
log_info "Check script: $CHECK_SCRIPT"
log_info "Install script: $INSTALL_SCRIPT -s $SOURCE_DIR"
log_info "Max iterations: $MAX_ITERATIONS"

previous_failed_packages=""
current_failed_packages=""

for (( i=1; i<=MAX_ITERATIONS; i++ )); do
    log_info "--- Iteration $i/$MAX_ITERATIONS ---"

    log_info "Running check script BEFORE installation..."
    current_failed_packages=$(get_failed_packages)

    if [[ -z "$current_failed_packages" ]]; then
        log_success "No packages reported as missing by $CHECK_SCRIPT. Loop finished."
        break
    fi

    log_info "Packages reported as missing:"
    echo "$current_failed_packages" | sed 's/^/  - /'

    # Check for stability
    if [[ $i -gt 1 && "$current_failed_packages" == "$previous_failed_packages" ]]; then
        log_success "List of missing packages is stable. Loop finished."
        log_warning "The following packages remained missing:"
        echo "$current_failed_packages" | sed 's/^/  - /'
        break
    fi

    previous_failed_packages="$current_failed_packages"

    log_info "Running install script: $INSTALL_SCRIPT -s $SOURCE_DIR"
    if bash "$INSTALL_SCRIPT" -s "$SOURCE_DIR"; then
        log_success "Install script completed successfully."
    else
        log_error "Install script failed with exit code $?. Check logs."
        # Decide whether to continue or stop on install failure
        # continue # Option: Continue to next iteration check
        break    # Option: Stop loop on install failure
    fi

    # Optional: Add a small delay
    # sleep 2

    if [[ $i -eq $MAX_ITERATIONS ]]; then
        log_warning "Reached maximum iterations ($MAX_ITERATIONS)."
        log_info "Running final check..."
        current_failed_packages=$(get_failed_packages)
        log_info "Packages reported as missing after final run:"
        echo "$current_failed_packages" | sed 's/^/  - /'
    fi
done

log_info "Debug installation loop finished."

# Report final state based on last check
if [[ -z "$current_failed_packages" ]]; then
    log_success "All checked packages appear to be installed."
    exit 0
else
    log_warning "Some packages may still be missing or failed to install."
    exit 1 # Indicate potential issues
fi 