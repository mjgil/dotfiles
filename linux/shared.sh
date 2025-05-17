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

# Sublime Text
mkdir -p ~/.config/sublime-text/Packages/User

# Copy config files with the correct names
cp ~/git/dotfiles/app-settings/sublime/linux-key-bindings.json ~/.config/sublime-text/Packages/User/"Default (Linux).sublime-keymap"
cp ~/git/dotfiles/app-settings/sublime/settings.json ~/.config/sublime-text/Packages/User/Preferences.sublime-settings

# Install Oceanic Next Color Scheme if not already installed
OCEANIC_PACKAGE_DIR="$HOME/.config/sublime-text/Installed Packages"
OCEANIC_PACKAGE="Oceanic Next Color Scheme.sublime-package"
if [ ! -f "${OCEANIC_PACKAGE_DIR}/${OCEANIC_PACKAGE}" ]; then
  mkdir -p "${OCEANIC_PACKAGE_DIR}"
  curl -o "${OCEANIC_PACKAGE_DIR}/${OCEANIC_PACKAGE}" \
    https://github.com/voronianski/oceanic-next-color-scheme/raw/master/Oceanic%20Next%20Color%20Scheme.sublime-package
  log_success "Installed Oceanic Next Color Scheme for Sublime Text"
fi


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

# Virtualization group setup
if command -v virt-manager >/dev/null 2>&1; then
  log_info "Adding user to virtualization groups..."
  sudo usermod -aG libvirt "$USER"
  sudo usermod -aG kvm "$USER"
  
  # Start and enable libvirtd service if not running
  if ! sudo systemctl is-active --quiet libvirtd; then
    log_info "Starting and enabling libvirtd service..."
    sudo systemctl start libvirtd
    sudo systemctl enable libvirtd
  fi
  log_success "Added user to virtualization groups"
fi

log_info "Linux-specific configurations completed."
