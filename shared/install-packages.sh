#!/usr/bin/env bash
# Import logging utilities
# Define logging functions
function log_info() { echo -e "\\033[0;34m[INFO]\\033[0m $1"; }
function log_success() { echo -e "\\033[0;32m[SUCCESS]\\033[0m $1"; }
function log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m $1"; }
function log_error() { echo -e "\\033[0;31m[ERROR]\\033[0m $1"; }

# Exit on error
set -e

# Define package definition file
PACKAGE_FILE="packages.json"

# Script directory - adjusted for dotfiles root
if [ -n "$DOTFILES_SOURCE_DIR" ]; then
  SCRIPT_DIR="$DOTFILES_SOURCE_DIR/shared"
else
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

# Check if package file exists
if [ ! -f "$SCRIPT_DIR/$PACKAGE_FILE" ]; then
    log_error "Package definition file not found: $SCRIPT_DIR/$PACKAGE_FILE"
    exit 1
fi

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
  # Ensure Homebrew is installed
  if ! command -v brew >/dev/null 2>&1; then
    log_info "Homebrew is required but not installed. Please run bootstrap.sh first."
    exit 1
  fi
elif [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "$ID" == "ubuntu" || "$ID" == "linuxmint" || "$ID" == "debian" ]]; then
    OS="debian"
  else
    log_info "Unsupported Linux distribution: $ID"
    exit 1
  fi
else
  log_info "Unsupported OS"
  exit 1
fi

