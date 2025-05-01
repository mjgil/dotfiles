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
    # Check for dpkg for apt checks
    if ! command -v dpkg >/dev/null 2>&1; then
      log_error "dpkg command not found. Cannot check package status."
      exit 1
    fi
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

# Global flag to track if apt update is needed
APT_UPDATE_NEEDED=false

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
  
  if [[ "$OS" == "macos" ]]; then
    # Check for brew package
    local brew_pkg=$(jq -r ".${category}[${idx}].brew // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$brew_pkg" != "null" ]]; then
      if ! brew list --formula | grep -q "^${brew_pkg}$"; then
        log_info " - Installing via brew: $brew_pkg"
        brew install "$brew_pkg" || log_warning " - Brew install failed for $brew_pkg, continuing..."
      else
        log_info " - Already installed via brew: $brew_pkg"
      fi
    fi
    
    # Check for brew cask package
    local brew_cask=$(jq -r ".${category}[${idx}].brew_cask // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$brew_cask" != "null" ]]; then
       if ! brew list --cask | grep -q "^${brew_cask}$"; then
         log_info " - Installing via brew cask: $brew_cask"
         brew install --cask "$brew_cask" || log_warning " - Brew cask install failed for $brew_cask, continuing..."
       else
         log_info " - Already installed via brew cask: $brew_cask"
       fi
    fi
    
    # Check for brew bundle
    local brew_bundle_check=$(jq -e ".${category}[${idx}].brew_bundle" "$SCRIPT_DIR/$PACKAGE_FILE" > /dev/null 2>&1 && echo true || echo false)
    if [[ "$brew_bundle_check" == "true" ]]; then
        mapfile -t packages < <(jq -r ".${category}[${idx}].brew_bundle[]" "$SCRIPT_DIR/$PACKAGE_FILE")
        if [[ "${#packages[@]}" -gt 0 ]]; then
            log_info " - Checking brew bundle: ${packages[*]}"
            local installed_count=0
            local all_bundle_pkgs_installed=true
            for pkg in "${packages[@]}"; do
              if ! brew list --formula | grep -q "^${pkg}$"; then
                log_info "   - Installing via brew: $pkg"
                brew install "$pkg" || log_warning "     - Brew install failed for bundle package $pkg, continuing..."
                all_bundle_pkgs_installed=false # Mark as not all installed if any install fails or is needed
              else
                ((installed_count++))
              fi
            done
            if [[ "$all_bundle_pkgs_installed" == true && "$installed_count" -eq "${#packages[@]}" ]]; then
                log_info "   - All brew bundle packages already installed."
            fi
        fi
    fi
    
    # Check for custom command
    local brew_command=$(jq -r ".${category}[${idx}].brew_command // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$brew_command" != "null" ]]; then
      # Add specific checks here if possible, otherwise assume needs running
      log_info " - Running custom brew command: $brew_command"
      eval "$brew_command" || log_warning " - Custom brew command failed for $name, continuing..."
    fi
    
  elif [[ "$OS" == "debian" ]]; then
    local ppa_added=false
    local repo_added=false
    local command_already_exists=false # Flag to check if any listed apt command exists

    # --- Check if any command corresponding to apt package names exists ---
    local apt_pkgs_type_for_check=$(jq -r ".${category}[${idx}].apt | type" "$SCRIPT_DIR/$PACKAGE_FILE" 2>/dev/null || echo "null")
    local pkgs_to_check_for_cmd=()
    if [[ "$apt_pkgs_type_for_check" == "array" ]]; then
        mapfile -t pkgs_to_check_for_cmd < <(jq -r ".${category}[${idx}].apt[]" "$SCRIPT_DIR/$PACKAGE_FILE")
    elif [[ "$apt_pkgs_type_for_check" == "string" ]]; then
        pkgs_to_check_for_cmd=( $(jq -r ".${category}[${idx}].apt" "$SCRIPT_DIR/$PACKAGE_FILE") )
    fi

    if [[ "${#pkgs_to_check_for_cmd[@]}" -gt 0 ]]; then
        local cmd_to_check=""
        for cmd_to_check in "${pkgs_to_check_for_cmd[@]}"; do
            # Check if a command with the exact apt package name exists
            if command -v "$cmd_to_check" >/dev/null 2>&1; then
                log_info " - Command '$cmd_to_check' (from apt field) found for $name. Skipping PPA/Repo checks."
                command_already_exists=true
                break # Found one, no need to check others for this package
            fi
        done
    fi
    # --- End command check ---

    # Add PPA if needed AND command doesn't already exist
    local apt_ppa=$(jq -r ".${category}[${idx}].apt_ppa // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$apt_ppa" != "null" && "$command_already_exists" == "false" ]]; then
        # Determine primary command again just for logging, if needed
        local primary_command_for_log="${pkgs_to_check_for_cmd[-1]:-unknown}"
        log_info " - Adding PPA: $apt_ppa (since no command from [${pkgs_to_check_for_cmd[*]}] found)"
        # Use the previous robust check just in case, but log clearly
        local ppa_uri_part=$(echo "$apt_ppa" | cut -d':' -f2)
        local ppa_check_found=false
        shopt -s nullglob
        list_files=(/etc/apt/sources.list.d/*.list)
        if [ ${#list_files[@]} -gt 0 ]; then
            if grep -rsq "ppa.launchpadcontent.net/${ppa_uri_part}/ubuntu" "${list_files[@]}"; then ppa_check_found=true; fi
        fi
        sources_files=(/etc/apt/sources.list.d/*.sources)
        if [ "$ppa_check_found" = "false" ] && [ ${#sources_files[@]} -gt 0 ]; then
             for source_file in "${sources_files[@]}"; do
                if grep -qE "^URIs:[[:space:]]*https://ppa.launchpadcontent.net/${ppa_uri_part}/ubuntu" "$source_file"; then ppa_check_found=true; break; fi
             done
        fi
        shopt -u nullglob

        if [[ "$ppa_check_found" == false ]]; then
            if sudo add-apt-repository -y "$apt_ppa"; then
                ppa_added=true
                APT_UPDATE_NEEDED=true
            else
                log_warning " - Failed to add PPA: $apt_ppa"
            fi
        else
             log_info " - PPA source file already exists for $apt_ppa. Skipping add."
        fi
    elif [[ "$apt_ppa" != "null" && "$command_already_exists" == "true" ]]; then
         # Find which command was found for logging clarity
         local found_cmd=""
         for cmd_to_check in "${pkgs_to_check_for_cmd[@]}"; do
             if command -v "$cmd_to_check" >/dev/null 2>&1; then found_cmd="$cmd_to_check"; break; fi
         done
         log_info " - Skipping PPA add for $apt_ppa because command '$found_cmd' exists."
    fi

    # Add repository if needed AND command doesn't already exist
    local apt_repo=$(jq -r ".${category}[${idx}].apt_repo // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$apt_repo" != "null" && "$command_already_exists" == "false" ]]; then
      local primary_command_for_log="${pkgs_to_check_for_cmd[-1]:-unknown}"
      local apt_key=$(jq -r ".${category}[${idx}].apt_key // null" "$SCRIPT_DIR/$PACKAGE_FILE")
      local key_file="/usr/share/keyrings/${id_for_checks}-keyring.gpg"
      local repo_file="/etc/apt/sources.list.d/${id_for_checks}.list"
      local repo_added_this_time=false

      log_info " - Checking repository for $name (since no command from [${pkgs_to_check_for_cmd[*]}] found)"

      # Check repo file first
      if [[ ! -f "$repo_file" ]]; then
          if [[ "$apt_key" != "null" ]]; then
             # Check key file
             if [[ ! -f "$key_file" ]]; then
                 log_info " - Adding repository key: $apt_key"
                 curl -fsSL "$apt_key" | sudo gpg --dearmor -o "$key_file" || log_warning " - Failed to add repository key $apt_key, cannot add repo."
             fi

             # Add repo only if key exists
             if [[ -f "$key_file" ]]; then
                 log_info " - Adding repository: $apt_repo"
                 echo "deb [signed-by=$key_file] $apt_repo" | sudo tee "$repo_file" > /dev/null || log_warning " - Error adding repository $apt_repo, continuing..."
                 repo_added_this_time=true
             else
                 log_warning " - Key file $key_file not found or failed to add. Cannot add repository $apt_repo."
             fi
          else
             log_warning " - Adding repository without specific key: $apt_repo"
             echo "$apt_repo" | sudo tee "$repo_file" > /dev/null || log_warning " - Error adding repository $apt_repo, continuing..."
             repo_added_this_time=true
          fi
      else
          log_info " - Repository file already exists: $repo_file"
      fi

      if [[ "$repo_added_this_time" == true ]]; then
          repo_added=true
      fi
    elif [[ "$apt_repo" != "null" && "$command_already_exists" == "true" ]]; then
         local found_cmd=""
         for cmd_to_check in "${pkgs_to_check_for_cmd[@]}"; do
             if command -v "$cmd_to_check" >/dev/null 2>&1; then found_cmd="$cmd_to_check"; break; fi
         done
         log_info " - Skipping Repo add for $apt_repo because command '$found_cmd' exists."
    fi
    
    # Set flag if PPA or repo was actually added in this run
    if [[ "$ppa_added" == true || "$repo_added" == true ]]; then
      APT_UPDATE_NEEDED=true
    fi
    
    # Check for apt package(s)
    local apt_pkgs_type=$(jq -r ".${category}[${idx}].apt | type" "$SCRIPT_DIR/$PACKAGE_FILE" 2>/dev/null || echo "null")
    local pkgs_to_install=()
    local all_apt_pkgs_installed=true # Assume true initially
    
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
            if [[ "$APT_UPDATE_NEEDED" == true ]]; then
              log_info " - Running apt update..."
              sudo apt update || log_warning " - apt update failed, install might fail..."
              APT_UPDATE_NEEDED=false # Reset flag after running
            fi
            log_info " - Installing missing apt packages for $name: ${pkgs_to_install[*]}"
            sudo apt install -y "${pkgs_to_install[@]}" || log_warning " - apt install failed for some packages in [$name], continuing..."
        elif [[ "$all_apt_pkgs_installed" == true ]]; then
             log_info " - All required apt packages for $name already installed."
        fi
    fi # End check if pkgs_to_check array has elements
    
    # Check for snap package
    local snap_pkg_full=$(jq -r ".${category}[${idx}].apt_snap // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$snap_pkg_full" != "null" ]]; then
      local snap_pkg=$(echo "$snap_pkg_full" | cut -d' ' -f1) # Get name part
      local snap_opts=$(echo "$snap_pkg_full" | cut -d' ' -f2-)
      # Check using snap list
      if ! snap list "$snap_pkg" >/dev/null 2>&1; then
         log_info " - Installing via snap: $snap_pkg_full"
         sudo snap install $snap_pkg $snap_opts || log_warning " - Snap install failed for $snap_pkg, continuing..."
      else
         log_info " - Already installed via snap: $snap_pkg"
      fi
    fi
    
    # Check for custom command
    local apt_command=$(jq -r ".${category}[${idx}].apt_command // null" "$SCRIPT_DIR/$PACKAGE_FILE")
    if [[ "$apt_command" != "null" ]]; then
      local needs_run=true
      # Add specific checks based on command/name
      local check_name_id=$(echo "$name" | tr '[:upper:]' '[:lower:]')
      case "$check_name_id" in
        "asdf")
          if [[ -d "$HOME/.asdf" ]]; then
            log_info " - ASDF directory already exists, skipping clone command."
            needs_run=false
          fi
          ;;
        "rust")
          if command -v rustup >/dev/null 2>&1; then
             log_info " - rustup (Rust) is already installed, skipping custom command."
             needs_run=false # Skip the curl command if rustup exists
          else
             log_info " - Running rustup install command."
          fi
          ;;          
        "yt-dlp")
          # Check using the command itself or pip show
          if command -v yt-dlp > /dev/null 2>&1 || (command -v pip >/dev/null 2>&1 && pip show yt-dlp > /dev/null 2>&1); then
              log_info " - yt-dlp already installed, skipping pip install command."
              needs_run=false
          fi
          ;;
         # Add more specific checks here
      esac

      if [[ "$needs_run" == true ]]; then
        log_info " - Running custom command for $name: $apt_command"
        eval "$apt_command" || log_warning " - Custom command failed for $name, continuing..."
      fi
    fi
  fi
  
  log_info " - Finished processing $name"
}

# Function to install ASDF if not already installed
ensure_asdf_installed() {
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
            install_package "$category" "$i" # This will run the clone/brew install
            found_asdf=true
            # Source it after installation
            if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
                log_info "Sourcing ASDF after installation..."
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
check_asdf_version_installed() {
    local plugin_name=$1
    local version=$2
    # Use asdf list command and check exit status directly
    # This seems more reliable than parsing output with grep
    asdf list "$plugin_name" "$version" >/dev/null 2>&1
    # Exit status 0 means the version is installed
    return $?
}

# Function to install ASDF-managed languages
install_asdf_languages() {
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
    
    log_info "Processing ASDF language $name: $description"
    
    local plugin_name=$(echo $plugin_cmd | cut -d' ' -f1)

    # Check if plugin is already installed
    if ! asdf plugin list | grep -q "^${plugin_name}$"; then
      log_info " - Adding ASDF plugin: $plugin_cmd"
      # Pass full command (name + optional URL) to add
      asdf plugin add $(echo $plugin_cmd) || log_warning " - Error adding plugin $plugin_name, continuing..."
    else
      log_info " - ASDF plugin already installed: $plugin_name"
    fi
    
    # Install versions if plugin exists
    if asdf plugin list | grep -q "^${plugin_name}$"; then
        if [[ "${#versions[@]}" -gt 0 ]]; then
          local all_versions_installed=true
          for version in "${versions[@]}"; do
            if ! check_asdf_version_installed "$plugin_name" "$version"; then
              log_info " - Installing $name version: $version"
              asdf install $plugin_name $version || log_warning " - Error installing $name version $version, continuing..."
              all_versions_installed=false # Mark as false if any install attempted
            else
              log_info " - Version $version already installed for $name"
            fi
          done
        else 
            log_info " - No versions specified for $name."
        fi
        
        # Set global version if specified and installed
        if [[ "$global" != "null" ]]; then
           # Check if the global version is actually installed first using the improved function
           if check_asdf_version_installed "$plugin_name" "$global"; then
              local current_global=$(asdf global list $plugin_name 2>/dev/null | awk '{print $2}')
              if [[ "$current_global" != "$global" ]]; then
                  log_info " - Setting global version for $name to $global"
                  asdf global $plugin_name $global || log_warning " - Error setting global version $global for $name, continuing..."
              else
                  log_info " - Global version for $name already set to $global"
              fi
           else
               log_warning " - Global version $global specified for $name, but it's not installed. Skipping setting global."
           fi
        fi
        
        # Run post-install commands if specified
        if [[ "$post_install" != "null" ]]; then
          # Maybe only run if all_versions_installed was false initially?
          # For now, run if defined, assuming idempotency.
          # Add checks for common post-install tools
          local run_post_install=true
          case "$plugin_name" in
              nodejs)
                  # Check if both typescript and ts-node commands exist
                  if command -v typescript >/dev/null 2>&1 && command -v ts-node >/dev/null 2>&1; then
                      log_info "   - Post-install tools (typescript, ts-node) already installed."
                      run_post_install=false
                  fi
                  ;;
              python)
                  # Check if pipenv, grip, and tabulate commands exist
                  if command -v pipenv >/dev/null 2>&1 && command -v grip >/dev/null 2>&1 && command -v tabulate >/dev/null 2>&1; then
                      log_info "   - Post-install tools (pipenv, grip, tabulate) already installed."
                      run_post_install=false
                  fi
                  ;;
              # Add checks for other plugins if necessary
          esac

          if [[ "$run_post_install" == true ]]; then
              log_info " - Running post-install for $name: $post_install"
              # Ensure asdf environment is active for post-install commands
              ( # Run in a subshell to isolate potential env changes
                  # Find the correct binary path instead of using asdf shell
                  local bin_path=""
                  local cmd_to_run=""
                  if [[ "$plugin_name" == "nodejs" ]]; then
                      # Assumes post_install starts with npm or npx
                      local npm_path=$(asdf which npm "$global" 2>/dev/null)
                      if [[ -n "$npm_path" ]]; then
                          bin_path=$(dirname "$npm_path")
                          # Prepend the specific bin path to PATH for this command
                          export PATH="$bin_path:$PATH"
                          cmd_to_run="$post_install"
                      else
                          log_warning "   - Could not find npm path for version $global. Cannot run post-install accurately."
                      fi
                  elif [[ "$plugin_name" == "python" ]]; then
                       # Assumes post_install starts with pip or uses global python packages
                       local python_path=$(asdf which python "$global" 2>/dev/null)
                       if [[ -n "$python_path" ]]; then
                          bin_path=$(dirname "$python_path")
                          # Prepend the specific bin path to PATH for this command
                          export PATH="$bin_path:$PATH"
                          cmd_to_run="$post_install"
                       else
                          log_warning "   - Could not find python path for version $global. Cannot run post-install accurately."
                       fi
                  else
                      # Default for other languages: try simple eval
                      log_info "   - Using default eval for post-install for $plugin_name"
                      cmd_to_run="$post_install"
                  fi

                  # Execute the command if we determined how to run it
                  if [[ -n "$cmd_to_run" ]]; then
                     log_info "   - Executing: $cmd_to_run (in $plugin_name $global context)"
                     eval "$cmd_to_run" || log_warning " - Error in post-install command for $name, continuing..."
                  fi
              ) # End subshell
          fi
        fi
    else
        log_warning " - Plugin $plugin_name not installed. Skipping version installs and global setting for $name."
    fi
    
    log_info " - Finished processing ASDF language $name"
  done
  
  log_info "All ASDF-managed languages processed."
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
  
  # Run apt update once at the end if any PPA/repo was added during the category run
  if [[ "$OS" == "debian" && "$APT_UPDATE_NEEDED" == true ]]; then
      log_info "Running final apt update for category $category..."
      sudo apt update || log_warning " - Final apt update failed for category $category."
      APT_UPDATE_NEEDED=false # Reset flag
  fi

  log_info "Completed installing category: $category"
}

# Main installation function
install_all() {
  log_info "Starting package installation for $OS..."

  # Define the explicit installation order
  # ASDF languages needs dev_environments (asdf itself) installed first.
  local explicit_order=(
    "development"
    "terminal_utils"
    "dev_tools"
    "system_tools"
    # "cloud_tools"
    "dev_environments"
    "asdf_languages"
    # "browsers"
    # "design_tools"
    # "editors"
    # "file_utils"
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

# === Script Execution ===

# Check for specific category installation
if [[ $# -gt 0 ]]; then
  log_info "Installing specific categories: $@"
  if [[ " $* " == *" asdf_languages "* ]]; then install_asdf_languages; fi

  for category in "$@"; do
    if [[ "$category" != "asdf_languages" ]]; then
        if jq -e ".$category" "$SCRIPT_DIR/$PACKAGE_FILE" > /dev/null 2>&1; then
          install_category "$category"
        else
          log_warning "Category '$category' not found in $PACKAGE_FILE"
        fi
    fi
  done
else
  # Install all packages
  install_all
fi

# Final apt update if any repo/PPA was added and not updated yet
if [[ "$OS" == "debian" && "$APT_UPDATE_NEEDED" == true ]]; then
    log_info "Running final apt update..."
    sudo apt update || log_warning " - Final apt update failed."
    APT_UPDATE_NEEDED=false
fi

log_success "Package installation script finished."