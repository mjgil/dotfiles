#!/usr/bin/env bash
# Import logging utilities
# Define logging functions
function log_info() { echo -e "\\033[0;34m[INFO]\\033[0m $1"; }
function log_success() { echo -e "\\033[0;32m[SUCCESS]\\033[0m $1"; }
function log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m $1"; }
function log_error() { echo -e "\\033[0;31m[ERROR]\\033[0m $1"; }

# Common setup for all Linux distributions
log_info "Setting up Linux-specific configurations..."

# Linux Mint specific adjustment (can run on any distro safely)
if [ -f "/etc/apt/preferences.d/nosnap.pref" ]; then
   sudo rm /etc/apt/preferences.d/nosnap.pref
fi

# Docker group setup
if ! getent group docker > /dev/null 2>&1; then
  sudo groupadd docker
fi
sudo usermod -aG docker "$USER"

# Export paths for python
export LDFLAGS="-L/usr/local/opt/sqlite/lib"
export CPPFLAGS="-I/usr/local/opt/sqlite/include"
export PKG_CONFIG_PATH="/usr/local/opt/sqlite/lib/pkgconfig"

# Sublime Text post-installation setup
# if command -v subl >/dev/null 2>&1; then
#   log_info "Setting up Sublime Text package control..."
#   subl --command "install_package_control" &
#   sleep 2
#   pkill -f sublime_text || true
# fi

# Repository setup is now handled in shared/shared.sh

# App settings are now handled in shared/shared.sh

log_info "Linux-specific configurations completed."
