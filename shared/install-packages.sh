#!/usr/bin/env bash
#
# install-packages.sh - Installs packages from a JSON definition file
# 
# This script reads a packages.json file and installs software
# across different platforms (macOS, Debian-based Linux) using
# appropriate package managers.
#

# Import logging utilities from log_utils.sh if it exists
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_UTILS="${SCRIPT_DIR}/log_utils.sh"

if [[ -f "$LOG_UTILS" ]]; then
  source "$LOG_UTILS"
else
  # Fallback to basic logging functions if log_utils.sh doesn't exist
  function log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
  function log_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
  function log_warning() { echo -e "\033[0;33m[WARNING]\033[0m $1"; }
  function log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
fi

# Exit on error
set -e

# Define constants
PACKAGE_FILE="packages.json"
APT_UPDATE_NEEDED=false
LOCAL_BIN_DIR="$HOME/.local/bin" # Define standard local bin directory

# Determine script directory - adjusted for dotfiles root
if [ -n "$DOTFILES_SOURCE_DIR" ]; then
  SCRIPT_DIR="$DOTFILES_SOURCE_DIR/shared"
fi

# Ensure $LOCAL_BIN_DIR exists
mkdir -p "$LOCAL_BIN_DIR"

# -----------------------------------------------------------------------------
# Platform detection functions
# -----------------------------------------------------------------------------

# Detect OS and verify required tools
function detect_platform() {
  log_info "Detecting platform..."
  
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    # Ensure Homebrew is installed
    if ! command -v brew >/dev/null 2>&1; then
      log_error "Homebrew is required but not installed. Please run bootstrap.sh first."
      exit 1
    fi
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" || "$ID" == "linuxmint" || "$ID" == "debian" ]]; then
      OS="debian"
      # Check for dpkg for apt checks
      if ! command -v dpkg >/dev/null 2>&1; then
        log_error "dpkg command not found. Cannot check package status."
        exit 1
      fi
      # Check for cargo if needed later
      if ! command -v cargo >/dev/null 2>&1; then
          log_info "cargo command not found. cargo_fallback installs might fail if needed."
      fi
    else
      log_error "Unsupported Linux distribution: $ID"
      exit 1
    fi
  else
    log_error "Unsupported OS"
    exit 1
  fi
  
  log_success "Platform detected: $OS"
  
  # Ensure jq is installed
  if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is required but not installed. Please run bootstrap.sh first."
    exit 1
  fi
  
  # Check if package file exists and show the full path
  log_info "Looking for package file at: $SCRIPT_DIR/$PACKAGE_FILE"
  if [ ! -f "$SCRIPT_DIR/$PACKAGE_FILE" ]; then
    log_error "Package definition file not found: $SCRIPT_DIR/$PACKAGE_FILE"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
# Package installation functions
# -----------------------------------------------------------------------------

# Run apt update if needed
function run_apt_update_if_needed() {
  if [[ "$OS" == "debian" && "$APT_UPDATE_NEEDED" == true ]]; then
    log_info "Running apt update..."
    sudo apt update || log_warning "apt update failed, install might fail..."
    APT_UPDATE_NEEDED=false # Reset flag after running
  fi
}

# Check if command exists using command -v
function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install a single package
function install_package() {
  local category=$1
  local idx=$2
  
  # Skip ASDF languages category (handled separately)
  if [[ "$category" == "asdf_languages" ]]; then
    return 0
  fi
  
  # Extract package information using jq
  local name=$(jq -r ".${category}[${idx}].name" "$SCRIPT_DIR/$PACKAGE_FILE")
  local description=$(jq -r ".${category}[${idx}].description // \"No description\"" "$SCRIPT_DIR/$PACKAGE_FILE")
  local id_for_checks=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-') # Sanitize name for filenames

  # Handle null values for name or description gracefully
  if [[ "$name" == "null" ]]; then
    log_warning "Skipping package at index $idx in category $category due to missing name."
    return 0
  fi
  if [[ "$description" == "null" ]]; then
    description="No description provided"
  fi
  
  log_info "Processing $name: $description"
  
  # Platform-specific installation logic
  if [[ "$OS" == "macos" ]]; then
    install_macos_package "$category" "$idx" "$name"
  elif [[ "$OS" == "debian" ]]; then
    install_debian_package "$category" "$idx" "$name" "$id_for_checks"
  fi
  
  log_info "Finished processing $name"
}

# Install package on macOS
function install_macos_package() {
  local category=$1
  local idx=$2
  local name=$3

  local symlink_target=$(jq -r ".${category}[${idx}].symlink_target // null" "$SCRIPT_DIR/$PACKAGE_FILE")
  local cargo_fallback=$(jq -r ".${category}[${idx}].cargo_fallback // null" "$SCRIPT_DIR/$PACKAGE_FILE")
  local final_cmd_name="${symlink_target:-$name}" # Use symlink target if defined, else primary name

  # Check for brew package
  local brew_pkg=$(jq -r ".${category}[${idx}].brew // null" "$SCRIPT_DIR/$PACKAGE_FILE")
  if [[ "$brew_pkg" != "null" ]]; then
    if ! brew list --formula | grep -q "^${brew_pkg}$"; then
      log_info "Installing via brew: $brew_pkg"
      brew install "$brew_pkg" || log_warning "Brew install failed for $brew_pkg, continuing..."
    else
      log_info "Already installed via brew: $brew_pkg"
    fi
  fi
  
  # Check for brew cask package
  local brew_cask=$(jq -r ".${category}[${idx}].brew_cask // null" "$SCRIPT_DIR/$PACKAGE_FILE")
  if [[ "$brew_cask" != "null" ]]; then
    if ! brew list --cask | grep -q "^${brew_cask}$"; then
      log_info "Installing via brew cask: $brew_cask"
      brew install --cask "$brew_cask" || log_warning "Brew cask install failed for $brew_cask, continuing..."
    else
      log_info "Already installed via brew cask: $brew_cask"
    fi
  fi
  
  # Check for brew bundle
  local brew_bundle_check=$(jq -e ".${category}[${idx}].brew_bundle" "$SCRIPT_DIR/$PACKAGE_FILE" > /dev/null 2>&1 && echo true || echo false)
  if [[ "$brew_bundle_check" == "true" ]]; then
    mapfile -t packages < <(jq -r ".${category}[${idx}].brew_bundle[]" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "${#packages[@]}" -gt 0 ]]; then
      log_info "Checking brew bundle: ${packages[*]}"
      local installed_count=0
      local all_bundle_pkgs_installed=true
      for pkg in "${packages[@]}"; do
        if ! brew list --formula | grep -q "^${pkg}$"; then
          log_info "Installing via brew: $pkg"
          brew install "$pkg" || log_warning "Brew install failed for bundle package $pkg, continuing..."
          all_bundle_pkgs_installed=false # Mark as not all installed if any install fails or is needed
        else
          ((installed_count++))
        fi
      done
      if [[ "$all_bundle_pkgs_installed" == true && "$installed_count" -eq "${#packages[@]}" ]]; then
        log_info "All brew bundle packages already installed."
      fi
    fi
  fi
  
  # Check for custom command
  local brew_command=$(jq -r ".${category}[${idx}].brew_command // null" "$SCRIPT_DIR/$PACKAGE_FILE")
  if [[ "$brew_command" != "null" ]]; then
    # Add specific checks here if possible, otherwise assume needs running
    log_info "Running custom brew command: $brew_command"
    eval "$brew_command" || log_warning "Custom brew command failed for $name, continuing..."
  fi

  # --- Post-installation checks for macOS (Cargo & Symlinks) ---
  if ! command_exists "$final_cmd_name"; then
    attempt_cargo_install "$cargo_fallback" "$final_cmd_name"
  fi
  ensure_symlink "$category" "$idx" "$name" "$symlink_target" "$final_cmd_name"
}

