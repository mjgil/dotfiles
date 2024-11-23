#!/usr/bin/env bash

rm ~/.bashrc
rm ~/.bashrc_shared
ln -s ~/git/dotfiles/linux/.bashrc ~/.bashrc
ln -s ~/git/dotfiles/shared/.bashrc ~/.bashrc_shared
source ~/.bashrc