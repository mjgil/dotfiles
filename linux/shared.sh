#!/usr/bin/env bash
# Import logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../shared/log_utils.sh"

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
if command -v subl >/dev/null 2>&1; then
  log_info "Setting up Sublime Text package control..."
  subl --command "install_package_control" &
  sleep 2
  pkill -f sublime_text || true
fi

# Repository setup is now handled in shared/shared.sh

# App settings are now handled in shared/shared.sh

# Ensure ~/.local/bin exists and is in PATH in .bashrc if not already
# (install-packages.sh now creates the dir, this ensures it's in PATH)
if ! grep -q "export PATH=\"$HOME/.local/bin:\$PATH\"" "$HOME/.bashrc"; then
    log_info "Adding ~/.local/bin to PATH in ~/.bashrc"
    echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
    log_success "Added ~/.local/bin to PATH in ~/.bashrc"
    # Set for current session too
    export PATH="$HOME/.local/bin:$PATH"
fi

# Ensure ~/.cargo/bin is in PATH if it exists
if [ -d "$HOME/.cargo/bin" ] && ! grep -q "export PATH=\"$HOME/.cargo/bin:\$PATH\"" "$HOME/.bashrc"; then
    log_info "Adding ~/.cargo/bin to PATH in ~/.bashrc"
    echo "export PATH=\"$HOME/.cargo/bin:\$PATH\"" >> "$HOME/.bashrc"
    log_success "Added ~/.cargo/bin to PATH in ~/.bashrc"
    # Set for current session too
    export PATH="$HOME/.cargo/bin:$PATH"
fi

log_info "Linux-specific configurations completed."
