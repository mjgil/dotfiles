# need developer tools for git
xcode-select --install
sudo xcodebuild -license

mkdir ~/git
cd ~/git

# pull down dotfiles
git clone https://github.com/mjgil/dotfiles.git
git clone https://github.com/mjgil/z.git
#
/Users/$(whoami)/git/dotfiles/mac/installSettingsAndApps.sh
/Users/$(whoami)/git/dotfiles/mac/update-bashrc.sh
