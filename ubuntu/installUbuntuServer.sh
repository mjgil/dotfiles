#!/usr/bin/env bash


# add the google chrome package
if [ ! -d "/usr/local/go" ]; then
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
sudo apt-get install -y python-pip
# install sublime text
# install package control
# install oceanic next as the theme
curl https://sh.rustup.rs -sSf | sh

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

# need go for hub on Ubuntu
if [ ! -d "/usr/local/go" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  wget https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz
  sudo tar -xvf go1.8.3.linux-amd64.tar.gz
  sudo mv go /usr/local
  rm go1.8.3.linux-amd64.tar.gz
fi

# link bashrc
~/git/dotfiles/ubuntu/update-bashrc.sh

# install hub
cd ~/git
git clone https://github.com/github/hub.git && cd hub
script/build -o ~/bin/hub

cd ~/git

# add ssh key to github
# ssh-keygen -t rsa -b 4096 -C "malcomgilbert@gmail.com"
# cat ~/.ssh/id_rsa.pub
# eval "$(ssh-agent -s)"
# ssh-add ~/.ssh/id_rsa
# go to settings on github and add the key

# update keybindings for terminator copy -> ctrl + c
# update keybindings for terminator paste -> ctrl + v
