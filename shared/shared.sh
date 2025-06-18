#!/usr/bin/env bash
# Import logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/log_utils.sh"

# This script contains common setup for all systems

# Setup Git
# Source our centralized git configuration script
source "${SCRIPT_DIR}/git-config.sh"
setup_git_config

if [ ! -f ~/.git-prompt.sh ]; then
  curl -o ~/.git-prompt.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi

# make git directory
mkdir -p ~/git
cd ~/git || exit

# pull down dotfiles if not already cloned
if [ ! -d ~/git/dotfiles ]; then
  git clone https://github.com/mjgil/dotfiles.git
fi

# clone z repository if not already cloned
if [ ! -d ~/git/z ]; then
  cd ~/git
  git clone https://github.com/mjgil/z.git
  cd - || exit
fi

# clone mini-bash repository if not already cloned
if [ ! -d ~/git/mini-bash ]; then
  cd ~/git
  git clone https://github.com/mjgil/mini-bash.git
  cd -
fi

# link bashrc
cd ~/git/dotfiles || exit
./linux/update-bashrc.sh
git remote set-url origin ssh://git@ssh.github.com:443/mjgil/dotfiles.git
cd -

# install mini-bash
cd ~/git/mini-bash || exit
./install-local.sh
git remote set-url origin ssh://git@ssh.github.com:443/mjgil/mini-bash.git
cd -

# app-settings
# Terminator
mkdir -p ~/.config/terminator
cp ~/git/dotfiles/app-settings/terminator.config ~/.config/terminator/config

# Silicon (code screenshot tool)
mkdir -p ~/.config/silicon
cp ~/git/dotfiles/app-settings/silicon/config.toml ~/.config/silicon/config.toml

# Set time format to AM/PM if on GNOME
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface clock-format 12h
fi

# Set up ASDF language management - wrapper scripts for local user
cd ~/git/dotfiles
./shared/create-package-blockers.sh

# Set up APT hooks if on Debian/Ubuntu - works with sudo too
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  if [[ "$ID" == "ubuntu" || "$ID" == "linuxmint" || "$ID" == "debian" ]]; then
    ./shared/install-apt-hooks.sh
  fi
fi

# set time format to AM/PM if on GNOME
if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface clock-format 12h
fi