#!/usr/bin/env bash

# Exit on error
set -e

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
    echo "Unsupported Linux distribution: $ID"
    exit 1
  fi
else
  echo "Unsupported OS"
  exit 1
fi

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ensure yq is installed
if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required but not installed. Please run shared/bootstrap.sh first."
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
  local name=$(yq e ".$category[$idx].name" "$SCRIPT_DIR/shared/packages.yml")
  local description=$(yq e ".$category[$idx].description" "$SCRIPT_DIR/shared/packages.yml")
  
  echo -n "Checking $name: $description... "
  
  if [[ "$OS" == "macos" ]]; then
    # Check for brew package
    if yq e ".$category[$idx] | has(\"brew\")" "$SCRIPT_DIR/shared/packages.yml" == "true"; then
      local brew_pkg=$(yq e ".$category[$idx].brew" "$SCRIPT_DIR/shared/packages.yml")
      if brew list "$brew_pkg" &>/dev/null; then
        echo "[✓ INSTALLED]"
        return 0
      fi
    fi
    
    # Check for brew cask package
    if yq e ".$category[$idx] | has(\"brew_cask\")" "$SCRIPT_DIR/shared/packages.yml" == "true"; then
      local brew_cask=$(yq e ".$category[$idx].brew_cask" "$SCRIPT_DIR/shared/packages.yml")
      if brew list --cask "$brew_cask" &>/dev/null; then
        echo "[✓ INSTALLED]"
        return 0
      fi
    fi
  
  elif [[ "$OS" == "debian" ]]; then
    # Check for apt package
    if yq e ".$category[$idx] | has(\"apt\")" "$SCRIPT_DIR/shared/packages.yml" == "true"; then
      local apt_pkg=$(yq e ".$category[$idx].apt" "$SCRIPT_DIR/shared/packages.yml")
      if dpkg -l | grep -q "$apt_pkg"; then
        echo "[✓ INSTALLED]"
        return 0
      fi
    fi
    
    # Check for snap package
    if yq e ".$category[$idx] | has(\"apt_snap\")" "$SCRIPT_DIR/shared/packages.yml" == "true"; then
      local snap_pkg=$(yq e ".$category[$idx].apt_snap" "$SCRIPT_DIR/shared/packages.yml" | cut -d' ' -f1)
      if snap list | grep -q "$snap_pkg"; then
        echo "[✓ INSTALLED]"
        return 0
      fi
    fi
  fi
  
  echo "[✗ MISSING]"
  return 1
}

# Function to check ASDF-managed languages
check_asdf_languages() {
  echo "Checking ASDF-managed languages:"
  
  # Check if ASDF is installed
  if ! command -v asdf >/dev/null 2>&1; then
    if [[ -f ~/.asdf/asdf.sh ]]; then
      . ~/.asdf/asdf.sh
    else
      echo "ASDF not installed. Please install ASDF first."
      return 1
    fi
  fi
  
  # Get number of languages
  local num_languages=$(yq e ".asdf_languages | length" "$SCRIPT_DIR/shared/packages.yml")
  local installed=0
  local total=$num_languages
  
  for ((i=0; i<num_languages; i++)); do
    local name=$(yq e ".asdf_languages[$i].name" "$SCRIPT_DIR/shared/packages.yml")
    local description=$(yq e ".asdf_languages[$i].description" "$SCRIPT_DIR/shared/packages.yml")
    local plugin=$(yq e ".asdf_languages[$i].plugin" "$SCRIPT_DIR/shared/packages.yml" | cut -d' ' -f1)
    local global=$(yq e ".asdf_languages[$i].global" "$SCRIPT_DIR/shared/packages.yml")
    
    echo -n "Checking $name: $description... "
    
    # Check if plugin is installed
    if asdf plugin list | grep -q "$plugin"; then
      # Check if global version is set and installed
      if asdf list "$plugin" 2>/dev/null | grep -q "$global"; then
        echo "[✓ INSTALLED]"
        ((installed++))
      else
        echo "[✗ INSTALLED BUT WRONG VERSION]"
      fi
    else
      echo "[✗ MISSING]"
    fi
  done
  
  echo "ASDF languages: $installed/$total installed correctly"
  echo ""
}

# Check if system versions of ASDF-managed languages are installed
check_system_conflict() {
  echo "Checking for system installations of ASDF-managed languages:"
  
  local conflicts=0
  
  echo -n "Checking system Node.js... "
  if command -v node >/dev/null 2>&1 && ! which node | grep -q ".asdf"; then
    echo "[✗ CONFLICT] - $(which node)"
    ((conflicts++))
  else
    echo "[✓ OK]"
  fi
  
  echo -n "Checking system Python... "
  if command -v python3 >/dev/null 2>&1 && ! which python3 | grep -q ".asdf"; then
    echo "[✗ CONFLICT] - $(which python3)"
    ((conflicts++))
  else
    echo "[✓ OK]"
  fi
  
  echo -n "Checking system Go... "
  if command -v go >/dev/null 2>&1 && ! which go | grep -q ".asdf"; then
    echo "[✗ CONFLICT] - $(which go)"
    ((conflicts++))
  else
    echo "[✓ OK]"
  fi
  
  echo -n "Checking system Java... "
  if command -v java >/dev/null 2>&1 && ! which java | grep -q ".asdf"; then
    echo "[✗ CONFLICT] - $(which java)"
    ((conflicts++))
  else
    echo "[✓ OK]"
  fi
  
  if [[ $conflicts -gt 0 ]]; then
    echo "WARNING: Found $conflicts conflicts with system-installed languages."
    echo "These may interfere with ASDF-managed versions. Consider removing them."
  else
    echo "No system conflicts found. All languages properly managed by ASDF."
  fi
  echo ""
}

# Function to check all packages in a category
check_category() {
  local category=$1
  
  # Handle ASDF languages separately
  if [[ "$category" == "asdf_languages" ]]; then
    check_asdf_languages
    return
  fi
  
  echo "Checking category: $category"
  
  # Get number of packages in this category
  local num_packages=$(yq e ".$category | length" "$SCRIPT_DIR/shared/packages.yml")
  
  local installed=0
  local total=$num_packages
  
  for ((i=0; i<num_packages; i++)); do
    if check_package "$category" "$i"; then
      ((installed++))
    fi
  done
  
  echo "Category $category: $installed/$total installed"
  echo ""
}

# Main check function
check_all() {
  echo "Checking packages for $OS..."
  
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
  
  echo "Check completed!"
}

# Check for specific category
if [[ $# -gt 0 ]]; then
  for category in "$@"; do
    if yq e "has(\"$category\")" "$SCRIPT_DIR/shared/packages.yml" == "true"; then
      check_category "$category"
    else
      echo "Category '$category' not found in packages.yml"
    fi
  done
else
  # Check all packages
  check_all
fi