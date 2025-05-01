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

# Function to download a script with progress indicator
download_script() {
    local source_path=$1
    local target_name=$2
    local target_path="$TEMP_DIR/$target_name"
    
    echo "Downloading $target_name..."
    wget -q "$BASE_URL/$source_path" -O "$target_path"
    chmod +x "$target_path"
}

echo "Starting setup..."

# Download shared scripts
download_script "shared/bootstrap.sh" "bootstrap.sh"
download_script "shared/shared.sh" "shared.sh"
download_script "shared/packages.yml" "packages.yml"
download_script "shared/install-packages.sh" "install-packages.sh"
download_script "shared/create-package-blockers.sh" "create-package-blockers.sh"
download_script "shared/install-apt-hooks.sh" "install-apt-hooks.sh"

# Execute bootstrap.sh to install yq
echo "Executing bootstrap.sh..."
bash "$TEMP_DIR/bootstrap.sh"

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

# Download Linux-specific scripts
download_script "linux/shared.sh" "linux_shared.sh"
download_script "linux/distro-setup.sh" "distro-setup.sh"
download_script "linux/ubuntu.sh" "ubuntu.sh"
download_script "linux/linuxmint.sh" "linuxmint.sh"

# Execute scripts in the correct order
echo "Installing packages..."
bash "$TEMP_DIR/install-packages.sh"

echo "Executing Linux shared script..."
bash "$TEMP_DIR/linux_shared.sh"

echo "Executing distribution-specific setup..."
bash "$TEMP_DIR/distro-setup.sh"

echo "Executing shared setup across platforms..."
bash "$TEMP_DIR/shared.sh"

echo "Setting up package blocking for ASDF..."
bash "$TEMP_DIR/create-package-blockers.sh"
bash "$TEMP_DIR/install-apt-hooks.sh"

echo "Setup completed successfully."
