# need developer tools for git
xcode-select --install
sudo xcodebuild -license

# Setup Git
git config --global user.name "Malcom Gilbert"
git config --global user.email malcom@mjgil.com
git config --global core.editor "subl -n -w"
git config --global push.default matching
git config --global core.excludesfile ~/.gitignore
echo *.DS_Store >> ~/.gitignore

if [ ! -f ~/.git-prompt.sh ]; then
  curl -o ~/.git-prompt.sh \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi

mkdir ~/git
cd ~/git

# pull down dotfiles
git clone https://github.com/mjgil/dotfiles.git

# make sure dot files have correct remote origin
cd dotfiles
git remote set-url origin git@github.com:mjgil/dotfiles.git
cd ~/git

git clone https://github.com/mjgil/z.git
#
/Users/$(whoami)/git/dotfiles/mac/installSettingsAndApps.sh
/Users/$(whoami)/git/dotfiles/mac/update-bashrc.sh

ssh-keygen -t rsa -b 4096 -C "malcom@mjgil.com"
