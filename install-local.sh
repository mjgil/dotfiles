#!/usr/bin/env bash
# Local installation script for dotfiles
# This script allows installing dotfiles from a local directory instead of pulling from GitHub

# Set strict error handling
set -e

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Import logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/shared/log_utils.sh"

# Use our yq wrapper to suppress "open ==" errors
export PATH="/home/m/git/dotfiles:$PATH"

# Function to show usage/help
show_help() {
    echo "Usage: ./install-local.sh [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -s, --source DIR        Specify local source directory (default: current directory)"
    echo "  -o, --os [linux|mac]    Specify the operating system (auto-detected if not provided)"
    echo "  -d, --dry-run           Show what would be done without making changes"
    echo
    echo "Examples:"
    echo "  ./install-local.sh                     # Install from current directory"
    echo "  ./install-local.sh -s ~/my-dotfiles    # Install from specified directory"
    echo "  ./install-local.sh -o linux            # Force Linux installation"
    echo
}

# Parse command line arguments
SOURCE_DIR="$(pwd)"
OS_TYPE=""
DRY_RUN=false
extra_args=() # Array to hold non-option arguments

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--source)
            if [[ -n "$2" && "$2" != -* ]]; then
                SOURCE_DIR="$2"
                shift 2
            else
                log_error "Error: Argument for $1 is missing"
                show_help
                exit 1
            fi
            ;;
        -o|--os)
            if [[ -n "$2" && "$2" != -* ]]; then
                OS_TYPE="$2"
                shift 2
            else
                log_error "Error: Argument for $1 is missing"
                show_help
                exit 1
            fi
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            # Store unrecognized arguments instead of erroring
            extra_args+=("$1")
            shift
            ;;
    esac
done

# Ensure source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    log_error "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Auto-detect OS if not specified
if [ -z "$OS_TYPE" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="mac"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
    else
        log_error "Unable to detect OS type. Please specify with -o option."
        exit 1
    fi
fi

log_info "Starting dotfiles installation from local directory"
log_info "Source directory: $SOURCE_DIR"
log_info "Operating system: $OS_TYPE"
if $DRY_RUN; then
    log_info "Dry run mode: no changes will be made"
fi

# Check if the source directory has the required structure
if [ ! -d "$SOURCE_DIR/shared" ] || [ ! -d "$SOURCE_DIR/$OS_TYPE" ]; then
    log_error "Source directory does not appear to be a valid dotfiles repository. Missing 'shared' or '$OS_TYPE' directory."
    exit 1
fi

# Execute the appropriate OS-specific installation script
if [ "$OS_TYPE" == "linux" ]; then
    log_info "Running Linux installation from local directory..."
    
    # Define bash variables to pass to subsequent scripts
    export DOTFILES_SOURCE_DIR="$SOURCE_DIR"
    export DOTFILES_DRY_RUN="$DRY_RUN"
    
    # Execute the Linux local installation script, passing extra args
    bash "$SOURCE_DIR/linux/install-local.sh" "${extra_args[@]}"
    
elif [ "$OS_TYPE" == "mac" ]; then
    log_info "Running Mac installation from local directory..."
    
    # Define bash variables to pass to subsequent scripts
    export DOTFILES_SOURCE_DIR="$SOURCE_DIR"
    export DOTFILES_DRY_RUN="$DRY_RUN"
    
    # Execute the Mac local installation script, passing extra args
    bash "$SOURCE_DIR/mac/install-local.sh" "${extra_args[@]}"
    
else
    log_error "Unsupported OS type: $OS_TYPE"
    exit 1
fi

log_success "Local installation completed successfully!"
