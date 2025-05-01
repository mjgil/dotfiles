#!/usr/bin/env bash

# Exit on error
set -e

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Detected macOS"
  if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  if ! command -v yq >/dev/null 2>&1; then
    echo "Installing yq..."
    brew install yq
  fi
elif [[ -f /etc/os-release ]]; then
  . /etc/os-release
  echo "Detected Linux distribution: $ID"
  if [[ "$ID" == "ubuntu" || "$ID" == "linuxmint" || "$ID" == "debian" ]]; then
    if ! command -v yq >/dev/null 2>&1; then
      echo "Installing yq..."
      sudo apt update
      sudo apt install -y wget
      YQ_VERSION="v4.30.8"
      wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -O /tmp/yq
      sudo mv /tmp/yq /usr/local/bin/yq
      sudo chmod +x /usr/local/bin/yq
    fi
  else
    echo "Unsupported Linux distribution: $ID"
    exit 1
  fi
else
  echo "Unsupported OS"
  exit 1
fi

echo "Bootstrap complete, yq is installed."