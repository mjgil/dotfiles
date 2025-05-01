#!/usr/bin/env bash

# Exit on error
set -e

# Import logging utilities
source "$(dirname "${BASH_SOURCE[0]}")/shared/log_utils.sh"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
  PKG_TYPE="brew"
elif [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "$ID" == "ubuntu" || "$ID" == "linuxmint" || "$ID" == "debian" ]]; then
    OS="debian"
    PKG_TYPE="apt"
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

# Function to check if a package is installed
check_package() {
  local category=$1
  local idx=$2
  
  # Skip ASDF languages (handled separately)
  if [[ "$category" == "asdf_languages" ]]; then
    return 0
  fi
  
  # Extract package information
  local name=$(yq e ".${category}[${idx}].name" "$SCRIPT_DIR/shared/packages.yml")
  local description=$(yq e ".${category}[${idx}].description" "$SCRIPT_DIR/shared/packages.yml")
  
  log_echo "Checking $name: $description... " "-n"
  
  if [[ "$OS" == "macos" ]]; then
    # Check for brew package
    if yq e ".${category}[${idx}] | has(\"brew\")" "$SCRIPT_DIR/shared/packages.yml" == "true"; then
      local brew_pkg=$(yq e ".${category}[${idx}].brew" "$SCRIPT_DIR/shared/packages.yml")
      if brew list "$brew_pkg" &>/dev/null; then
        log_echo "[✓ INSTALLED]"
        return 0
      fi
    fi
    
    # Check for brew cask package
    if yq e ".${category}[${idx}] | has(\"brew_cask\")" "$SCRIPT_DIR/shared/packages.yml" == "true"; then
      local brew_cask=$(yq e ".${category}[${idx}].brew_cask" "$SCRIPT_DIR/shared/packages.yml")
      if brew list --cask "$brew_cask" &>/dev/null; then
        log_echo "[✓ INSTALLED]"
        return 0
      fi
    fi
  
  elif [[ "$OS" == "debian" ]]; then
    # Check for apt package
    log_debug "test"
    if yq e ".${category}[${idx}] | has(\"apt\")" "$SCRIPT_DIR/shared/packages.yml" == "true"; then
      local apt_pkg=$(yq e ".${category}[${idx}].apt" "$SCRIPT_DIR/shared/packages.yml")
      if dpkg -l | grep -q "$apt_pkg"; then
        log_echo "[✓ INSTALLED]"
        return 0
      fi
    fi
    log_debug "test2"
    
    # Check for snap package
    if yq e ".${category}[${idx}] | has(\"apt_snap\")" "$SCRIPT_DIR/shared/packages.yml" == "true"; then
      local snap_pkg=$(yq e ".${category}[${idx}].apt_snap" "$SCRIPT_DIR/shared/packages.yml" | cut -d' ' -f1)
      if snap list | grep -q "$snap_pkg"; then
        log_echo "[✓ INSTALLED]"
        return 0
      fi
    fi
    log_debug "test3"

  fi
  
  log_echo "[✗ MISSING]"
  return 1
}

# Function to check ASDF-managed languages
check_asdf_languages() {
  log_info "Checking ASDF-managed languages:"
  
  # Check if ASDF is installed
  if ! command -v asdf >/dev/null 2>&1; then
    if [[ -f ~/.asdf/asdf.sh ]]; then
      . ~/.asdf/asdf.sh
    else
      log_error "ASDF not installed. Please install ASDF first."
      return 1
    fi
  fi
  
  # Get number of languages
  local num_languages=$(yq e ".asdf_languages | length" "$SCRIPT_DIR/shared/packages.yml")
  local installed=0
  local total=$num_languages
  
  for ((i=0; i<num_languages; i++)); do
    local name=$(yq e ".asdf_languages[${i}].name" "$SCRIPT_DIR/shared/packages.yml")
    local description=$(yq e ".asdf_languages[${i}].description" "$SCRIPT_DIR/shared/packages.yml")
    local plugin=$(yq e ".asdf_languages[${i}].plugin" "$SCRIPT_DIR/shared/packages.yml" | cut -d' ' -f1)
    local global=$(yq e ".asdf_languages[${i}].global" "$SCRIPT_DIR/shared/packages.yml")
    
    log_echo "Checking $name: $description... " "-n"
    
    # Check if plugin is installed
    if asdf plugin list | grep -q "$plugin"; then
      # Check if global version is set and installed
      if asdf list "$plugin" 2>/dev/null | grep -q "$global"; then
        log_echo "[✓ INSTALLED]"
        ((installed++))
      else
        log_echo "[✗ INSTALLED BUT WRONG VERSION]"
      fi
    else
      log_echo "[✗ MISSING]"
    fi
  done
  
  log_info "ASDF languages: $installed/$total installed correctly"
  log_echo ""
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
  
  # Handle ASDF languages separately
  if [[ "$category" == "asdf_languages" ]]; then
    check_asdf_languages
    return
  fi
  
  log_info "Checking category: $category"
  
  # Get number of packages in this category
  local num_packages=$(yq e ".$category | length" "$SCRIPT_DIR/shared/packages.yml")
  
  local installed=0
  local total=$num_packages
  
  for ((i=0; i<num_packages; i++)); do
    if check_package "$category" "$i"; then
      ((installed++))
    fi
  done
  
  log_info "Category $category: $installed/$total installed"
  log_echo ""
}

# Main check function
check_all() {
  log_info "Checking packages for $OS..."
  
  # Check ASDF languages first
  check_asdf_languages
  
  # Check for system conflicts with ASDF languages
  check_system_conflict
  
  # Get all categories except ASDF languages
  local categories=$(yq e 'keys | .[]' "$SCRIPT_DIR/shared/packages.yml")
  
  for category in $categories; do
    if [[ "$category" != "asdf_languages" ]]; then
      check_category "$category"
    fi
  done
  
  log_success "Check completed!"
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
  check_all
fi