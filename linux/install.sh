#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define the base URL where the scripts are hosted
BASE_URL="https://raw.githubusercontent.com/mjgil/dotfiles/master/linux"

# Temporary directory to store downloaded scripts
TEMP_DIR=$(mktemp -d)

# Function to clean up temporary files on exit
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "Starting setup..."

# Download shared.sh
echo "Downloading shared.sh..."
wget -q "$BASE_URL/shared.sh" -O "$TEMP_DIR/shared.sh"
chmod +x "$TEMP_DIR/shared.sh"

# Detect the Linux distribution
echo "Detecting Linux distribution..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=$ID
else
    echo "Cannot detect the Linux distribution. Exiting."
    exit 1
fi
echo "Detected distribution: $DISTRO_ID"

# Download distribution-specific script
if [ "$DISTRO_ID" = "ubuntu" ]; then
    echo "Downloading ubuntu.sh..."
    wget -q "$BASE_URL/ubuntu.sh" -O "$TEMP_DIR/ubuntu.sh"
    chmod +x "$TEMP_DIR/ubuntu.sh"
elif [ "$DISTRO_ID" = "linuxmint" ]; then
    echo "Downloading linuxmint.sh..."
    wget -q "$BASE_URL/linuxmint.sh" -O "$TEMP_DIR/linuxmint.sh"
    chmod +x "$TEMP_DIR/linuxmint.sh"
else
    echo "Unsupported distribution: $DISTRO_ID. Exiting."
    exit 1
fi

# Execute shared.sh
echo "Executing shared.sh..."
bash "$TEMP_DIR/shared.sh"

# Execute distribution-specific script
if [ "$DISTRO_ID" = "ubuntu" ]; then
    echo "Executing ubuntu.sh..."
    bash "$TEMP_DIR/ubuntu.sh"
elif [ "$DISTRO_ID" = "linuxmint" ]; then
    echo "Executing linuxmint.sh..."
    bash "$TEMP_DIR/linuxmint.sh"
fi

echo "Setup completed successfully."
