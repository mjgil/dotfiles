#!/bin/bash

# A simple script to run shellcheck on all .sh files in specific directories
ROOT_DIR="/home/m/git/dotfiles"

echo "Checking scripts in root directory"
for script in "$ROOT_DIR"/*.sh; do
    if [ -f "$script" ]; then
        echo "Checking $script"
        shellcheck "$script" || echo "Issues found in $script"
    fi
done

echo "Checking scripts in linux directory"
for script in "$ROOT_DIR/linux"/*.sh; do
    if [ -f "$script" ]; then
        echo "Checking $script"
        shellcheck "$script" || echo "Issues found in $script"
    fi
done

echo "Checking scripts in shared directory"
for script in "$ROOT_DIR/shared"/*.sh; do
    if [ -f "$script" ]; then
        echo "Checking $script"
        shellcheck "$script" || echo "Issues found in $script"
    fi
done

echo "Checking complete"
