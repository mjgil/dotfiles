#!/usr/bin/env bash
# Import logging utilities
# Define logging functions
function log_info() { echo -e "\\033[0;34m[INFO]\\033[0m $1"; }
function log_success() { echo -e "\\033[0;32m[SUCCESS]\\033[0m $1"; }
function log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m $1"; }
function log_error() { echo -e "\\033[0;31m[ERROR]\\033[0m $1"; }

# This script determines the Linux distribution and executes the appropriate setup script

# Detect the Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=$ID
    log_info "Detected distribution: $DISTRO_ID"
else
    log_info "Cannot detect the Linux distribution. Exiting."
    exit 1
fi

# Execute the appropriate distribution-specific script
case "$DISTRO_ID" in
    "ubuntu")
        log_info "Running Ubuntu-specific setup..."
        bash "$(dirname "$0")/ubuntu.sh"
        ;;
    "linuxmint")
        log_info "Running Linux Mint-specific setup..."
        bash "$(dirname "$0")/linuxmint.sh"
        ;;
    "debian")
        log_info "Running Debian-specific setup..."
        bash "$(dirname "$0")/ubuntu.sh"  # Use Ubuntu script for Debian as well
        ;;
    *)
        log_info "No specific setup script for $DISTRO_ID. Using Ubuntu setup as fallback."
        bash "$(dirname "$0")/ubuntu.sh"
        ;;
esac

log_info "Distribution-specific setup completed."