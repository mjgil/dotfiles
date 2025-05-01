#!/usr/bin/env bash
# Mac-specific local installation script for dotfiles

# Exit on error
set -e

# Define logging functions
function log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
function log_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
function log_warning() { echo -e "\033[0;33m[WARNING]\033[0m $1"; }
function log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# Check if the source directory is set
if [ -z "$DOTFILES_SOURCE_DIR" ]; then
    log_error "DOTFILES_SOURCE_DIR environment variable is not set"
    log_info "Please run this script through install-local.sh in the root directory"
    exit 1
fi

# Set dry run mode based on environment variable
DRY_RUN=${DOTFILES_DRY_RUN:-false}

log_info "Starting Mac dotfiles installation from local directory: $DOTFILES_SOURCE_DIR"

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
        # Change to the script's directory to ensure relative paths work
        (cd "$(dirname "$script_path")" && bash "$(basename "$script_path")") 
    fi
}

# Ensure Command Line Tools are installed
if ! xcode-select -p &>/dev/null; then
    log_info "Xcode Command Line Tools are not installed. Proceeding with installation..."
    # Create the marker file to enable installation via softwareupdate
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    # Install the Command Line Tools
    log_info "Finding Xcode Software Name..."
    UPDATE_LABEL=$(softwareupdate --list | \
                    awk -F: '/^ *\* Label: / {print $2}' | \
                    grep -i "Command Line Tools for Xcode" | \
                    head -n 1 | \
                    xargs)
    log_info "Name Found: $UPDATE_LABEL"
    log_info "Installing Xcode Command Line Tools..."
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would install: $UPDATE_LABEL"
    else
        softwareupdate --install "$UPDATE_LABEL" --verbose
    fi

    # Remove the marker file
    rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    # Verify installation
    if ! $DRY_RUN && ! xcode-select -p &>/dev/null; then
        log_error "Failed to install Xcode Command Line Tools."
        exit 1
    fi
fi

# Install Rosetta for Apple Silicon Macs
if [[ $(uname -p) == 'arm' ]]; then
    log_info "Installing Rosetta for Apple Silicon..."
    if $DRY_RUN; then
        log_info "[DRY RUN] Would install Rosetta"
    else
        softwareupdate --install-rosetta --agree-to-license
    fi
fi

# Install Homebrew if it doesn't exist
if ! command -v brew >/dev/null 2>&1; then
    log_info "Installing Homebrew..."
    if $DRY_RUN; then
        log_info "[DRY RUN] Would install Homebrew"
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH if needed
        if [[ $(uname -p) == 'arm' ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
fi

# Setup Git configuration
log_info "Setting up Git configuration..."
if $DRY_RUN; then
    log_info "[DRY RUN] Would configure Git"
else
    git config --global user.name "Malcom Gilbert"
    git config --global user.email malcomgilbert@gmail.com
    git config --global core.editor "subl -n -w"
    git config --global push.default matching
    git config --global core.excludesfile ~/.gitignore
    echo "*.DS_Store" >> ~/.gitignore

    if [ ! -f ~/.git-prompt.sh ]; then
        curl -o ~/.git-prompt.sh \
        https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
    fi
fi

# Run bootstrap script
execute_script "$DOTFILES_SOURCE_DIR/shared/bootstrap.sh"

# Run the package installer
log_info "Installing packages from YAML definition..."
execute_script "$DOTFILES_SOURCE_DIR/shared/install-packages.sh"

# Install Mac-specific applications
log_info "Installing Mac-specific applications..."
execute_script "$DOTFILES_SOURCE_DIR/mac/install-programs-and-apps.sh"

# Configure Mac OS defaults
log_info "Configuring Mac OS defaults..."
execute_script "$DOTFILES_SOURCE_DIR/mac/install-defaults.sh"

# Update bash configuration
log_info "Updating bash configuration..."
execute_script "$DOTFILES_SOURCE_DIR/mac/update-bashrc.sh"

log_success "Mac dotfiles installation completed successfully!"
