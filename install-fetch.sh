#!/usr/bin/env bash

if [ ! -d "/usr/bin/fastfetch" ]; then
  sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
fi

sudo apt update
sudo apt upgrade

sudo apt install -y fastfetch