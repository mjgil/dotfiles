#!/usr/bin/env bash
# Import logging utilities
# Define logging functions
function log_info() { echo -e "\\033[0;34m[INFO]\\033[0m $1"; }
function log_success() { echo -e "\\033[0;32m[SUCCESS]\\033[0m $1"; }
function log_warning() { echo -e "\\033[0;33m[WARNING]\\033[0m $1"; }
function log_error() { echo -e "\\033[0;31m[ERROR]\\033[0m $1"; }

rm ~/.bashrc
rm ~/.bashrc_shared
ln -s ~/git/dotfiles/linux/.bashrc ~/.bashrc
ln -s ~/git/dotfiles/shared/.bashrc ~/.bashrc_shared
source ~/.bashrc