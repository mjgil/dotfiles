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

if [ -f "/etc/apt/preferences.d/nosnap.pref" ]; then
   sudo rm /etc/apt/preferences.d/nosnap.pref
fi


sudo apt update
sudo apt upgrade -y
sudo apt install -y snapd
sudo apt install -y nodejs
sudo apt install -y npm
sudo apt install -y build-essential
sudo apt install -y libssl-dev
sudo apt install -y git-core
sudo apt install -y curl
sudo apt install -y jq
sudo apt install -y google-chrome-stable
sudo apt install -y python3-pip
sudo apt install -y python3-venv

sudo apt install -y ffmpeg
sudo apt install -y exfat-utils
sudo apt install -y exfat-fuse
sudo apt install -y vlc
sudo apt install -y tmux
sudo apt install -y terminator
sudo apt install -y tree


sudo apt install -y software-properties-common
sudo apt install -y python3.9
sudo apt install -y python3.9-distutils
sudo ln -s /usr/bin/python3.9 /usr/bin/python
curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python
pip install yt-dlp
pip install -U yt-dlp



# install snap packages
sudo snap install sublime-text --classic
# install package control
# install oceanic next as the theme

sudo snap install ubuntu-make --classic
sudo snap install hub --classic
sudo snap install qbittorrent-arnatious
sudo snap install gravit-designer
sudo snap install vectr
sudo snap install gimp

# install go
wget -c https://go.dev/dl/go1.21.1.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
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
sudo node_modules/n/bin/n 20.14

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

cp /var/lib/snapd/desktop/applications/*.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/

# github commands
echo "make github key"
echo "update git config file"


# install dropbox
# sudo nano /etc/apt/sources.list.d/dropbox.list
# add line -- deb [arch=i386,amd64] http://linux.dropbox.com/ubuntu bionic main
# sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
# sudo apt update
# sudo apt install python3-gpg dropbox