# Install package on Debian-based systems
function install_debian_package() {
  local category=$1
  local idx=$2
  local name=$3
  local id_for_checks=$4

  local symlink_target=$(jq -r ".${category}[${idx}].symlink_target // null" "$SCRIPT_DIR/$PACKAGE_FILE")
  local cargo_fallback=$(jq -r ".${category}[${idx}].cargo_fallback // null" "$SCRIPT_DIR/$PACKAGE_FILE")
  local final_cmd_name="${symlink_target:-$name}" # Use symlink target if defined, else primary name

  # Get potential original command name (if symlink_target is set)
  local original_cmd_name=""
  local pkgs_to_check_for_cmd=() # Used for PPA/Repo skip logic
  local apt_pkgs_type=$(jq -r ".${category}[${idx}].apt | type" "$SCRIPT_DIR/$PACKAGE_FILE" 2>/dev/null || echo "null")

  if [[ "$apt_pkgs_type" == "array" ]]; then
      mapfile -t pkgs_to_check_for_cmd < <(jq -r ".${category}[${idx}].apt[]" "$SCRIPT_DIR/$PACKAGE_FILE")
      # If symlink target is set, the first apt entry is usually the "real" command name
      if [[ "$symlink_target" != "null" && "${#pkgs_to_check_for_cmd[@]}" -gt 0 ]]; then
          original_cmd_name="${pkgs_to_check_for_cmd[0]}"
      fi
  elif [[ "$apt_pkgs_type" == "string" ]]; then
      original_cmd_name=$(jq -r ".${category}[${idx}].apt" "$SCRIPT_DIR/$PACKAGE_FILE")
      pkgs_to_check_for_cmd=("$original_cmd_name")
  fi
  # If symlink target exists but original cmd name is not derived from apt field, use name as original
  if [[ "$symlink_target" != "null" && -z "$original_cmd_name" ]]; then
      original_cmd_name="$name"
  fi

  # Check if the final command already exists before trying PPA/Repo/Install
  local command_already_exists=false
  if command_exists "$final_cmd_name"; then
      log_info "Command '$final_cmd_name' already exists. Skipping install attempts."
      command_already_exists=true
  elif [[ -n "$original_cmd_name" ]] && command_exists "$original_cmd_name"; then
      log_info "Original command '$original_cmd_name' exists (target '$final_cmd_name' doesn't yet). Will attempt symlink later."
      # We still might need PPA/Repo/Install if the *package* providing the original command isn't installed
      # Check package status rather than command presence for PPA/Repo skip
      command_already_exists=false # Force install checks if final command doesn't exist
  fi

  # --- Standard Installation Attempts ---
  if [[ "$command_already_exists" == false ]]; then
      # Add PPA if needed
      install_apt_ppa "$category" "$idx" "$name" "$command_already_exists" "${pkgs_to_check_for_cmd[*]}"

      # Add repository if needed
      install_apt_repo "$category" "$idx" "$name" "$id_for_checks"

      # Install apt packages
      install_apt_packages "$category" "$idx"

      # Install snap package
      install_snap_package "$category" "$idx" "$name"

      # Run custom command if specified
      run_apt_custom_command "$category" "$idx" "$name"
  fi

  # --- Post-installation checks (Cargo & Symlinks) ---
  # Check again if the final command exists after install attempts
  if ! command_exists "$final_cmd_name"; then
      attempt_cargo_install "$cargo_fallback" "$final_cmd_name"
  fi
  ensure_symlink "$category" "$idx" "$original_cmd_name" "$symlink_target" "$final_cmd_name"
}

