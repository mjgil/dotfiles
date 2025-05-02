#!/usr/bin/env bash
# Import logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../shared/log_utils.sh"

rm ~/.bashrc
rm ~/.bashrc_shared
ln -s ~/git/dotfiles/linux/.bashrc ~/.bashrc
ln -s ~/git/dotfiles/shared/.bashrc ~/.bashrc_shared
source ~/.bashrc