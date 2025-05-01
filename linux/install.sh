#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status
set -e

# Define the base URL where the scripts are hosted
BASE_URL="https://raw.githubusercontent.com/mjgil/dotfiles/master"

# Temporary directory to store downloaded scripts
TEMP_DIR=$(mktemp -d)

# Function to clean up temporary files on exit
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Function to download a script
# Note: Log functions are not available until log_utils is sourced
download_script() {
    local source_path=$1
    local target_name=$2
    local target_path="$TEMP_DIR/$target_name"
    
    echo "[INFO] Downloading $target_name..." # Use echo before log utils are sourced
    wget -q "$BASE_URL/$source_path" -O "$target_path"
    chmod +x "$target_path"
}

# Download and source log_utils first
download_script "shared/log_utils.sh" "log_utils.sh"
source "$TEMP_DIR/log_utils.sh"

log_info "Starting Linux installation..."

# Download other shared scripts
download_script "shared/bootstrap.sh" "bootstrap.sh"
download_script "shared/shared.sh" "shared.sh"
# Download the JSON package file instead of YAML
download_script "shared/packages.json" "packages.json"
download_script "shared/install-packages.sh" "install-packages.sh"
download_script "shared/create-package-blockers.sh" "create-package-blockers.sh"
download_script "shared/install-apt-hooks.sh" "install-apt-hooks.sh"

# Execute bootstrap.sh to install jq/yq dependencies
log_info "Executing bootstrap.sh..."

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
# Pass TEMP_DIR so bootstrap knows where packages.json is
bash "$TEMP_DIR/bootstrap.sh" "$TEMP_DIR"

# Detect the Linux distribution
log_info "Detecting Linux distribution..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=$ID
else
    log_error "Cannot detect the Linux distribution. Exiting."
    exit 1
fi
log_info "Detected distribution: $DISTRO_ID"

# Download Linux-specific scripts
download_script "linux/shared.sh" "linux_shared.sh"
download_script "linux/distro-setup.sh" "distro-setup.sh"
download_script "linux/ubuntu.sh" "ubuntu.sh"
download_script "linux/linuxmint.sh" "linuxmint.sh"

# Execute scripts in the correct order
log_info "Installing packages..."
# Pass TEMP_DIR so install-packages knows where packages.json is
bash "$TEMP_DIR/install-packages.sh"

log_info "Executing Linux shared script..."
bash "$TEMP_DIR/linux_shared.sh"

log_info "Executing distribution-specific setup..."
# Pass TEMP_DIR so distro-setup knows where other scripts are
bash "$TEMP_DIR/distro-setup.sh"

log_info "Executing shared setup across platforms..."
# Pass TEMP_DIR so shared.sh knows where other scripts are
bash "$TEMP_DIR/shared.sh"

log_info "Setting up package blocking for ASDF..."
# Pass TEMP_DIR so these scripts know where packages.json is
bash "$TEMP_DIR/create-package-blockers.sh"
bash "$TEMP_DIR/install-apt-hooks.sh"

log_success "Setup completed successfully."
