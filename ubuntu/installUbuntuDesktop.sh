#!/usr/bin/env bash

# TODO: add verification text
# check mark if the software is installed correctly

sudo add-apt-repository ppa:qbittorrent-team/qbittorrent-stable

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y nodejs
sudo apt-get install -y npm
sudo apt-get install -y build-essential
sudo apt-get install -y libssl-dev
sudo apt-get install -y git-core
sudo apt-get install -y curl
sudo apt-get install -y jq
sudo apt-get install -y google-chrome-stable
sudo apt-get install -y ubuntu-make
sudo apt-get install -y python-pip
sudo apt-get install -y qbittorrent
sudo apt-get install -y ffmpeg
sudo apt-get install -y exfat-utils
sudo apt-get install -y exfat-fuse
sudo apt-get install -y vlc
sudo apt-get install -y tmux
sudo apt-get install -y docker-io
# add user to docker group
sudo usermod -a -G docker $USER
# install sublime text

# install snap packages
sudo snap install sublime-text --classic
# install package control
# install oceanic next as the theme
sudo snap install ubuntu-make --classic
sudo snap install --classic --channel=1.14/stable go

curl https://sh.rustup.rs -sSf | bash -s -- -y

# umake web firefox-dev

pip install --upgrade pip
pip install grip

sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g tmpin

# Setup Git
git config --global user.name "Malcom Gilbert"
git config --global user.email malcomgilbert@gmail.com
git config --global core.editor "subl -n -w"
git config --global push.default matching

if [ ! -f ~/.git-prompt.sh ]; then
  curl -o ~/.git-prompt.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi

# make git directory
mkdir ~/git
cd ~/git

# pull down dotfiles
git clone https://github.com/mjgil/dotfiles.git
git clone https://github.com/mjgil/z.git
git clone https://github.com/mjgil/mini-bash.git

# link bashrc
~/git/dotfiles/ubuntu/update-bashrc.sh

# install mini-bash
cd ~/git/mini-bash
./install-local.sh
cd -



# install hub
if [ ! -d "/usr/local/hub" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  wget https://github.com/github/hub/releases/download/v2.5.1/hub-linux-amd64-2.5.1.tgz
  sudo tar -xvf hub-linux-amd64-2.5.1.tgz
  sudo mv hub-linux-amd64-2.5.1 /usr/local/hub
  rm hub-linux-amd64-2.5.1.tgz
fi

cd ~/git

# default to list-view
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
# add ssh key to github
# ssh-keygen -t rsa -b 4096 -C "malcomgilbert@gmail.com"
# cat ~/.ssh/id_rsa.pub
# eval "$(ssh-agent -s)"
# ssh-add ~/.ssh/id_rsa
# go to settings on github and add the key

# update keybindings for terminator copy -> ctrl + c
# update keybindings for terminator paste -> ctrl + v
