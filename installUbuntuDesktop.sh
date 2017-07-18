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

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y nodejs
sudo apt-get install -y npm
sudo apt-get install -y build-essential
sudo apt-get install -y libssl-dev
sudo apt-get install -y git-core
sudo apt-get install -y curl
sudo apt-get install -y terminator
sudo apt-get install -y google-chrome-stable 

sudo ln -s /usr/bin/nodejs /usr/bin/node

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

# need go for hub on Ubuntu
if [ ! -d "/usr/local/go" ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  wget https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz
  sudo tar -xvf go1.8.3.linux-amd64.tar.gz
  sudo mv go /usr/local
  rm go1.8.3.linux-amd64.tar.gz
fi

# link bashrc
rm ~/.bashrc
ln -s /home/$(whoami)/git/dotfiles/.bashrc_ubuntu_desktop ~/.bashrc
ln -s /home/$(whoami)/git/dotfiles/.bashrc_shared ~/.bashrc_shared

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

# update keybindings for terminator copy -> ctrl + c
# update keybindings for terminator paste -> ctrl + v

