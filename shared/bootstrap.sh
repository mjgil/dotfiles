#!/usr/bin/env bash
# Import logging utilities
# Define logging functions
function log_info() { echo -e "\\033[0;34m[INFO]\\033[0m $1"; }
function log_success() { echo -e "\\033[0;32m[SUCCESS]\\033[0m $1"; }
function log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m $1"; }
function log_error() { echo -e "\\033[0;31m[ERROR]\\033[0m $1"; }

# Exit on error
set -e

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  log_info "Detected macOS"
  if ! command -v brew >/dev/null 2>&1; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  if ! command -v yq >/dev/null 2>&1; then
    log_info "Installing yq..."
    brew install yq
  fi
elif [[ -f /etc/os-release ]]; then
  . /etc/os-release
  log_info "Detected Linux distribution: $ID"
  if [[ "$ID" == "ubuntu" || "$ID" == "linuxmint" || "$ID" == "debian" ]]; then
    if ! command -v yq >/dev/null 2>&1; then
      log_info "Installing yq..."
      sudo apt update
      sudo apt install -y wget
      YQ_VERSION="v4.30.8"
      wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -O /tmp/yq
      sudo mv /tmp/yq /usr/local/bin/yq
      sudo chmod +x /usr/local/bin/yq
    fi
  else
    log_info "Unsupported Linux distribution: $ID"
    exit 1
  fi
else
  log_info "Unsupported OS"
  exit 1
fi

log_info "Bootstrap complete, yq is installed."