#!/usr/bin/env bash

# Import logging utilities
function log_info() { echo -e "\\033[0;34m[INFO]\\033[0m $1"; }
function log_success() { echo -e "\\033[0;32m[SUCCESS]\\033[0m $1"; }
function log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m $1"; }
function log_error() { echo -e "\\033[0;31m[ERROR]\\033[0m $1"; }

log_info "Starting fix for missing terminal utilities..."

# Ensure ~/.local/bin directory exists
mkdir -p "$HOME/.local/bin"

# Install bat/batcat using cargo (fallback method)
log_info "Installing bat using cargo..."
if ! command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    if command -v cargo &> /dev/null; then
        cargo install bat
        if [ -e "$HOME/.cargo/bin/bat" ]; then
            ln -sf "$HOME/.cargo/bin/bat" "$HOME/.local/bin/bat"
            log_success "Created symlink: ~/.local/bin/bat -> $HOME/.cargo/bin/bat"
        fi
    else
        log_warning "Cargo not available for bat installation"
    fi
elif command -v batcat &> /dev/null; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    log_success "Created symlink: ~/.local/bin/bat -> $(command -v batcat)"
fi

# Install exa/eza using cargo (fallback method)
log_info "Installing eza (replacement for exa) using cargo..."
if ! command -v exa &> /dev/null && ! command -v eza &> /dev/null; then
    if command -v cargo &> /dev/null; then
        cargo install eza
        if [ -e "$HOME/.cargo/bin/eza" ]; then
            ln -sf "$HOME/.cargo/bin/eza" "$HOME/.local/bin/exa"
            log_success "Created symlink: ~/.local/bin/exa -> $HOME/.cargo/bin/eza"
        fi
    else
        log_warning "Cargo not available for eza installation"
    fi
elif command -v eza &> /dev/null; then
    ln -sf "$(command -v eza)" "$HOME/.local/bin/exa"
    log_success "Created symlink: ~/.local/bin/exa -> $(command -v eza)"
fi

# Ensure ~/.local/bin is in PATH
if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$HOME/.bashrc"; then
    log_info "Adding ~/.local/bin to PATH in ~/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    # Set for current session too
    export PATH="$HOME/.local/bin:$PATH"
    log_success "Added ~/.local/bin to PATH"
fi

# Check if ~/.cargo/bin is in PATH
if ! grep -q "export PATH=\"\$HOME/.cargo/bin:\$PATH\"" "$HOME/.bashrc"; then
    log_info "Adding ~/.cargo/bin to PATH in ~/.bashrc"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$HOME/.bashrc"
    # Set for current session too
    export PATH="$HOME/.cargo/bin:$PATH"
    log_success "Added ~/.cargo/bin to PATH"
fi

log_success "Fixed missing utilities!"
log_info "Note: g++-10 is missing but isn't required for terminal utilities."
log_info "Run 'source ~/.bashrc' to update your current session PATH, then run check_installed_orig.sh again."
