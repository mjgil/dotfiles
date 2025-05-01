#!/usr/bin/env bash

# This script supplements the YAML-based package management system
# with Mac-specific applications and utilities

echo "Installing Mac-specific applications..."

# Install Homebrew if it does not exist (this is now in bootstrap.sh but kept for direct script use)
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew update

# Helper functions for installing applications
brew_cask_install() {
  if ! brew list --cask "$1" &>/dev/null; then
    echo "Installing $1..."
    brew install "$1" --cask
  else
    echo "$1 is already installed."
  fi
}

# Mac-specific brew casks not in packages.yml
# Browsers
brew_cask_install google-chrome-canary
brew_cask_install safari-technology-preview
brew_cask_install firefox-beta

# Productivity & Development
brew_cask_install iterm2
brew_cask_install kaleidoscope
brew_cask_install sourcetree
brew_cask_install paw

# Essential Mac utilities
brew_cask_install 1password
brew_cask_install alfred
brew_cask_install caffeine
brew_cask_install flux
brew_cask_install rectangle
brew_cask_install the-unarchiver
brew_cask_install bartender
brew_cask_install istat-menus
brew_cask_install mounty

# Media & Entertainment
brew_cask_install calibre
brew_cask_install webtorrent
brew_cask_install screenflow

# Communication
brew_cask_install skype
brew_cask_install slack

# Specialized tools
brew install lukechilds/tap/gifgen
brew install mas # Mac App Store CLI

echo "Mac-specific applications installation completed."
echo "Note that some of these changes require a logout/restart to take effect."
