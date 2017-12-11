#!/usr/bin/env bash

rm ~/.bashrc
rm ~/.bashrc_shared
ln -s ~/git/dotfiles/ubuntu/.bashrc ~/.bashrc
ln -s ~/git/dotfiles/shared/.bashrc ~/.bashrc_shared