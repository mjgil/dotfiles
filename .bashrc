# . `brew --prefix`/Cellar/z/1.6/etc/profile.d/z.sh

export PS1='\[\033[1;34m\][\u@\h jobs:\j \d \A] \n \[\033[1;32m\]$PWD $(__git_ps1 "(%s)")\n \[\033[1;31m\]ΝΔ\[\033[0m\]: '
# virtualenv ps1 --- export PS1='\[\033[1;34m\][\u@\h jobs:\j \d \A] \n \[\033[1;32m\](`basename $VIRTUAL_ENV`) $PWD $(__git_ps1 "(%s)")\n \[\033[1;31m\]ΝΔ\[\033[0m\]: '
# export PATH="/usr/local/bin:/opt/chef/embedded/bin:$PATH"

# alias hub to git
alias git=hub

# hub aliases
alias gpr="git pull-request"

# git aliases
alias gd="git diff | subl"
alias ga="git add"
alias gaa="git add --all"
alias gbd="git branch -D"
alias gst="git status"
alias gca="git commit -a -m"
alias gmnf="git merge --no-ff"
alias gpt="git push --tags"
alias gp="git push"
alias gpn='git push -u origin $(__git_ps1 "%s")'
alias gpom="git push origin master"
alias gpf="git push -f"
alias grh="git reset --hard"
alias gb="git branch"
alias gcob="git checkout -b"
alias gco="git checkout"
alias gba="git branch -a"
alias gbv="git branch -v"
alias gchp="git cherry-pick"
alias gl="git log --pretty='format:%Cgreen%h%Creset %an - %s' --graph"
alias glo="git log --color --oneline | head"
alias gpl="git pull"
alias gplo="git pull origin"
alias gplom="git pull origin master"
alias gcd='cd "`git rev-parse --show-toplevel`"'
alias gc='git add --all :/ && git commit -m'
alias gct='git add --all . && git commit -m'
alias gr='git remote'
alias grv='git remote -v'
alias gfa='git fetch --all'
alias gpa='git fetch --all && git reset --hard HEAD' #git pull all
alias gpac='git fetch --all && git reset --hard HEAD && git clean -f' #git pull all clean

git_merge() {
    # $1 -- branch to merge into
    cur_branch=${2:-$(__git_ps1 "%s")}
    gco $cur_branch
    gco $1
    git pull
    gco $cur_branch
    git merge $1
}
alias gm=git_merge

# tmux aliases
alias tmxn='tmux new-session -s'
alias tmxa='tmux attach-session -t'
alias tmxk='tmux kill-session -t'
alias tmxl='tmux ls'

# node aliases
alias nodeh='node --harmony-generators'
alias npmi='npm install'
alias npmis='npm install --save'
alias npmisd='npm install --save-dev'

# vagrant aliases
alias vst='vagrant status'
alias vup='vagrant up'
alias vssh='vagrant ssh'
# alias npmisd='npm install --save-dev'

# ansible aliases
# ansible-playbook
# ansible all -m ping
# ansible.cfg -> forks=100
# setup module, gets gathered facts
# ansible $hostname -m setup -a "filter=ansible_hostname"

# [ab] -- apache benchmark
# ab -n 10000 -c 25 http://localhost:8080

# ssh-keyscan -- get ssh keys for remote servers
# [usage] ssh-keyscan server1 server2 >> ~/.ssh/known_hosts

# node aliases
alias pdfJoin='python /Users/malcomgilbert/Dropbox/Classes/21m.269/pdfJoin.py'
alias pdfJoinc='python /Users/malcomgilbert/Dropbox/Classes/21m.269/pdfJoin.py -o combined.pdf `ls|grep .pdf$`'


# Easier navigation: .., ..., ...., ....., ~ and -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"

# Detect which `ls` flavor is in use
if ls --color > /dev/null 2>&1; then # GNU `ls`
  colorflag="--color"
else # OS X `ls`
  colorflag="-G"
fi

alias ls='ls -aF ${colorflag}'
alias ll='ls -lahF ${colorflag}'

# kill pyc files
alias klpyc='find . -name "*.pyc" -delete'

# find all files of type in nested directories and move them to current directory
# find . -name '*.ttf' -exec mv {} ./ \;

# mkdir aliases
alias mkdirp='mkdir -p'
alias mkdirv='mkdir -v'

# the equalizer
alias rmrf='rm -rf'

# soft symlinks
# [usage] lns original linked
alias lns='ln -s'
alias sl='ln -s'
alias hl='ln'

# gzipped responses
alias gurl='curl --compressed'

# usage PORT=3000 findPort
alias findPort='lsof -n -i4TCP:$PORT | grep LISTEN'

# find size of current subdirectories
alias duc='du -sh */'

# find directories larger than 1000MB
function dul { du -sh * | grep '\d*\.*\dG'; }
export -f dul

# find directories larger than 100MB
function dulm { du -sh * | grep '\d\d\dM'; }
export -f dulm
# pstree --- not on a mac
# EDITOR=subl
# export editor
# non-server config

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en1"
alias ips="ifconfig -a | grep -o 'inet6\? \(\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)\|[a-fA-F0-9:]\+\)' | sed -e 's/inet6* //'"

# Enhanced WHOIS lookups
alias whois="whois -h whois-servers.net"

# Flush Directory Service cache
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# OS X has no `md5sum`, so use `md5` as a fallback
command -v md5sum > /dev/null || alias md5sum="md5"

# OS X has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum > /dev/null || alias sha1sum="shasum"

# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
. ~/git/z/z.sh

# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH"

# # Load the shell dotfiles, and then some:
# # * ~/.path can be used to extend `$PATH`.
# # * ~/.extra can be used for other settings you don’t want to commit.
# for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
#   [ -r "$file" ] && [ -f "$file" ] && source "$file"
# done
# unset file

# # Case-insensitive globbing (used in pathname expansion)
# shopt -s nocaseglob

# make bash history better
export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, don't overwrite it

# Save and reload the history after each command finishes
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# # Autocorrect typos in path names when using `cd`
# shopt -s cdspell

# # Enable some Bash 4 features when possible:
# # * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# # * Recursive globbing, e.g. `echo **/*.txt`
# for option in autocd globstar; do
#   shopt -s "$ option" 2> /dev/null
# done

# # Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
# [ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2 | tr ' ' '\n')" scp sftp ssh

# # Add tab completion for `defaults read|write NSGlobalDomain`
# # You could just use `-g` instead, but I like being explicit
# complete -W "NSGlobalDomain" defaults

# # Add `killall` tab completion for common apps
# complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall

# # If possible, add tab completion for many more commands
# [ -f /etc/bash_completion ] && source /etc/bash_completion

# source /usr/local/bin/virtualenvwrapper.sh

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"
export PYTHONPATH="/usr/local/lib/python2.7/site-packages:$PYTHONPATH"
export GOPATH="/Users/malcomgilbert/go"
