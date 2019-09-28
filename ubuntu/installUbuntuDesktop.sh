#!/usr/bin/env bash


# add sublime text package
if [ ! "$(which subl)" ]; then
  sudo add-apt-repository -y ppa:webupd8team/sublime-text-3
fi


# add the google chrome package
if [ ! -d "/usr/local/go" ]; then
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
fi

if [ ! "$(which umake)" ]; then
  sudo add-apt-repository -y ppa:ubuntu-desktop/ubuntu-make
fi

if [ ! "$(which atom)" ]; then
  sudo add-apt-repository -y ppa:webupd8team/atom
fi

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
sudo apt-get install -y atom
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
# install package control
# install oceanic next as the theme
sudo apt-get install -y sublime-text-installer
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

# install go
if [ ! -d "/usr/local/go" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  wget https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz
  sudo tar -xvf go1.13.1.linux-amd64.tar.gz
  sudo mv go /usr/local
  rm go1.13.1.linux-amd64.tar.gz
fi

# link bashrc
~/git/dotfiles/ubuntu/update-bashrc.sh


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

# sublime text from ubuntu installer
ln -s /snap/sublime-text/current/opt/sublime_text/sublime_text /usr/local/bin/subl