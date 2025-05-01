#!/usr/bin/env bash

# This script determines the Linux distribution and executes the appropriate setup script

# Detect the Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=$ID
    echo "Detected distribution: $DISTRO_ID"
else
    echo "Cannot detect the Linux distribution. Exiting."
    exit 1
fi

# Execute the appropriate distribution-specific script
case "$DISTRO_ID" in
    "ubuntu")
        echo "Running Ubuntu-specific setup..."
        bash "$(dirname "$0")/ubuntu.sh"
        ;;
    "linuxmint")
        echo "Running Linux Mint-specific setup..."
        bash "$(dirname "$0")/linuxmint.sh"
        ;;
    "debian")
        echo "Running Debian-specific setup..."
        bash "$(dirname "$0")/ubuntu.sh"  # Use Ubuntu script for Debian as well
        ;;
    *)
        echo "No specific setup script for $DISTRO_ID. Using Ubuntu setup as fallback."
        bash "$(dirname "$0")/ubuntu.sh"
        ;;
esac

echo "Distribution-specific setup completed."