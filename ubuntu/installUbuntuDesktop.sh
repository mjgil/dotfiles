#!/usr/bin/env bash

# TODO: add verification text
# check mark if the software is installed correctly


# add the google chrome package
if [ ! -d "/usr/bin/google-chrome" ]; then
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
fi

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
sudo apt-get install -y python-pip
sudo apt-get install -y ffmpeg
sudo apt-get install -y exfat-utils
sudo apt-get install -y exfat-fuse
sudo apt-get install -y vlc
sudo apt-get install -y tmux
sudo apt-get install -y docker-io
# add user to docker group
sudo usermod -a -G docker $USER

# install snap packages
sudo snap install sublime-text --classic
# install package control
# install oceanic next as the theme

sudo snap install ubuntu-make --classic
sudo snap install --classic --channel=1.14/stable go
sudo snap install hub --classic
sudo snap install qbittorrent-arnatious

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


# default to list-view
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'

# update keybindings for terminator copy -> ctrl + c
# update keybindings for terminator paste -> ctrl + v

# add applications to favorites
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'org.gnome.Terminal.desktop']"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'google-chrome.desktop']"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'vlc.desktop']"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'sublime-text_subl.desktop']"

# rm 'snap-store_ubuntu-software.desktop', 'yelp.desktop' from favorites
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/'snap-store_ubuntu-software.desktop'//)"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/'yelp.desktop'//)"

echo "make sure to run make-ssh.sh in shared folder"
