#!/usr/bin/env bash

# Exit on error
set -e

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
  # Ensure Homebrew is installed
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required but not installed. Please run bootstrap.sh first."
    exit 1
  fi
elif [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "$ID" == "ubuntu" || "$ID" == "linuxmint" || "$ID" == "debian" ]]; then
    OS="debian"
  else
    echo "Unsupported Linux distribution: $ID"
    exit 1
  fi
else
  echo "Unsupported OS"
  exit 1
fi

# Ensure yq is installed
if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required but not installed. Please run bootstrap.sh first."
  exit 1
fi

# Function to install a single package
install_package() {
  local category=$1
  local idx=$2
  
  # Skip ASDF languages category (handled separately)
  if [[ "$category" == "asdf_languages" ]]; then
    return 0
  fi
  
  # Extract package information
  local name=$(yq e ".$category[$idx].name" "$SCRIPT_DIR/packages.yml")
  local description=$(yq e ".$category[$idx].description" "$SCRIPT_DIR/packages.yml")
  
  echo "Installing $name: $description"
  
  if [[ "$OS" == "macos" ]]; then
    # Check for brew package
    if yq e ".$category[$idx] | has(\"brew\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      local brew_pkg=$(yq e ".$category[$idx].brew" "$SCRIPT_DIR/packages.yml")
      echo " - Installing via brew: $brew_pkg"
      brew install "$brew_pkg" || echo " - Already installed or error occurred"
    fi
    
    # Check for brew cask package
    if yq e ".$category[$idx] | has(\"brew_cask\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      local brew_cask=$(yq e ".$category[$idx].brew_cask" "$SCRIPT_DIR/packages.yml")
      echo " - Installing via brew cask: $brew_cask"
      brew install --cask "$brew_cask" || echo " - Already installed or error occurred"
    fi
    
    # Check for brew bundle
    if yq e ".$category[$idx] | has(\"brew_bundle\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      local packages=$(yq e ".$category[$idx].brew_bundle[]" "$SCRIPT_DIR/packages.yml")
      for pkg in $packages; do
        echo " - Installing via brew: $pkg"
        brew install "$pkg" || echo " - Already installed or error occurred"
      done
    fi
    
    # Check for custom command
    if yq e ".$category[$idx] | has(\"brew_command\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      local command=$(yq e ".$category[$idx].brew_command" "$SCRIPT_DIR/packages.yml")
      echo " - Running custom command: $command"
      eval "$command"
    fi
    
  elif [[ "$OS" == "debian" ]]; then
    # Add PPA if needed
    if yq e ".$category[$idx] | has(\"apt_ppa\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      local apt_ppa=$(yq e ".$category[$idx].apt_ppa" "$SCRIPT_DIR/packages.yml")
      echo " - Adding PPA: $apt_ppa"
      sudo add-apt-repository -y "$apt_ppa"
    fi
    
    # Add repository if needed
    if yq e ".$category[$idx] | has(\"apt_repo\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      local apt_repo=$(yq e ".$category[$idx].apt_repo" "$SCRIPT_DIR/packages.yml")
      
      if yq e ".$category[$idx] | has(\"apt_key\")" "$SCRIPT_DIR/packages.yml" == "true"; then
        local apt_key=$(yq e ".$category[$idx].apt_key" "$SCRIPT_DIR/packages.yml")
        echo " - Adding repository key: $apt_key"
        wget -q -O - "$apt_key" | sudo apt-key add -
      fi
      
      echo " - Adding repository: $apt_repo"
      echo "$apt_repo" | sudo tee /etc/apt/sources.list.d/"$name".list > /dev/null
    fi
    
    # Update apt if we added any repos or PPAs
    if yq e ".$category[$idx] | has(\"apt_repo\")" "$SCRIPT_DIR/packages.yml" == "true" || \
       yq e ".$category[$idx] | has(\"apt_ppa\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      echo " - Updating apt..."
      sudo apt update
    fi
    
    # Check for apt package
    if yq e ".$category[$idx] | has(\"apt\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      local apt_pkg=$(yq e ".$category[$idx].apt" "$SCRIPT_DIR/packages.yml")
      echo " - Installing via apt: $apt_pkg"
      sudo apt install -y "$apt_pkg"
    fi
    
    # Check for snap package
    if yq e ".$category[$idx] | has(\"apt_snap\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      local snap_pkg=$(yq e ".$category[$idx].apt_snap" "$SCRIPT_DIR/packages.yml")
      echo " - Installing via snap: $snap_pkg"
      sudo snap install $snap_pkg
    fi
    
    # Check for custom command
    if yq e ".$category[$idx] | has(\"apt_command\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      local command=$(yq e ".$category[$idx].apt_command" "$SCRIPT_DIR/packages.yml")
      echo " - Running custom command: $command"
      eval "$command"
    fi
  fi
  
  echo " - Done installing $name"
}

