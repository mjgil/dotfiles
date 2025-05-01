#!/usr/bin/env bash

# Common setup for all Linux distributions
echo "Setting up Linux-specific configurations..."

# Linux Mint specific adjustment (can run on any distro safely)
if [ -f "/etc/apt/preferences.d/nosnap.pref" ]; then
   sudo rm /etc/apt/preferences.d/nosnap.pref
fi

# Docker group setup
if ! getent group docker > /dev/null 2>&1; then
  sudo groupadd docker
fi
sudo usermod -aG docker $USER

# Export paths for python
export LDFLAGS="-L/usr/local/opt/sqlite/lib"
export CPPFLAGS="-I/usr/local/opt/sqlite/include"
export PKG_CONFIG_PATH="/usr/local/opt/sqlite/lib/pkgconfig"

# Sublime Text post-installation setup
if command -v subl >/dev/null 2>&1; then
  echo "Setting up Sublime Text package control..."
  subl --command "install_package_control" &
  sleep 2
  pkill -f sublime_text || true
fi

# Repository setup is now handled in shared/shared.sh

# App settings are now handled in shared/shared.sh

echo "Linux-specific configurations completed."
