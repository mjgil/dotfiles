#!/usr/bin/env bash
# Linux-specific local installation script for dotfiles

# Exit immediately if a command exits with a non-zero status
set -e

# Import logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../shared/log_utils.sh"

# Check if the source directory is set
if [ -z "$DOTFILES_SOURCE_DIR" ]; then
    log_error "DOTFILES_SOURCE_DIR environment variable is not set"
    log_info "Please run this script through install-local.sh in the root directory"
    exit 1
fi

# Set dry run mode based on environment variable
DRY_RUN=${DOTFILES_DRY_RUN:-false}

log_info "Starting Linux dotfiles installation from local directory: $DOTFILES_SOURCE_DIR"

# Function to execute a script with dry run support
execute_script() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")
    
    if [ ! -f "$script_path" ]; then
        log_error "Script not found: $script_path"
        return 1
    fi
    
    log_info "Executing $script_name..."
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would execute: $script_path"
    else
        # Set environment variable to indicate this is a local installation
        export LOCAL_INSTALL=true
        export DOTFILES_ROOT="$DOTFILES_SOURCE_DIR"
        # Execute the script directly with the full path
        cd "$DOTFILES_SOURCE_DIR" && bash "$script_path"
    fi
}

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

# Execute bootstrap.sh to install yq
execute_script "$DOTFILES_SOURCE_DIR/shared/bootstrap.sh"

# Execute scripts in the correct order
log_info "Installing packages..."
execute_script "$DOTFILES_SOURCE_DIR/shared/install-packages.sh"

log_info "Executing Linux shared script..."
execute_script "$DOTFILES_SOURCE_DIR/linux/shared.sh"

log_info "Executing distribution-specific setup..."
execute_script "$DOTFILES_SOURCE_DIR/linux/distro-setup.sh"

log_info "Executing shared setup across platforms..."
execute_script "$DOTFILES_SOURCE_DIR/shared/shared.sh"

log_info "Setting up package blocking for ASDF..."
execute_script "$DOTFILES_SOURCE_DIR/shared/create-package-blockers.sh"
execute_script "$DOTFILES_SOURCE_DIR/shared/install-apt-hooks.sh"

log_success "Linux dotfiles installation completed successfully!"