# Add PPA repository
function install_apt_ppa() {
  local category=$1
  local idx=$2
  local name=$3
  local command_already_exists=$4 # This is now less relevant, we check package status
  local pkgs_to_check_for_cmd=$5

  local apt_ppa=$(jq -r ".${category}[${idx}].apt_ppa // null" "$SCRIPT_DIR/$PACKAGE_FILE")
  if [[ "$apt_ppa" != "null" ]]; then
    # Check if any package from the list needs the PPA
    local ppa_needed=false
    local apt_pkgs_type=$(jq -r ".${category}[${idx}].apt | type" "$SCRIPT_DIR/$PACKAGE_FILE" 2>/dev/null || echo "null")
    local pkgs_for_ppa_check=()
    if [[ "$apt_pkgs_type" == "array" ]]; then
        mapfile -t pkgs_for_ppa_check < <(jq -r ".${category}[${idx}].apt[]" "$SCRIPT_DIR/$PACKAGE_FILE")
    elif [[ "$apt_pkgs_type" == "string" ]]; then
        pkgs_for_ppa_check=( $(jq -r ".${category}[${idx}].apt" "$SCRIPT_DIR/$PACKAGE_FILE") )
    fi

    if [[ "${#pkgs_for_ppa_check[@]}" -gt 0 ]]; then
        for pkg in "${pkgs_for_ppa_check[@]}"; do
            if ! dpkg-query -W -f='\${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
                ppa_needed=true
                log_info "Package '$pkg' not installed, PPA '$apt_ppa' might be needed."
                break
            fi
        done
    else
      # If no 'apt' field, but PPA exists, assume PPA is needed if snap/custom isn't already satisfied
      local final_cmd_name="${symlink_target:-$name}"
      if ! command_exists "$final_cmd_name"; then
          ppa_needed=true
          log_info "Command '$final_cmd_name' not found, PPA '$apt_ppa' might be needed."
      fi
    fi

    if [[ "$ppa_needed" == true ]]; then
        log_info "Checking PPA: $apt_ppa"
        local ppa_uri_part=$(echo "$apt_ppa" | cut -d':' -f2)
        local ppa_check_found=false

        # Check existing sources
        shopt -s nullglob
        list_files=(/etc/apt/sources.list.d/*.list)
        if [ ${#list_files[@]} -gt 0 ]; then
          if grep -rsq "ppa.launchpadcontent.net/${ppa_uri_part}/ubuntu" "${list_files[@]}"; then
            ppa_check_found=true
          fi
        fi
        sources_files=(/etc/apt/sources.list.d/*.sources)
        if [ "$ppa_check_found" = "false" ] && [ ${#sources_files[@]} -gt 0 ]; then
          for source_file in "${sources_files[@]}"; do
            if grep -qE "^URIs:[[:space:]]*https://ppa.launchpadcontent.net/${ppa_uri_part}/ubuntu" "$source_file"; then
              ppa_check_found=true
              break
            fi
          done
        fi
        shopt -u nullglob

        if [[ "$ppa_check_found" == false ]]; then
          log_info "Adding PPA: $apt_ppa"
          if sudo add-apt-repository -y "$apt_ppa"; then
            APT_UPDATE_NEEDED=true
          else
            log_warning "Failed to add PPA: $apt_ppa"
          fi
        else
          log_info "PPA source file already exists for $apt_ppa. Skipping add."
        fi
    else
         log_info "All associated apt packages installed or PPA not needed for $name. Skipping PPA check for $apt_ppa."
    fi
  fi
}

# Add third-party apt repository
function install_apt_repo() {
  local category=$1
  local idx=$2
  local name=$3
  local id_for_checks=$4
  # command_already_exists=$5 # Less relevant now
  # pkgs_to_check_for_cmd=$6

  local apt_repo=$(jq -r ".${category}[${idx}].apt_repo // null" "$SCRIPT_DIR/$PACKAGE_FILE")
  if [[ "$apt_repo" != "null" ]]; then
      # Determine the primary package this repo provides (usually the 'apt' field)
      local primary_pkg=""
      local apt_pkgs_type=$(jq -r ".${category}[${idx}].apt | type" "$SCRIPT_DIR/$PACKAGE_FILE" 2>/dev/null || echo "null")
      if [[ "$apt_pkgs_type" == "array" ]]; then
          primary_pkg=$(jq -r ".${category}[${idx}].apt[0]" "$SCRIPT_DIR/$PACKAGE_FILE") # Assume first is primary
      elif [[ "$apt_pkgs_type" == "string" ]]; then
          primary_pkg=$(jq -r ".${category}[${idx}].apt" "$SCRIPT_DIR/$PACKAGE_FILE")
      fi

      local repo_needed=false
      if [[ -n "$primary_pkg" ]]; then
          # Check if the primary package is installed
          if ! dpkg-query -W -f='\${Status}' "$primary_pkg" 2>/dev/null | grep -q "ok installed"; then
              repo_needed=true
              log_info "Primary package '$primary_pkg' not installed, repository '$apt_repo' might be needed."
          else
              log_info "Primary package '$primary_pkg' already installed. Assuming repository '$apt_repo' is correctly configured or not needed."
          fi
      else
          # If no primary package defined, check if the command exists
          local symlink_target=$(jq -r ".${category}[${idx}].symlink_target // null" "$SCRIPT_DIR/$PACKAGE_FILE")
          local final_cmd_name="${symlink_target:-$name}"
          if ! command_exists "$final_cmd_name"; then
              repo_needed=true
              log_info "Command '$final_cmd_name' not found and no primary apt package specified, repository '$apt_repo' might be needed."
          else
               log_info "Command '$final_cmd_name' found. Assuming repository '$apt_repo' is correctly configured or not needed."
          fi
      fi

      # Only proceed if the package is missing
      if [[ "$repo_needed" == true ]]; then
          log_info "Checking repository configuration for $name: $apt_repo"
          local apt_key=$(jq -r ".${category}[${idx}].apt_key // null" "$SCRIPT_DIR/$PACKAGE_FILE")
          local key_file="/usr/share/keyrings/${id_for_checks}-keyring.gpg"
          local repo_file="/etc/apt/sources.list.d/${id_for_checks}.list"
          local repo_added_this_time=false

          # Only try to add the repo file if it doesn't already exist
          if [[ ! -f "$repo_file" ]]; then
              log_info "Repository file '$repo_file' not found. Attempting to add repo and key."
              if [[ "$apt_key" != "null" ]]; then
                  # Add key only if it doesn't exist
                  if [[ ! -f "$key_file" ]]; then
                      log_info "Adding repository key: $apt_key to $key_file"
                      curl -fsSL "$apt_key" | sudo gpg --dearmor -o "$key_file" || log_warning "Failed to add repository key $apt_key, cannot add repo."
                  else 
                      log_info "Key file $key_file already exists."
                  fi
                  # Add repo file if key exists (or was successfully added)
                  if [[ -f "$key_file" ]]; then
                      log_info "Adding repository source file: $repo_file"
                      echo "deb [signed-by=$key_file] $apt_repo" | sudo tee "$repo_file" > /dev/null || log_warning "Error adding repository $apt_repo, continuing..."
                      repo_added_this_time=true
                  else
                      log_warning "Key file $key_file not found or failed to add. Cannot add repository $apt_repo."
                  fi
              else
                  # Add repo without key
                  log_warning "Adding repository source file without specific key: $repo_file"
                  echo "deb $apt_repo" | sudo tee "$repo_file" > /dev/null || log_warning "Error adding repository $apt_repo, continuing..."
                  repo_added_this_time=true
              fi

              # Trigger apt update if repo was newly added
              if [[ "$repo_added_this_time" == true ]]; then
                  APT_UPDATE_NEEDED=true
              fi
          else
              log_info "Repository file '$repo_file' already exists. Skipping repo/key addition."
              # We might still need an update if the package check failed earlier but file existed
              # Let's ensure apt update runs if the package was missing, even if file existed
              APT_UPDATE_NEEDED=true 
          fi
      # else: Package is installed, do nothing.
      fi
  fi
}

# Install apt packages
function install_apt_packages() {
  local category=$1
  local idx=$2
  
  local apt_pkgs_type=$(jq -r ".${category}[${idx}].apt | type" "$SCRIPT_DIR/$PACKAGE_FILE" 2>/dev/null || echo "null")
  local pkgs_to_check=()
  local pkgs_to_install=()
  local all_apt_pkgs_installed=true
  
  if [[ "$apt_pkgs_type" == "array" ]]; then
    mapfile -t pkgs_to_check < <(jq -r ".${category}[${idx}].apt[]" "$SCRIPT_DIR/$PACKAGE_FILE")
  elif [[ "$apt_pkgs_type" == "string" ]]; then
    pkgs_to_check=( $(jq -r ".${category}[${idx}].apt" "$SCRIPT_DIR/$PACKAGE_FILE") )
  fi

  # Check installation status for each defined apt package
  if [[ "${#pkgs_to_check[@]}" -gt 0 ]]; then
    for pkg in "${pkgs_to_check[@]}"; do
      # Use dpkg-query for more reliable status check (Exit code 0 if installed)
      if ! dpkg-query -W -f='\${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
        pkgs_to_install+=("$pkg")
        all_apt_pkgs_installed=false
      fi
    done

    if [[ "${#pkgs_to_install[@]}" -gt 0 ]]; then
      # Run apt update *before* install if needed
      run_apt_update_if_needed
      
      log_info "Installing missing apt packages: ${pkgs_to_install[*]}"
      sudo apt install -y "${pkgs_to_install[@]}" || log_warning "apt install failed for some packages (${pkgs_to_install[*]}), continuing..."
    elif [[ "$all_apt_pkgs_installed" == true ]]; then
      log_info "All required apt packages already installed."
    fi
  fi
}

# Install snap package
function install_snap_package() {
  local category=$1
  local idx=$2
  local name=$3
  
  local snap_pkg_full=$(jq -r ".${category}[${idx}].apt_snap // null" "$SCRIPT_DIR/$PACKAGE_FILE")
  if [[ "$snap_pkg_full" != "null" ]]; then
    local snap_pkg=$(echo "$snap_pkg_full" | cut -d' ' -f1) # Get name part
    local snap_opts=$(echo "$snap_pkg_full" | cut -d' ' -f2-)
    
    # Check using snap list
    if ! snap list "$snap_pkg" >/dev/null 2>&1; then
      log_info "Installing via snap: $snap_pkg_full"
      sudo snap install $snap_pkg $snap_opts || log_warning "Snap install failed for $snap_pkg, continuing..."
    else
      log_info "Already installed via snap: $snap_pkg"
    fi
  fi
}

# Run custom apt command
function run_apt_custom_command() {
  local category=$1
  local idx=$2
  local name=$3
  
  local apt_command=$(jq -r ".${category}[${idx}].apt_command // null" "$SCRIPT_DIR/$PACKAGE_FILE")
  if [[ "$apt_command" != "null" ]]; then
    local needs_run=true
    
    # Get the final command name we expect
    local symlink_target=$(jq -r ".${category}[${idx}].symlink_target // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    local final_cmd_name="${symlink_target:-$name}"

    # Basic check: does the final command already exist?
    if command_exists "$final_cmd_name"; then
        log_info "Command '$final_cmd_name' already exists. Skipping custom command for $name."
        needs_run=false
    else
        # More specific checks if needed (examples kept, but primary check is above)
        local check_name_id=$(echo "$name" | tr '[:upper:]' '[:lower:]')
        case "$check_name_id" in
          "asdf")
            if [[ -d "$HOME/.asdf" ]]; then
              log_info "ASDF directory already exists, skipping clone command."
              needs_run=false
            fi
            ;;
          "rust")
            if command_exists "rustup"; then
              log_info "rustup (Rust) is already installed, skipping custom command."
              needs_run=false 
            fi
            ;;          

          "yt-dlp")
             # Check using the command itself or pip show
             if command_exists "yt-dlp" || (command_exists "pip" && pip show yt-dlp > /dev/null 2>&1); then
               log_info "yt-dlp already installed, skipping pip install command."
               needs_run=false
             fi
             ;;
           "lux")
             # Check standard local bin too, as that's where its command installs
             if [[ -f "$LOCAL_BIN_DIR/lux" ]]; then
                 log_info "lux binary exists at $LOCAL_BIN_DIR/lux. Skipping custom command."
                 needs_run=false
             fi
             ;;
          # Add more specific checks here if needed
        esac
    fi

    if [[ "$needs_run" == true ]]; then
      log_info "Running custom command for $name: $apt_command"
      eval "$apt_command" || log_warning "Custom command failed for $name, continuing..."
    fi
  fi
}

# Attempt cargo install if fallback specified and command doesn't exist
function attempt_cargo_install() {
    local cargo_fallback_crate=$1
    local final_cmd_name=$2

    if [[ "$cargo_fallback_crate" != "null" ]] && ! command_exists "$final_cmd_name"; then
        if command_exists "cargo"; then
            log_info "Command '$final_cmd_name' not found. Attempting install via cargo: $cargo_fallback_crate"
            if cargo install "$cargo_fallback_crate"; then
                log_success "Successfully installed '$cargo_fallback_crate' via cargo."
                # If ASDF manages rust/cargo, reshim might be needed
                if command_exists "asdf"; then
                   if asdf plugin list | grep -q "rust"; then
                       log_info "Reshimming ASDF rust..."
                       asdf reshim rust || log_warning "ASDF reshim rust failed."
                   fi
                fi
            else
                log_warning "Cargo install failed for '$cargo_fallback_crate'."
            fi
        else
            log_warning "Cargo fallback specified for '$final_cmd_name' ('$cargo_fallback_crate'), but cargo command not found. Skipping cargo install."
        fi
    fi
}

# Ensure symlink exists if specified and needed
function ensure_symlink() {
    local category=$1
    local idx=$2
    local original_cmd_name=$3 # The command name that might exist (e.g., fdfind)
    local symlink_target=$4    # The desired final command name (e.g., fd)
    local final_cmd_name=$5    # Same as symlink_target if set, otherwise primary name

    if [[ "$symlink_target" != "null" && "$symlink_target" != "null" ]]; then
        # Only proceed if symlink target is defined and is different from original name (or original name is known)
        if [[ -n "$original_cmd_name" && "$original_cmd_name" != "$symlink_target" ]]; then
            local target_path="$LOCAL_BIN_DIR/$symlink_target"
            
            # Check if the original command exists and the target symlink doesn't
            local original_cmd_path=$(command -v "$original_cmd_name")
            if [[ -n "$original_cmd_path" ]] && ! command_exists "$symlink_target"; then
                 log_info "Creating symlink for '$symlink_target' (from '$original_cmd_name')"
                 ln -sf "$original_cmd_path" "$target_path"
                 log_success "Created symlink: $target_path -> $original_cmd_path"
            elif command_exists "$symlink_target"; then
                 # log_info "Symlink target '$symlink_target' already exists at $(command -v "$symlink_target")." # Optional: verbose
                 : # Do nothing if target command already exists
            elif [[ -z "$original_cmd_path" ]]; then
                 log_warning "Symlink requested for '$symlink_target' from '$original_cmd_name', but original command not found in PATH."
            fi
        # Handle cases where symlink target is same as name - link from non-PATH location if needed
        elif [[ "$original_cmd_name" == "$symlink_target" ]] && ! command_exists "$symlink_target"; then
             # Reserved for future non-PATH checks
            :
             # Add other specific non-PATH checks here if necessary
        fi
    fi
}

# -----------------------------------------------------------------------------
# ASDF language management functions
# -----------------------------------------------------------------------------

# Function to install ASDF if not already installed
function ensure_asdf_installed() {
  log_info "Checking for ASDF installation..."
  
  if ! command -v asdf >/dev/null 2>&1; then
    log_info "ASDF command not found."
    # Check if installed but not sourced
    if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
      log_info "ASDF installed but not sourced. Sourcing now..."
      . "$HOME/.asdf/asdf.sh"
      # Check again
      if ! command -v asdf >/dev/null 2>&1; then
        log_warning "Sourcing ASDF failed. Language installs might fail."
        return 1
      fi
    else
      # Not installed, find ASDF entry in packages.json and install it
      log_info "ASDF not installed. Attempting installation via packages.json..."
      local category="dev_environments" # Assuming ASDF is here
      local num_packages=$(jq ".$category | length" "$SCRIPT_DIR/$PACKAGE_FILE" 2>/dev/null || echo 0)
      local found_asdf=false
      
      for ((i=0; i<num_packages; i++)); do
        local name=$(jq -r ".${category}[${i}].name" "$SCRIPT_DIR/$PACKAGE_FILE")
        if [[ "$name" == "asdf" ]]; then
          # Need to call the main install_package function to handle platform differences
          # This might cause recursion if ASDF isn't installed first - ensure ASDF is early in install order
          install_package "$category" "$i" 
          found_asdf=true
          # Source it after installation attempt
          if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
            log_info "Sourcing ASDF after installation attempt..."
            . "$HOME/.asdf/asdf.sh"
          fi
          break
        fi
      done
      
      if [[ "$found_asdf" == false ]]; then
        log_error "ASDF definition not found in packages.json. Cannot install ASDF automatically."
        return 1
      fi
    fi
  else
    log_info "ASDF command is available."
  fi

  # Final check
  if ! command -v asdf >/dev/null 2>&1; then
    log_warning "ASDF command still not available after installation/sourcing attempts."
    log_warning "Language installations may fail."
    return 1
  fi
  
  return 0
}

# Function to check if an ASDF version is installed for a plugin
# Returns 0 if installed, 1 otherwise
function check_asdf_version_installed() {
  local plugin_name=$1
  local version=$2
  # Use asdf list command and check exit status directly
  asdf list "$plugin_name" "$version" >/dev/null 2>&1
  return $?
}

# Function to install ASDF-managed languages
function install_asdf_languages() {
  log_info "Installing ASDF-managed languages..."

  # First ensure ASDF is installed and sourced
  if ! ensure_asdf_installed; then
    log_warning "Skipping ASDF language installations due to setup issues."
    return 1
  fi

  # Get number of languages
  local num_languages=$(jq ".asdf_languages | length" "$SCRIPT_DIR/$PACKAGE_FILE")

  for ((i=0; i<num_languages; i++)); do
    local name=$(jq -r ".asdf_languages[$i].name" "$SCRIPT_DIR/$PACKAGE_FILE")
    local description=$(jq -r ".asdf_languages[$i].description // \"No description\"" "$SCRIPT_DIR/$PACKAGE_FILE")
    local plugin_cmd=$(jq -r ".asdf_languages[$i].plugin" "$SCRIPT_DIR/$PACKAGE_FILE") # Can include URL
    local global=$(jq -r ".asdf_languages[$i].global // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    local post_install=$(jq -r ".asdf_languages[$i].post_install // null" "$SCRIPT_DIR/$PACKAGE_FILE")

    # Get versions into a bash array
    mapfile -t versions < <(jq -r ".asdf_languages[$i].versions[]? // empty" "$SCRIPT_DIR/$PACKAGE_FILE")

    local plugin_name=$(echo $plugin_cmd | cut -d' ' -f1)

    log_info "Processing ASDF language $name ($plugin_name): $description"

    # Check if the desired global version is already set and installed
    if [[ "$global" != "null" ]]; then

      # Get the currently set global version specifically for this plugin
      local current_global_version
      current_global_version=$(asdf current "$plugin_name" 2>/dev/null | awk '{print $2}')

      echo "$current_global_version"
      echo "$global"

      # Check if the current global matches the desired global AND if that version is installed
      if [[ "$current_global_version" == "$global" ]] && check_asdf_version_installed "$plugin_name" "$global"; then
        log_info "ASDF language $name ($plugin_name) is already globally set to the desired version $global and installed. Skipping."
        continue # Skip to the next language in the loop
      else
        # Log why we are proceeding if the global was set but maybe not installed, or different
        if [[ "$current_global_version" == "$global" ]]; then
          log_info "ASDF language $name ($plugin_name) is globally set to $global, but version is not installed. Proceeding with installation."
        elif [[ -n "$current_global_version" ]]; then
          log_info "Current global version for $plugin_name ('$current_global_version') does not match desired global '$global'. Proceeding with installation/update."
        else
          log_info "No global version currently set for $plugin_name. Proceeding with installation/update."
        fi
      fi
    fi


    # Proceed with installation steps if not skipped
    install_asdf_plugin "$plugin_name" "$plugin_cmd"
    install_asdf_versions "$plugin_name" "${versions[@]}"
    set_asdf_global_version "$plugin_name" "$global" "$name"
    run_asdf_post_install "$plugin_name" "$post_install" "$global" "$name"

    log_info "Finished processing ASDF language $name ($plugin_name)"
  done

  log_info "All ASDF-managed languages processed."
}

# Install ASDF plugin
function install_asdf_plugin() {
  local plugin_name=$1
  local plugin_cmd=$2
  
  # Check if plugin is already installed
  if ! asdf plugin list | grep -q "^${plugin_name}$"; then
    log_info "Adding ASDF plugin: $plugin_cmd"
    # Pass full command (name + optional URL) to add
    asdf plugin add $(echo $plugin_cmd) || log_warning "Error adding plugin $plugin_name, continuing..."
  else
    log_info "ASDF plugin already installed: $plugin_name"
  fi
}

# Install ASDF language versions
function install_asdf_versions() {
  local plugin_name=$1
  shift
  local versions=("$@")
  
  # Install versions if plugin exists
  if asdf plugin list | grep -q "^${plugin_name}$"; then
    if [[ "${#versions[@]}" -gt 0 ]]; then
      for version in "${versions[@]}"; do
        if ! check_asdf_version_installed "$plugin_name" "$version"; then
          log_info "Installing $plugin_name version: $version"
          asdf install $plugin_name $version || log_warning "Error installing $plugin_name version $version, continuing..."
        else
          log_info "Version $version already installed for $plugin_name"
        fi
      done
    else 
      log_info "No versions specified for $plugin_name."
    fi
  else
    log_warning "Plugin $plugin_name not installed. Skipping version installs."
  fi
}

# Set global ASDF version
function set_asdf_global_version() {
  local plugin_name=$1
  local global=$2
  local name=$3
  
  # Set global version if specified and installed
  if [[ "$global" != "null" ]]; then
    # Check if the global version is actually installed first
    if check_asdf_version_installed "$plugin_name" "$global"; then
      local current_global=$(asdf global "$plugin_name" 2>/dev/null || echo "") # Handle error if not set
      if [[ "$current_global" != "$global" ]]; then
        log_info "Setting global version for $name to $global"
        asdf global "$plugin_name" "$global" || log_warning "Error setting global version $global for $name, continuing..."
      else
        log_info "Global version for $name already set to $global"
      fi
    else
      log_warning "Global version $global specified for $name, but it's not installed. Skipping setting global."
    fi
  fi
}

# Run post-install commands for ASDF languages
function run_asdf_post_install() {
  local plugin_name=$1
  local post_install=$2
  local global=$3 # Keep global version info for context if needed
  local name=$4
  
  # Run post-install commands if specified
  if [[ "$post_install" != "null" ]]; then
    # Simplified check: Assume post-install needs running unless explicitly checked and found unnecessary
    local run_post_install=true
    
    case "$plugin_name" in
      nodejs)
        # Check if both typescript and ts-node commands exist *within the asdf context*
        if (export ASDF_NODEJS_LEGACY_FILE_DYNAMIC_STRIP=yes; . "$HOME/.asdf/plugins/nodejs/bin/asdf-exec" "$plugin_name" "$global" command -v typescript >/dev/null 2>&1 && . "$HOME/.asdf/plugins/nodejs/bin/asdf-exec" "$plugin_name" "$global" command -v ts-node >/dev/null 2>&1); then
            log_info "Post-install tools (typescript, ts-node) seem already available in $plugin_name $global context."
            run_post_install=false
        fi
        ;;
      python)
        # Check if pipenv, grip, and tabulate commands exist *within the asdf context*
         if (export ASDF_PYTHON_LEGACY_FILE_DYNAMIC_STRIP=yes; . "$HOME/.asdf/plugins/python/bin/asdf-exec" "$plugin_name" "$global" command -v pipenv >/dev/null 2>&1 && . "$HOME/.asdf/plugins/python/bin/asdf-exec" "$plugin_name" "$global" command -v grip >/dev/null 2>&1 && . "$HOME/.asdf/plugins/python/bin/asdf-exec" "$plugin_name" "$global" command -v tabulate >/dev/null 2>&1) ; then
           log_info "Post-install tools (pipenv, grip, tabulate) seem already available in $plugin_name $global context."
           run_post_install=false
         fi
         ;;
      # Add checks for other plugins if necessary
    esac

    if [[ "$run_post_install" == true ]]; then
      log_info "Running post-install for $name ($plugin_name $global): $post_install"
      
      log_info "Running asdf reshim $plugin_name..."
      if asdf reshim "$plugin_name"; then
        log_success "asdf reshim $plugin_name completed."
      else
        log_warning "asdf reshim $plugin_name failed, post-install might still fail."
      fi

      # Execute post-install command directly, relying on shims being in PATH
      log_info "Attempting post-install command directly: $post_install"
      if eval "$post_install"; then
          log_success "Post-install command successful for $name."
      else
          log_warning "Error in post-install command for $name ($plugin_name $global), continuing..."
      fi
    fi
  fi
}

# -----------------------------------------------------------------------------
# Category installation functions
# -----------------------------------------------------------------------------

# Function to install all packages in a category
function install_category() {
  local category=$1
  
  # Handle ASDF languages separately
  if [[ "$category" == "asdf_languages" ]]; then
    install_asdf_languages
    return
  fi
  
  log_info "Installing category: $category"
  
  # Get number of packages in this category
  local num_packages
  num_packages=$(jq ".$category | length" "$SCRIPT_DIR/$PACKAGE_FILE")
  
  for ((i=0; i<num_packages; i++)); do
    install_package "$category" "$i"
  done
  
  # Run apt update once at the end if any PPA/repo was added during the category run
  run_apt_update_if_needed

  log_info "Completed installing category: $category"
}

# Main installation function
function install_all() {
  log_info "Starting package installation for $OS..."

  # Define the explicit installation order
  # ASDF languages needs dev_environments (asdf itself) installed first.
  # Terminal utils should come early to provide tools like cargo if needed.
  local explicit_order=(
    "development"
    "terminal_utils"
    "dev_tools"
    "dev_environments"
    "asdf_languages"
    "system_tools"
    "cloud_tools"
    "browsers"
    "design_tools"
    "editors"
    "file_utils"
  )

  # Keep track of processed categories to avoid duplicates
  declare -A processed_categories
  for cat in "${explicit_order[@]}"; do
    processed_categories["$cat"]=1
  done

  # --- Install explicitly ordered categories --- 
  log_info "Installing core categories in specific order..."

  for category in "${explicit_order[@]}"; do
    # Check if category actually exists in the file
    if ! jq -e ".$category" "$SCRIPT_DIR/$PACKAGE_FILE" > /dev/null 2>&1; then
      log_warning "Category '$category' specified in explicit order but not found in $PACKAGE_FILE. Skipping."
      continue
    fi

    if [[ "$category" == "asdf_languages" ]]; then
      install_asdf_languages # Handle ASDF languages specifically
    else
      install_category "$category"
    fi
  done
  
  log_info "Finished installing core categories."

  # --- Install remaining categories --- 
  log_info "Installing remaining categories..."
  mapfile -t all_categories < <(jq -r 'keys | .[]' "$SCRIPT_DIR/$PACKAGE_FILE")

  for category in "${all_categories[@]}"; do
    # Check if this category was already processed in the explicit list
    if [[ -z "${processed_categories[$category]}" ]]; then
      log_info "Processing remaining category: $category"
      # Double-check it's not asdf_languages again (shouldn't happen with map logic)
      if [[ "$category" != "asdf_languages" ]]; then 
        install_category "$category"
        processed_categories["$category"]=1 # Mark as processed
      fi
    fi
  done

  log_success "All package categories processed successfully!"
}

# -----------------------------------------------------------------------------
# Script entry point
# -----------------------------------------------------------------------------

# Detect platform first
detect_platform

# Display usage information
function show_usage() {
  echo "Usage: $0 [OPTION] [CATEGORY...]" 
  echo ""
  echo "Options:"
  echo "  --help     Display this help message"
  echo "  --list     List available categories"
  echo ""
  echo "If no category is specified, all packages will be installed."
  echo "Available categories:"
  
  mapfile -t available_categories < <(jq -r 'keys | .[]' "$SCRIPT_DIR/$PACKAGE_FILE")
  for category in "${available_categories[@]}"; do
    echo "  - $category"
  done
}

# List available categories
function list_categories() {
  log_info "Available categories in $PACKAGE_FILE:"
  
  mapfile -t available_categories < <(jq -r 'keys | .[]' "$SCRIPT_DIR/$PACKAGE_FILE")
  for category in "${available_categories[@]}"; do
    local count
    count=$(jq ".$category | length" "$SCRIPT_DIR/$PACKAGE_FILE")
    echo "  - $category ($count packages)"
  done
}

# Check for special arguments or specific category installation
if [[ $# -gt 0 ]]; then
  # Check for --help flag
  if [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
  fi
  
  # Check for --list flag
  if [[ "$1" == "--list" ]]; then
    list_categories
    exit 0
  fi
  
  log_info "Installing specific categories: $@"
  
  # Ensure dev_environments run if asdf_languages is requested
  if [[ " $* " == *" asdf_languages "* && " $* " != *" dev_environments "* ]]; then
      log_info "Installing dev_environments category first as it's needed by asdf_languages"
      install_category "dev_environments"
  fi

  for category in "$@"; do
    # ASDF languages are handled separately to ensure dependencies
    if [[ "$category" == "asdf_languages" ]]; then
        install_asdf_languages
    elif jq -e ".$category" "$SCRIPT_DIR/$PACKAGE_FILE" > /dev/null 2>&1; then
      install_category "$category"
    else
      log_warning "Category '$category' not found in $PACKAGE_FILE"
    fi
  done
else
  # Install all packages using the defined order
  install_all
fi

# Final apt update if any repo/PPA was added and not updated yet
run_apt_update_if_needed

log_success "Package installation script finished."
