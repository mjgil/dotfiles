#!/bin/bash
# Import logging utilities
source "$(dirname "${BASH_SOURCE[0]}")/shared/log_utils.sh"

# A simple script to run shellcheck on all .sh files in specific directories
ROOT_DIR="/home/m/git/dotfiles"

log_info "Checking scripts in root directory"
for script in "$ROOT_DIR"/*.sh; do
    if [ -f "$script" ]; then
        log_info "Checking $script"
        shellcheck "$script" || log_info "Issues found in $script"
    fi
done

log_info "Checking scripts in linux directory"
for script in "$ROOT_DIR/linux"/*.sh; do
    if [ -f "$script" ]; then
        log_info "Checking $script"
        shellcheck "$script" || log_info "Issues found in $script"
    fi
done

log_info "Checking scripts in shared directory"
for script in "$ROOT_DIR/shared"/*.sh; do
    if [ -f "$script" ]; then
        log_info "Checking $script"
        shellcheck "$script" || log_info "Issues found in $script"
    fi
done

log_info "Checking complete"
