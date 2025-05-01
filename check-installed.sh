#!/usr/bin/env bash

# Exit on error
set -e

# Import logging utilities
source "$(dirname "${BASH_SOURCE[0]}")/shared/log_utils.sh"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
  # PKG_TYPE="brew" # SC2034: Unused variable
elif [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "$ID" == "ubuntu" || "$ID" == "linuxmint" || "$ID" == "debian" ]]; then
    OS="debian"
    # PKG_TYPE="apt" # SC2034: Unused variable
  else
    log_error "Unsupported Linux distribution: $ID"
    exit 1
  fi
else
  log_error "Unsupported OS"
  exit 1
fi

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ensure yq is installed
if ! command -v yq >/dev/null 2>&1; then
  log_error "yq is required but not installed. Please run shared/bootstrap.sh first."
  exit 1
fi

# Function to check a single package
check_package() {
  local category=$1
  local idx=$2
  local name description brew_pkg brew_cask apt_pkg snap_pkg check_cmd cmd_path

  # SC2155 Fix: Declare separately
  name=$(yq e ".${category}[${idx}].name" "$SCRIPT_DIR/shared/packages.yml")
  description=$(yq e ".${category}[${idx}].description" "$SCRIPT_DIR/shared/packages.yml")

  log_info "Checking $name ($description)"

  # macOS checks
  if [[ "$OS" == "macos" ]]; then
    # SC2155 Fix: Declare separately
    brew_pkg=$(yq e ".${category}[${idx}].brew" "$SCRIPT_DIR/shared/packages.yml")
    if [[ "$brew_pkg" != "null" ]]; then
      if brew list --formula | grep -q "^${brew_pkg}$"; then
        log_success " - Found via brew: $brew_pkg"
      else
        log_warning " - Missing via brew: $brew_pkg"
        MISSING_PACKAGES+=("$name (brew: $brew_pkg)")
      fi
    fi

    # SC2155 Fix: Declare separately
    brew_cask=$(yq e ".${category}[${idx}].brew_cask" "$SCRIPT_DIR/shared/packages.yml")
    if [[ "$brew_cask" != "null" ]]; then
      if brew list --cask | grep -q "^${brew_cask}$"; then
        log_success " - Found via brew cask: $brew_cask"
      else
        log_warning " - Missing via brew cask: $brew_cask"
        MISSING_PACKAGES+=("$name (cask: $brew_cask)")
      fi
    fi
  fi

  # Debian checks
  if [[ "$OS" == "debian" ]]; then
    # SC2155 Fix: Declare separately
    apt_pkg=$(yq e ".${category}[${idx}].apt" "$SCRIPT_DIR/shared/packages.yml")
    if [[ "$apt_pkg" != "null" ]]; then
      if dpkg -s "$apt_pkg" >/dev/null 2>&1; then
        log_success " - Found via apt: $apt_pkg"
      else
        log_warning " - Missing via apt: $apt_pkg"
        MISSING_PACKAGES+=("$name (apt: $apt_pkg)")
      fi
    fi

    # SC2155 Fix: Declare separately
    snap_pkg=$(yq e ".${category}[${idx}].apt_snap" "$SCRIPT_DIR/shared/packages.yml" | cut -d' ' -f1)
    if [[ "$snap_pkg" != "null" ]]; then
      if snap list "$snap_pkg" >/dev/null 2>&1; then
        log_success " - Found via snap: $snap_pkg"
      else
        log_warning " - Missing via snap: $snap_pkg"
        MISSING_PACKAGES+=("$name (snap: $snap_pkg)")
      fi
    fi
  fi

  # Command check (fallback)
  check_cmd=$(yq e ".${category}[${idx}].check_cmd" "$SCRIPT_DIR/shared/packages.yml")
  if [[ "$check_cmd" != "null" ]]; then
    cmd_path=$(eval "$check_cmd")
    if [[ -n "$cmd_path" ]]; then
      log_success " - Found via command: $cmd_path"
    else
      log_warning " - Missing via command: $check_cmd"
      MISSING_PACKAGES+=("$name (command: $check_cmd)")
    fi
  fi
}

