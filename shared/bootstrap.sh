#!/usr/bin/env bash
# Import logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/log_utils.sh"

# Exit on error
set -e

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  log_info "Detected macOS"
  if ! command -v brew >/dev/null 2>&1; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Ensure jq is installed (since we rely on it now)
  if ! command -v jq >/dev/null 2>&1; then
    log_info "Installing jq..."
    brew install jq
  fi
elif [[ -f /etc/os-release ]]; then
  . /etc/os-release
  log_info "Detected Linux distribution: $ID"
  if [[ "$ID" == "ubuntu" || "$ID" == "linuxmint" || "$ID" == "debian" ]]; then
    # Ensure jq is installed (since we rely on it now)

    sudo apt update
    if ! command -v jq >/dev/null 2>&1; then
      log_info "Installing jq..."
      sudo apt install -y jq
    fi
  else
    log_info "Unsupported Linux distribution: $ID"
    exit 1
  fi
else
  log_info "Unsupported OS"
  exit 1
fi

log_info "Bootstrap complete. Essential tools (brew/apt, jq) checked/installed."