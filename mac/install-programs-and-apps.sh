#!/usr/bin/env bash

# Install Homebrew if it does not exist
if test ! $(which brew)
then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew update

# TODO: fix for different names, imagemagick (magick,convert), ripgrep (rg), gcc@10, etc...
ifnot_brew_install() {
  if test ! $(which $1)
  then
    brew install $1
  fi  
}

brew_cask_install() {
  brew install $1 --cask
}

# Install Essential Programs/Languages
ifnot_brew_install git
ifnot_brew_install wget
ifnot_brew_install node
ifnot_brew_install hub
ifnot_brew_install go
ifnot_brew_install rust
ifnot_brew_install asdf
ifnot_brew_install pipenv
ifnot_brew_install haskell-stack
ifnot_brew_install elixir
ifnot_brew_install hardlink-osx
ifnot_brew_install yt-dlp
ifnot_brew_install ffmpeg
ifnot_brew_install tree
ifnot_brew_install jq
ifnot_brew_install gnupg
ifnot_brew_install cmake
ifnot_brew_install tmux
ifnot_brew_install mvn
ifnot_brew_install snap
ifnot_brew_install gcc@10
ifnot_brew_install ripgrep
ifnot_brew_install ncdu
ifnot_brew_install handbrake
ifnot_brew_install mas
ifnot_brew_install gh


# install gifgen
brew install lukechilds/tap/gifgen

# browsers
brew_cask_install google-chrome
brew_cask_install google-chrome@canary
brew_cask_install google-cloud-sdk
brew_cask_install firefox
brew_cask_install firefox@beta
brew_cask_install safari-technology-preview
brew_cask_install brave-browser

# coding
brew_cask_install kaleidoscope
brew_cask_install iterm2
# brew_cask_install mou
# brew_cask_install parallels-desktop
brew_cask_install virtualbox
brew_cask_install docker
brew_cask_install paw
brew_cask_install sourcetree
brew_cask_install sublime-text
brew_cask_install atom
# brew_cask_install entr # watch file for changes and do stuff
# ex: ls *.js | entr npm test

# essential
brew_cask_install 1password
brew_cask_install alfred
brew_cask_install caffeine
brew_cask_install flux
brew_cask_install dropbox
brew_cask_install calibre
brew_cask_install handbrake
brew_cask_install vagrant
brew_cask_install virtualbox
brew_cask_install rectangle
# brew_cask_install evernote
# brew_cask_install licecap

# for fun
# brew_cask_install spotify
brew_cask_install vlc
brew_cask_install webtorrent

# other
brew_cask_install bartender
brew_cask_install istat-menus
brew_cask_install screenflow
brew_cask_install skype
brew_cask_install slack
brew_cask_install the-unarchiver
brew_cask_install gimp


echo "Done. Note that some of these changes require a logout/restart to take effect."
