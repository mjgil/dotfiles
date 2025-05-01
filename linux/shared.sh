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
if command -v subl >/dev/null 2>&1; then
  log_info "Setting up Sublime Text package control..."
  subl --command "install_package_control" &
  sleep 2
  pkill -f sublime_text || true
fi

# Repository setup is now handled in shared/shared.sh

# App settings are now handled in shared/shared.sh

# Create necessary symlinks for command line tools with different naming conventions
log_info "Creating symlinks for terminal utilities to ensure compatibility..."

# Ensure ~/.local/bin exists and is in PATH
mkdir -p "$HOME/.local/bin"

# Function to create symlinks for common utilities with alternate names in Debian/Ubuntu
create_terminal_symlinks() {
    # fd-find -> fd
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        log_info "Creating symlink for fd (from fdfind)"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        log_success "Created symlink: ~/.local/bin/fd -> $(command -v fdfind)"
    elif command -v fd &> /dev/null; then
        log_info "fd is already available at $(command -v fd)"
    fi

    # Install bat if not available (via cargo)
    if ! command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        if command -v cargo &> /dev/null; then
            log_info "Installing bat using cargo..."
            cargo install bat
            if [ -e "$HOME/.cargo/bin/bat" ]; then
                log_success "Successfully installed bat using cargo"
                ln -sf "$HOME/.cargo/bin/bat" "$HOME/.local/bin/bat"
                log_success "Created symlink: ~/.local/bin/bat -> $HOME/.cargo/bin/bat"
            else
                log_warning "Failed to install bat using cargo"
            fi
        else
            log_warning "Neither bat nor batcat available, and cargo not found for installation"
        fi
    # batcat -> bat
    elif command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        log_info "Creating symlink for bat (from batcat)"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        log_success "Created symlink: ~/.local/bin/bat -> $(command -v batcat)"
    elif command -v bat &> /dev/null; then
        log_info "bat is already available at $(command -v bat)"
    fi

    # Install exa/eza if not available (via cargo)
    if ! command -v exa &> /dev/null && ! command -v eza &> /dev/null; then
        if command -v cargo &> /dev/null; then
            log_info "Installing eza using cargo..."
            cargo install eza
            if [ -e "$HOME/.cargo/bin/eza" ]; then
                log_success "Successfully installed eza using cargo"
                ln -sf "$HOME/.cargo/bin/eza" "$HOME/.local/bin/exa"
                log_success "Created symlink: ~/.local/bin/exa -> $HOME/.cargo/bin/eza"
            else
                log_warning "Failed to install eza using cargo"
            fi
        else
            log_warning "Neither exa nor eza available, and cargo not found for installation"
        fi
    # exa/eza -> exa 
    elif command -v eza &> /dev/null && ! command -v exa &> /dev/null; then
        log_info "Creating symlink for exa (from eza)"
        ln -sf "$(command -v eza)" "$HOME/.local/bin/exa"
        log_success "Created symlink: ~/.local/bin/exa -> $(command -v eza)"
    elif command -v exa &> /dev/null; then
        log_info "exa is already available at $(command -v exa)"
    fi

    # atuin symlink if installed but not in PATH
    if [ -f "$HOME/.atuin/bin/atuin" ] && ! command -v atuin &> /dev/null; then
        log_info "Creating symlink for atuin"
        ln -sf "$HOME/.atuin/bin/atuin" "$HOME/.local/bin/atuin"
        log_success "Created symlink: ~/.local/bin/atuin -> $HOME/.atuin/bin/atuin"
    elif command -v atuin &> /dev/null; then
        log_info "atuin is already available at $(command -v atuin)"
    fi
}

# Create the terminal utility symlinks
create_terminal_symlinks

# Ensure ~/.local/bin is in PATH in .bashrc if not already
if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$HOME/.bashrc"; then
    log_info "Adding ~/.local/bin to PATH in ~/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    log_success "Added ~/.local/bin to PATH in ~/.bashrc"
    # Set for current session too
    export PATH="$HOME/.local/bin:$PATH"
fi

# Ensure ~/.cargo/bin is in PATH if it exists
if [ -d "$HOME/.cargo/bin" ] && ! grep -q "export PATH=\"\$HOME/.cargo/bin:\$PATH\"" "$HOME/.bashrc"; then
    log_info "Adding ~/.cargo/bin to PATH in ~/.bashrc"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
    log_success "Added ~/.cargo/bin to PATH in ~/.bashrc"
    # Set for current session too
    export PATH="$HOME/.cargo/bin:$PATH"
fi

log_info "Linux-specific configurations completed."