# Ensure jq is installed
if ! command -v jq >/dev/null 2>&1; then
  log_info "jq is required but not installed. Please run bootstrap.sh first."
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
  
  # Extract package information using jq
  local name=$(jq -r ".${category}[${idx}].name" "$SCRIPT_DIR/$PACKAGE_FILE")
  local description=$(jq -r ".${category}[${idx}].description // \"No description\"" "$SCRIPT_DIR/$PACKAGE_FILE")
  
  # Handle null values for name or description gracefully
  if [[ "$name" == "null" ]]; then
    log_warning "Skipping package at index $idx in category $category due to missing name."
    return 0
  fi
  if [[ "$description" == "null" ]]; then
      description="No description provided"
  fi
  
  log_info "Installing $name: $description"
  
  if [[ "$OS" == "macos" ]]; then
    # Check for brew package
    local brew_pkg=$(jq -r ".${category}[${idx}].brew // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$brew_pkg" != "null" ]]; then
      log_info " - Installing via brew: $brew_pkg"
      brew install "$brew_pkg" || log_info " - Already installed or error occurred"
    fi
    
    # Check for brew cask package
    local brew_cask=$(jq -r ".${category}[${idx}].brew_cask // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$brew_cask" != "null" ]]; then
      log_info " - Installing via brew cask: $brew_cask"
      brew install --cask "$brew_cask" || log_info " - Already installed or error occurred"
    fi
    
    # Check for brew bundle
    local brew_bundle_check=$(jq -e ".${category}[${idx}].brew_bundle" "$SCRIPT_DIR/$PACKAGE_FILE" > /dev/null 2>&1 && echo true || echo false)
    if [[ "$brew_bundle_check" == "true" ]]; then
        mapfile -t packages < <(jq -r ".${category}[${idx}].brew_bundle[]" "$SCRIPT_DIR/$PACKAGE_FILE")
        if [[ "${#packages[@]}" -gt 0 ]]; then
            log_info " - Installing brew bundle: ${packages[*]}"
            for pkg in "${packages[@]}"; do
                log_info "   - Installing via brew: $pkg"
                brew install "$pkg" || log_info "     - Already installed or error occurred"
            done
        fi
    fi
    
    # Check for custom command
    local brew_command=$(jq -r ".${category}[${idx}].brew_command // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$brew_command" != "null" ]]; then
      log_info " - Running custom command: $brew_command"
      eval "$brew_command" || log_info " - Command may have failed, continuing..."
    fi
    
  elif [[ "$OS" == "debian" ]]; then
    # Add PPA if needed
    local apt_ppa=$(jq -r ".${category}[${idx}].apt_ppa // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$apt_ppa" != "null" ]]; then
      log_info " - Adding PPA: $apt_ppa"
      sudo add-apt-repository -y "$apt_ppa" || log_info " - PPA may already exist, continuing..."
    fi
    
    # Add repository if needed
    local apt_repo=$(jq -r ".${category}[${idx}].apt_repo // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$apt_repo" != "null" ]]; then
      local apt_key=$(jq -r ".${category}[${idx}].apt_key // null" "$SCRIPT_DIR/$PACKAGE_FILE")
      if [[ "$apt_key" != "null" ]]; then
        log_info " - Adding repository key: $apt_key"
        # Use curl instead of wget, handle potential errors
        curl -fsSL "$apt_key" | sudo gpg --dearmor -o /usr/share/keyrings/${name}-keyring.gpg || log_warning " - Failed to add repository key, continuing..."
        # Ensure the key was added before proceeding
        if [[ -f "/usr/share/keyrings/${name}-keyring.gpg" ]]; then
             local repo_file="/etc/apt/sources.list.d/${name}.list"
             if [[ ! -f "$repo_file" ]]; then
                log_info " - Adding repository: $apt_repo"
                echo "deb [signed-by=/usr/share/keyrings/${name}-keyring.gpg] $apt_repo" | sudo tee "$repo_file" > /dev/null || log_warning " - Error adding repository, continuing..."
             else
                log_info " - Repository already exists: $repo_file"
             fi
        else 
             log_warning " - Repository key file not found, cannot add repository $apt_repo"
        fi
      else 
        # If no key specified, try adding repo directly (less secure)
        local repo_file="/etc/apt/sources.list.d/${name}.list"
        if [[ ! -f "$repo_file" ]]; then
            log_warning " - Adding repository without specific key: $apt_repo"
            echo "$apt_repo" | sudo tee "$repo_file" > /dev/null || log_warning " - Error adding repository, continuing..."
        else
            log_info " - Repository already exists: $repo_file"
        fi
      fi
    fi
    
    # Update apt if we added any repos or PPAs
    if [[ "$apt_repo" != "null" || "$apt_ppa" != "null" ]]; then
      log_info " - Updating apt..."
      sudo apt update || log_warning " - Error updating apt, continuing..."
    fi
    
    # Check for apt package(s)
    local apt_pkgs_type=$(jq -r ".${category}[${idx}].apt | type" "$SCRIPT_DIR/$PACKAGE_FILE")
    local pkgs_to_install=()
    
    if [[ "$apt_pkgs_type" == "array" ]]; then
        mapfile -t pkgs_to_install < <(jq -r ".${category}[${idx}].apt[]" "$SCRIPT_DIR/$PACKAGE_FILE")
    elif [[ "$apt_pkgs_type" == "string" ]]; then
        pkgs_to_install=( $(jq -r ".${category}[${idx}].apt" "$SCRIPT_DIR/$PACKAGE_FILE") )
    fi

    if [[ "${#pkgs_to_install[@]}" -gt 0 ]]; then
        log_info " - Installing via apt: ${pkgs_to_install[*]}"
        sudo apt install -y "${pkgs_to_install[@]}" || log_info " - Package(s) may already be installed or an error occurred, continuing..."
    fi
    
    # Check for snap package
    local snap_pkg=$(jq -r ".${category}[${idx}].apt_snap // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$snap_pkg" != "null" ]]; then
      log_info " - Installing via snap: $snap_pkg"
      sudo snap install $snap_pkg || log_info " - Package may already be installed, continuing..."
    fi
    
    # Check for custom command
    local apt_command=$(jq -r ".${category}[${idx}].apt_command // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$apt_command" != "null" ]]; then
      log_info " - Running custom command: $apt_command"
      # Special handling for asdf installation
      if [[ "$name" == "asdf" && -d "$HOME/.asdf" ]]; then
        log_info " - ASDF directory already exists, skipping clone command"
      else
        eval "$apt_command" || log_info " - Command may have failed, continuing..."
      fi
    fi
  fi
  
  log_info " - Done installing $name"
}

# Function to install ASDF if not already installed
ensure_asdf_installed() {
  log_info "Checking for ASDF installation..."
  
  if ! command -v asdf >/dev/null 2>&1; then
    log_info "ASDF not found, installing..."
    
    if [[ "$OS" == "macos" ]]; then
      brew install asdf || log_warning " - Error installing ASDF via Homebrew, continuing..."
    elif [[ "$OS" == "debian" ]]; then
      if [[ -d "$HOME/.asdf" ]]; then
        log_info "ASDF directory exists but command not found, using existing installation"
      else
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0 || log_warning " - Error cloning ASDF, continuing..."
      fi
    fi
    
    # Source ASDF
    if [[ -f ~/.asdf/asdf.sh ]]; then
      . ~/.asdf/asdf.sh
    fi
  else
    log_info "ASDF is already installed."
  fi
  
  # Ensure ASDF is in the path
  if ! command -v asdf >/dev/null 2>&1; then
    if [[ -f ~/.asdf/asdf.sh ]]; then
      . ~/.asdf/asdf.sh
    else
      log_warning "ASDF installation seems to have failed or can't be sourced."
      log_warning "Continuing without ASDF, some language installations may fail."
    fi
  fi
}

