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
  sudo add-apt-repository -y ppa:gnome-terminator
fi

if [ ! -d "/usr/bin/fastfetch" ]; then
  sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
fi

# linux mint
if [ -f "/etc/apt/preferences.d/nosnap.pref" ]; then
   sudo rm /etc/apt/preferences.d/nosnap.pref
fi


sudo apt update
sudo apt upgrade -y
sudo apt install -y ncal
sudo apt install -y snapd
sudo apt install -y nautilus
sudo apt install -y imagemagick
sudo apt install -y nodejs
sudo apt install -y npm
sudo apt install -y build-essential
sudo apt install -y libssl-dev
sudo apt install -y git-core
sudo apt install -y curl
sudo apt install -y jq
sudo apt install -y google-chrome-stable

sudo apt install -y ffmpeg
sudo apt install -y exfat-utils
sudo apt install -y exfat-fuse
sudo apt install -y vlc
sudo apt install -y tmux
sudo apt install -y terminator
sudo apt install -y tree
sudo apt install -y fastfetch
sudo apt install -y ripgrep
sudo apt install -y ncdu


# install snap packages
sudo snap install sublime-text --classic
pkill sublime_text
sleep 1
pkill sublime_text
subl --command "install_package_control"
sleep 1
pkill sublime_text
# install package control
# install oceanic next as the theme

sudo snap install ubuntu-make --classic
sudo snap install cmake --classic
sudo snap install hub --classic
sudo snap install qbittorrent-arnatious
sudo snap install brave
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



### install python with sqlite3 and tkinter working
# need to install sqlite3 before installing python
sudo apt install -y software-properties-common
export LDFLAGS="-L/usr/local/opt/sqlite/lib"
export CPPFLAGS="-I/usr/local/opt/sqlite/include"
export PKG_CONFIG_PATH="/usr/local/opt/sqlite/lib/pkgconfig"
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev \
liblzma-dev python3-openssl git
sudo apt install -y libsqlite3-dev

# install asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
. "$HOME/.asdf/asdf.sh"
asdf plugin-add python
asdf install python 3.9.19
asdf global python 3.9.19

pip install pipenv
pip install grip
pip install tabulate
# 
### end install python

# install java
asdf plugin-add java
asdf install java openjdk-21.0.2
asdf global java openjdk-21.0.2

# install dotnet
asdf plugin-add dotnet
asdf install dotnet 7.0.100
asdf global dotnet 7.0.100




sudo apt install -y maven

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

# linux mint
cp /var/lib/snapd/desktop/applications/*.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
gsettings set org.cinnamon.desktop.interface clock-use-24h false
gsettings set org.cinnamon.desktop.interface clock-show-date true
gsettings set org.nemo.preferences default-folder-viewer 'list-view'






current_list=$(gsettings get org.cinnamon.desktop.keybindings custom-list)
# Check if the list already contains 'custom0'
if echo "$current_list" | grep -q "'custom0'"; then
  echo "'custom0' is already in the list"
else
  gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ name 'Area Screenshot'
  gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ binding "['<Primary>Print']"
  gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ command "gnome-screenshot -a"
  # Check if the list is empty
  if [[ "$current_list" == "@as []" ]]; then
    # If the list is empty, create a new list with 'custom0'
    new_list="@as ['custom0']"
  else
    # If the list is not empty, append 'custom0' to the list
    new_list=$(echo "$current_list" | sed "s/]/, 'custom0']/g")
  fi

  # Set the updated list of custom keybindings
  gsettings set org.cinnamon.desktop.keybindings custom-list "$new_list"
fi


# don't group applications by window
for file in ~/.cinnamon/configs/grouped-window-list@cinnamon.org/*.json; do
  cp "$file" "$file.bak"
  jq '.["group-apps"].value = false' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
done

sudo apt install --reinstall -o Dpkg::Options::="--force-confmiss" grub2-theme-mint


# app-settings
mkdir -p ~/.config/terminator
cp ~/git/dotfiles/app-settings/terminator.config ~/.config/terminator/config

# github commands
echo "run post-dotfiles-script"
echo "run ../check-installed.sh"


# install dropbox
# sudo nano /etc/apt/sources.list.d/dropbox.list
# add line -- deb [arch=i386,amd64] http://linux.dropbox.com/ubuntu bionic main
# sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
# sudo apt update
# sudo apt install python3-gpg dropbox
