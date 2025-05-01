#!/usr/bin/env bash

# Exit on error
set -e

echo "Starting Mac installation..."

# Ensure Command Line Tools are installed
if ! xcode-select -p &>/dev/null; then
    echo "Xcode Command Line Tools are not installed. Proceeding with installation..."
    # Create the marker file to enable installation via softwareupdate
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    # Install the Command Line Tools
    echo "Finding Xcode Software Name..."
    UPDATE_LABEL=$(softwareupdate --list | \
                    awk -F: '/^ *\* Label: / {print $2}' | \
                    grep -i "Command Line Tools for Xcode" | \
                    head -n 1 | \
                    xargs)
    echo "Name Found: $UPDATE_LABEL"
    echo "Installing Xcode Command Line Tools..."
    softwareupdate --install "$UPDATE_LABEL" --verbose

    # Remove the marker file
    rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    # Verify installation
    if ! xcode-select -p &>/dev/null; then
        echo "Failed to install Xcode Command Line Tools."
        exit 1
    fi
fi

# Install Rosetta for Apple Silicon Macs
if [[ $(uname -p) == 'arm' ]]; then
    echo "Installing Rosetta for Apple Silicon..."
    softwareupdate --install-rosetta --agree-to-license
fi

# Install Homebrew if it doesn't exist
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH if needed
    if [[ $(uname -p) == 'arm' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Setup Git before cloning repositories
git config --global user.name "Malcom Gilbert"
git config --global user.email malcomgilbert@gmail.com
git config --global core.editor "subl -n -w"
git config --global push.default matching
git config --global core.excludesfile ~/.gitignore
echo *.DS_Store >> ~/.gitignore

if [ ! -f ~/.git-prompt.sh ]; then
  curl -o ~/.git-prompt.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi

# Create git directory and clone repositories
mkdir -p ~/git
cd ~/git

# Clone dotfiles repository if not already present
if [ ! -d ~/git/dotfiles ]; then
    echo "Cloning dotfiles repository..."
    git clone https://github.com/mjgil/dotfiles.git
    cd dotfiles
    git remote set-url origin git@github.com:mjgil/dotfiles.git
    cd ..
else
    echo "Dotfiles repository already exists."
fi

# Install yq for YAML parsing
echo "Installing yq..."
brew install yq

# Run bootstrap script
cd ~/git/dotfiles
./shared/bootstrap.sh

# Run the package installer
echo "Installing packages from YAML definition..."
./shared/install-packages.sh

# Install Mac-specific applications
echo "Installing Mac-specific applications..."
./mac/install-programs-and-apps.sh

# Configure Mac OS defaults
echo "Configuring Mac OS defaults..."
./mac/install-defaults.sh

# Update bash configuration
echo "Updating bash configuration..."
./mac/update-bashrc.sh

echo "Mac installation completed successfully!"
