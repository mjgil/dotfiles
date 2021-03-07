#!/usr/bin/env bash

# TODO: add verification text
# check mark if the software is installed correctly


# add the google chrome package
if [ ! -d "/usr/bin/google-chrome" ]; then
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
fi

# add terminator
if [ ! -d "/usr/bin/terminator" ]; then
  sudo add-apt-repository ppa:gnome-terminator
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
sudo apt-get install -y python3-pip
sudo apt-get install -y ffmpeg
sudo apt-get install -y exfat-utils
sudo apt-get install -y exfat-fuse
sudo apt-get install -y vlc
sudo apt-get install -y tmux
sudo apt-get install -y terminator
sudo apt-get install -y tree

# install snap packages
sudo snap install sublime-text --classic
# install package control
# install oceanic next as the theme

sudo snap install ubuntu-make --classic
sudo snap install hub --classic
sudo snap install qbittorrent-arnatious
sudo snap install gravit-designer
sudo snap install vectr

# install go
wget -c https://dl.google.com/go/go1.14.2.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
# to check `go env` `go version` `go run $filename`

sudo groupadd docker
sudo usermod -aG docker $USER
sudo snap install docker
# sudo chmod 666 /var/run/docker.sock

curl https://sh.rustup.rs -sSf | bash -s -- -y

# umake web firefox-dev

pip3 install grip

# update node version
npm install n
sudo node_modules/n/bin/n 12.7

sudo npm install -g tmpin

sudo wget https://yt-dl.org/downloads/latest/youtube-dl -O /usr/local/bin/youtube-dl
sudo chmod a+rx /usr/local/bin/youtube-dl
sudo ln -s /usr/bin/python3 /usr/bin/python

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
cd ~/git/dotfiles
./ubuntu/update-bashrc.sh
git remote set-url origin ssh://git@ssh.github.com:443/mjgil/dotfiles.git
cd -

# install mini-bash
cd ~/git/mini-bash
./install-local.sh
git remote set-url origin ssh://git@ssh.github.com:443/mjgil/mini-bash.git
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
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'terminator.desktop']"

# rm 'snap-store_ubuntu-software.desktop', 'yelp.desktop' from favorites
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/'snap-store_ubuntu-software.desktop'//)"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/'yelp.desktop'//)"

# set time format to AM/PM
gsettings set org.gnome.desktop.interface clock-format 12h

# generate new ssh key for github
~/git/dotfiles/shared/make-ssh.sh


# install dropbox
# sudo nano /etc/apt/sources.list.d/dropbox.list
# add line -- deb [arch=i386,amd64] http://linux.dropbox.com/ubuntu bionic main
# sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
# sudo apt update
# sudo apt install python3-gpg dropbox
