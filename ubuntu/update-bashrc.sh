#!/usr/bin/env bash

rm ~/.bashrc
rm ~/.bashrc_shared
ln -s /home/$(whoami)/git/dotfiles/ubuntu/.bashrc ~/.bashrc
ln -s /home/$(whoami)/git/dotfiles/shared/.bashrc ~/.bashrc_shared