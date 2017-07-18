#!/usr/bin/env bash

# download this file wget 

sudo add-apt-repository -y ppa:webupd8team/sublime-text-3
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y nodejs
sudo apt-get install -y npm
sudo apt-get install -y build-essential
sudo apt-get install -y libssl-dev
sudo apt-get install -y git-core
sudo apt-get install -y golang
sudo apt-get install -y curl
sudo apt-get install -y terminator

sudo ln -s /usr/bin/nodejs /usr/bin/node

# Setup Git
git config --global user.name "Malcom Gilbert"
git config --global user.email malcomgilbert@gmail.com
git config --global core.editor "subl -n -w"
git config --global push.default matching

curl -o ~/.git-prompt.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

mkdir ~/git
cd ~/git
git clone https://github.com/mjgil/dotfiles.git

# update keybindings for terminator copy -> ctrl + c
# update keybindings for terminator paste -> ctrl + v