# Function to install ASDF if not already installed
ensure_asdf_installed() {
  echo "Checking for ASDF installation..."
  
  if ! command -v asdf >/dev/null 2>&1; then
    echo "ASDF not found, installing..."
    
    if [[ "$OS" == "macos" ]]; then
      brew install asdf
    elif [[ "$OS" == "debian" ]]; then
      git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
    fi
    
    # Source ASDF
    if [[ -f ~/.asdf/asdf.sh ]]; then
      . ~/.asdf/asdf.sh
    fi
  else
    echo "ASDF is already installed."
  fi
  
  # Ensure ASDF is in the path
  if ! command -v asdf >/dev/null 2>&1; then
    if [[ -f ~/.asdf/asdf.sh ]]; then
      . ~/.asdf/asdf.sh
    else
      echo "ERROR: ASDF installation seems to have failed or can't be sourced."
      exit 1
    fi
  fi
}

# Function to install ASDF-managed languages
install_asdf_languages() {
  echo "Installing ASDF-managed languages..."
  
  # First ensure ASDF is installed and sourced
  ensure_asdf_installed
  
  # Get number of languages
  local num_languages=$(yq e ".asdf_languages | length" "$SCRIPT_DIR/packages.yml")
  
  for ((i=0; i<num_languages; i++)); do
    local name=$(yq e ".asdf_languages[$i].name" "$SCRIPT_DIR/packages.yml")
    local description=$(yq e ".asdf_languages[$i].description" "$SCRIPT_DIR/packages.yml")
    local plugin=$(yq e ".asdf_languages[$i].plugin" "$SCRIPT_DIR/packages.yml")
    local versions=$(yq e ".asdf_languages[$i].versions[]" "$SCRIPT_DIR/packages.yml")
    local global=$(yq e ".asdf_languages[$i].global" "$SCRIPT_DIR/packages.yml")
    
    echo "Installing $name: $description"
    
    # Check if plugin is already installed
    if ! asdf plugin list | grep -q "$(echo $plugin | cut -d' ' -f1)"; then
      echo " - Adding ASDF plugin: $plugin"
      asdf plugin add $(echo $plugin)
    else
      echo " - ASDF plugin already installed: $(echo $plugin | cut -d' ' -f1)"
    fi
    
    # Install versions
    for version in $versions; do
      if ! asdf list $(echo $plugin | cut -d' ' -f1) | grep -q "$version"; then
        echo " - Installing version: $version"
        asdf install $(echo $plugin | cut -d' ' -f1) $version
      else
        echo " - Version $version already installed"
      fi
    done
    
    # Set global version
    echo " - Setting global version to $global"
    asdf global $(echo $plugin | cut -d' ' -f1) $global
    
    # Run post-install commands if specified
    if yq e ".asdf_languages[$i] | has(\"post_install\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      local post_install=$(yq e ".asdf_languages[$i].post_install" "$SCRIPT_DIR/packages.yml")
      echo " - Running post-install: $post_install"
      eval "$post_install"
    fi
    
    echo " - Done installing $name"
  done
  
  echo "All ASDF-managed languages installed successfully."
}

# Function to install all packages in a category
install_category() {
  local category=$1
  
  # Handle ASDF languages separately
  if [[ "$category" == "asdf_languages" ]]; then
    install_asdf_languages
    return
  fi
  
  echo "Installing category: $category"
  
  # Get number of packages in this category
  local num_packages=$(yq e ".$category | length" "$SCRIPT_DIR/packages.yml")
  
  for ((i=0; i<num_packages; i++)); do
    install_package "$category" "$i"
  done
  
  echo "Completed installing category: $category"
}

# Main installation function
install_all() {
  echo "Starting package installation for $OS..."
  
  # Install ASDF first (since other packages depend on it)
  if yq e 'has("dev_environments")' "$SCRIPT_DIR/packages.yml" == "true"; then
    for ((i=0; i<$(yq e ".dev_environments | length" "$SCRIPT_DIR/packages.yml"); i++)); do
      if [[ "$(yq e ".dev_environments[$i].name" "$SCRIPT_DIR/packages.yml")" == "asdf" ]]; then
        install_package "dev_environments" "$i"
        break
      fi
    done
  fi
  
  # Install ASDF languages
  install_asdf_languages
  
  # Get all categories except ASDF languages
  local categories=$(yq e 'keys | .[]' "$SCRIPT_DIR/packages.yml")
  
  for category in $categories; do
    if [[ "$category" != "asdf_languages" ]]; then
      install_category "$category"
    fi
  done
  
  echo "All packages installed successfully!"
}

# Check for specific category installation
if [[ $# -gt 0 ]]; then
  for category in "$@"; do
    if yq e "has(\"$category\")" "$SCRIPT_DIR/packages.yml" == "true"; then
      install_category "$category"
    else
      echo "Category '$category' not found in packages.yml"
    fi
  done
else
  # Install all packages
  install_all
fi