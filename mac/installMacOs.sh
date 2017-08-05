# need developer tools for git
xcode-select --install
sudo xcodebuild -license

# Setup Git
git config --global user.name "Malcom Gilbert"
git config --global user.email malcomgilbert@gmail.com
git config --global core.editor "subl -n -w"
git config --global push.default matching

if [ ! -f ~/.git-prompt.sh ]; then
  curl -o ~/.git-prompt.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi

mkdir ~/git
cd ~/git

# pull down dotfiles
git clone https://github.com/mjgil/dotfiles.git
git clone https://github.com/mjgil/z.git
#
/Users/$(whoami)/git/dotfiles/mac/installSettingsAndApps.sh
/Users/$(whoami)/git/dotfiles/mac/update-bashrc.sh
