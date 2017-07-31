#!/usr/bin/env bash

rm ~/.bash_profile
rm ~/.bashrc
ln -s /Users/$(whoami)/git/dotfiles/mac/.bash_profile ~/.bash_profile
ln -s /Users/$(whoami)/git/dotfiles/shared/.bashrc ~/.bashrc