# Function to check ASDF-managed languages
check_asdf_languages() {
  log_info "Checking ASDF..."
  if command -v asdf &> /dev/null; then
    log_success "ASDF command found"
    # SC1090 Ignored: Sourcing dynamic path
    . ~/.asdf/asdf.sh
  else
    log_warning "ASDF command not found"
    MISSING_PACKAGES+=("asdf")
    return # Cannot check languages if asdf is missing
  fi

  # Get number of languages
  local num_languages
  num_languages=$(yq e ".asdf_languages | length" "$SCRIPT_DIR/shared/packages.yml")

  for ((i=0; i<num_languages; i++)); do
    local name description plugin global version
    # SC2155 Fix: Declare separately
    name=$(yq e ".asdf_languages[${i}].name" "$SCRIPT_DIR/shared/packages.yml")
    description=$(yq e ".asdf_languages[${i}].description" "$SCRIPT_DIR/shared/packages.yml")
    plugin=$(yq e ".asdf_languages[${i}].plugin" "$SCRIPT_DIR/shared/packages.yml" | cut -d' ' -f1)
    global=$(yq e ".asdf_languages[${i}].global" "$SCRIPT_DIR/shared/packages.yml")

    log_info "Checking ASDF language: $name ($description)"

    # Check plugin
    if asdf plugin list | grep -q "$plugin"; then
      log_success " - Plugin found: $plugin"
    else
      log_warning " - Plugin missing: $plugin"
      MISSING_PACKAGES+=("$name (plugin: $plugin)")
      continue
    fi

    # Check global version
    version=$(asdf current "$plugin")
    if [[ "$version" == "$global" ]]; then
      log_success " - Global version found: $global"
    else
      log_warning " - Global version missing or incorrect: $global (current: $version)"
      MISSING_PACKAGES+=("$name (global version: $global)")
    fi
  done
}

# Check if system versions of ASDF-managed languages are installed
check_system_conflict() {
  log_info "Checking for system installations of ASDF-managed languages:"
  
  local conflicts=0
  
  log_echo "Checking system Node.js... " "-n"
  if command -v node >/dev/null 2>&1 && ! which node | grep -q ".asdf"; then
    log_echo "[✗ CONFLICT] - $(which node)"
    ((conflicts++))
  else
    log_echo "[✓ OK]"
  fi
  
  log_echo "Checking system Python... " "-n"
  if command -v python3 >/dev/null 2>&1 && ! which python3 | grep -q ".asdf"; then
    log_echo "[✗ CONFLICT] - $(which python3)"
    ((conflicts++))
  else
    log_echo "[✓ OK]"
  fi
  
  log_echo "Checking system Go... " "-n"
  if command -v go >/dev/null 2>&1 && ! which go | grep -q ".asdf"; then
    log_echo "[✗ CONFLICT] - $(which go)"
    ((conflicts++))
  else
    log_echo "[✓ OK]"
  fi
  
  log_echo "Checking system Java... " "-n"
  if command -v java >/dev/null 2>&1 && ! which java | grep -q ".asdf"; then
    log_echo "[✗ CONFLICT] - $(which java)"
    ((conflicts++))
  else
    log_echo "[✓ OK]"
  fi
  
  if [[ $conflicts -gt 0 ]]; then
    log_warning "WARNING: Found $conflicts conflicts with system-installed languages."
    log_warning "These may interfere with ASDF-managed versions. Consider removing them."
  else
    log_success "No system conflicts found. All languages properly managed by ASDF."
  fi
  log_echo ""
}

# Function to check all packages in a category
check_category() {
  local category=$1
  log_info "Checking category: $category"

  # Get number of packages in this category
  local num_packages
  num_packages=$(yq e ".$category | length" "$SCRIPT_DIR/shared/packages.yml")

  for ((i=0; i<num_packages; i++)); do
    check_package "$category" "$i"
  done
}

# Main check function
check_all_packages() {
  log_info "Checking all packages defined in packages.yml..."

  local categories
  # SC2155 Fix: Declare separately
  categories=$(yq e 'keys | .[]' "$SCRIPT_DIR/shared/packages.yml")

  for category in $categories; do
    # Skip ASDF languages category (handled separately)
    if [[ "$category" != "asdf_languages" ]]; then
      check_category "$category"
    fi
  done

  # Check ASDF languages
  check_asdf_languages

  # Check for system conflicts with ASDF languages
  check_system_conflict

  # Report missing packages
  if [[ ${#MISSING_PACKAGES[@]} -gt 0 ]]; then
    log_warning "Missing packages:"
    for pkg in "${MISSING_PACKAGES[@]}"; do
      log_warning " - $pkg"
    done
  else
    log_success "All packages found!"
  fi
}

# Check for specific category
if [[ $# -gt 0 ]]; then
  for category in "$@"; do
    if yq e "has(\"$category\")" "$SCRIPT_DIR/shared/packages.yml" == "true"; then
      check_category "$category"
    else
      log_error "Category '$category' not found in packages.yml"
    fi
  done
else
  # Check all packages
  check_all_packages
fi