# Function to install ASDF-managed languages
install_asdf_languages() {
  log_info "Installing ASDF-managed languages..."
  
  # First ensure ASDF is installed and sourced
  ensure_asdf_installed
  
  # Check if asdf command is available
  if ! command -v asdf >/dev/null 2>&1; then
    log_warning "ASDF command not available, skipping language installations."
    return 1
  fi
  
  # Get number of languages
  local num_languages=$(jq ".asdf_languages | length" "$SCRIPT_DIR/$PACKAGE_FILE")
  
  for ((i=0; i<num_languages; i++)); do
    local name=$(jq -r ".asdf_languages[$i].name" "$SCRIPT_DIR/$PACKAGE_FILE")
    local description=$(jq -r ".asdf_languages[$i].description // \"No description\"" "$SCRIPT_DIR/$PACKAGE_FILE")
    local plugin=$(jq -r ".asdf_languages[$i].plugin" "$SCRIPT_DIR/$PACKAGE_FILE")
    local global=$(jq -r ".asdf_languages[$i].global // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    local post_install=$(jq -r ".asdf_languages[$i].post_install // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    
    # Get versions into a bash array
    mapfile -t versions < <(jq -r ".asdf_languages[$i].versions[]? // empty" "$SCRIPT_DIR/$PACKAGE_FILE")
    
    log_info "Installing $name: $description"
    
    local plugin_name=$(echo $plugin | cut -d' ' -f1)

    # Check if plugin is already installed
    if ! asdf plugin list 2>/dev/null | grep -q "^${plugin_name}$"; then
      log_info " - Adding ASDF plugin: $plugin"
      asdf plugin add $(echo $plugin) || log_info " - Error adding plugin, continuing..."
    else
      log_info " - ASDF plugin already installed: $plugin_name"
    fi
    
    # Install versions
    if [[ "${#versions[@]}" -gt 0 ]]; then
      for version in "${versions[@]}"; do
        if ! asdf list $plugin_name 2>/dev/null | grep -q "^ *${version} *$"; then
          log_info " - Installing version: $version"
          asdf install $plugin_name $version || log_warning " - Error installing version $version, continuing..."
        else
          log_info " - Version $version already installed"
        fi
      done
    fi
    
    # Set global version
    if [[ "$global" != "null" ]]; then
      log_info " - Setting global version to $global"
      asdf global $plugin_name $global || log_warning " - Error setting global version $global, continuing..."
    fi
    
    # Run post-install commands if specified
    if [[ "$post_install" != "null" ]]; then
      log_info " - Running post-install: $post_install"
      eval "$post_install" || log_warning " - Error in post-install command, continuing..."
    fi
    
    log_info " - Done installing $name"
  done
  
  log_info "All ASDF-managed languages installed successfully."
}

# Function to install all packages in a category
install_category() {
  local category=$1
  
  # Handle ASDF languages separately
  if [[ "$category" == "asdf_languages" ]]; then
    install_asdf_languages
    return
  fi
  
  log_info "Installing category: $category"
  
  # Get number of packages in this category
  local num_packages=$(jq ".$category | length" "$SCRIPT_DIR/$PACKAGE_FILE")
  
  for ((i=0; i<num_packages; i++)); do
    install_package "$category" "$i"
  done
  
  log_info "Completed installing category: $category"
}

# Main installation function
install_all() {
  log_info "Starting package installation for $OS..."
  echo "hi"
  # Install ASDF first (since other packages depend on it)
  if jq -e '.dev_environments' "$SCRIPT_DIR/$PACKAGE_FILE" > /dev/null 2>&1; then
    echo "one"
    local num_dev_packages=$(jq '.dev_environments | length' "$SCRIPT_DIR/$PACKAGE_FILE")
    for ((i=0; i<num_dev_packages; i++)); do
    echo "two"
      local name=$(jq -r ".dev_environments[$i].name" "$SCRIPT_DIR/$PACKAGE_FILE")
      if [[ "$name" == "asdf" ]]; then
        echo "three"
        install_package "dev_environments" "$i"
        echo "four"
        break
      fi
    done
  fi
  
  # Install ASDF languages
  install_asdf_languages
  
  # Get all categories except ASDF languages
  mapfile -t categories < <(jq -r 'keys | .[]' "$SCRIPT_DIR/$PACKAGE_FILE")
  
  for category in "${categories[@]}"; do
    if [[ "$category" != "asdf_languages" ]]; then
      install_category "$category"
    fi
  done
  
  log_info "All packages installed successfully!"
}

# Check for specific category installation
if [[ $# -gt 0 ]]; then
  for category in "$@"; do
    if jq -e ".$category" "$SCRIPT_DIR/$PACKAGE_FILE" > /dev/null 2>&1; then
      install_category "$category"
    else
      log_warning "Category '$category' not found in $PACKAGE_FILE"
    fi
  done
else
  # Install all packages
  install_all
fi