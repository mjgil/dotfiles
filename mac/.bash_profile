if [ -f /usr/local/etc/bash_completion.d/git-completion.bash ]; then
    source /usr/local/etc/bash_completion.d/git-completion.bash
fi


if [ -f /usr/local/etc/bash_completion.d/git-completion.bash ]; then
    source /usr/local/etc/bash_completion.d/git-prompt.sh
fi


if [ -f /usr/local/git/contrib/completion/git-completion.bash ]; then
    source /usr/local/git/contrib/completion/git-prompt.sh
fi


if [ -f /usr/local/git/contrib/completion/git-completion.bash ]; then
    source /usr/local/git/contrib/completion/git-prompt.sh
fi


if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi


if [ -f ~/.git-prompt.sh ]; then
   source ~/.git-prompt.sh
fi

export GOPATH="/Users/malcomgilbert/go"
# added by Anaconda 1.9.1 installer
# export PATH="/usr/local/go/bin:/Users/malcomgilbert/Documents/anaconda/anaconda/bin:$PATH"
export PATH="/Users/malcomgilbert/.cargo/bin:/usr/local/go/bin:$PATH"

alias gam="/Users/malcomgilbert/bin/gam/gam"

##
# Your previous /Users/malcomgilbert/.bash_profile file was backed up as /Users/malcomgilbert/.bash_profile.macports-saved_2017-01-13_at_19:30:16
##

# MacPorts Installer addition on 2017-01-13_at_19:30:16: adding an appropriate PATH variable for use with MacPorts.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.

# export PATH="/usr/local/go/bin:$PATH"

alias gd="git diff | subl"
alias pdfJoin='python /Users/malcomgilbert/Dropbox/Classes/21m.269/pdfJoin.py'
alias pdfJoinc='python /Users/malcomgilbert/Dropbox/Classes/21m.269/pdfJoin.py -o combined.pdf `ls|grep .pdf$`'

# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"
