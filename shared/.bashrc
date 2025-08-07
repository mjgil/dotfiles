# . `brew --prefix`/Cellar/z/1.6/etc/profile.d/z.sh

# l - ls
# c - git commit
# t - text editor
# o - open finder
# r - resource bashrc

# Make sure the git-prompt script is available for showing git information in the prompt
if [ -f ~/.git-prompt.sh ]; then
   source ~/.git-prompt.sh
fi

export PS1='\[\033[1;34m\][\u@\h jobs:\j \d \A] \n \[\033[1;32m\]$PWD $(__git_ps1 "(%s)")\n \[\033[1;31m\]m\[\033[0m\]: '
# virtualenv ps1 --- export PS1='\[\033[1;34m\][\u@\h jobs:\j \d \A] \n \[\033[1;32m\](`basename $VIRTUAL_ENV`) $PWD $(__git_ps1 "(%s)")\n \[\033[1;31m\]ΝΔ\[\033[0m\]: '
# export PATH="/usr/local/bin:/opt/chef/embedded/bin:$PATH"

# alias hub to git
alias git=hub

# hub aliases
alias gpr="git pull-request"

# git aliases
alias gd="git diff | subl -"
alias ga="git add"
alias gaa="git add --all"
alias gbd="git branch -D"
alias gst="git status"
alias gca="git commit -a -m"
alias gcam="git commit --amend -m"
alias gmnf="git merge --no-ff"
alias gpt="git push --tags"
alias gp="git push"
alias gpn='git push -u origin $(__git_ps1 "%s")'
alias gpom="git push origin main" # Updated to use main instead of master
alias gpf="git push -f"
alias grh="git reset --hard"
alias grha="git status --porcelain -z | cut -c 4- -z | xargs -0 rm -rf && git reset --hard"
alias grm1="git reset --mixed HEAD~1"
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
alias gplom="git pull origin main" # Updated to use main instead of master
alias gcd='cd "`git rev-parse --show-toplevel`"'
alias gc='git add --all :/ && git commit -m'
alias gct='git add --all . && git commit -m'
alias gr='git remote'
alias grv='git remote -v'
alias grs='git remote set-url'
alias gra='git remote add'
alias grr='git remote rename'
alias gfa='git fetch --all'
alias gpa='git fetch --all && git reset --hard HEAD' #git pull all
alias gpac='git fetch --all && git reset --hard HEAD && git clean -f' #git pull all clean




git_commit_push() {
  gc "$1" && gp
}
alias c=git_commit_push

git_clone_org_secure() {
  git clone "git@github.com:$1/$2.git"
}
alias gcos=git_clone_org_secure

git_clone_secure() {
  gcos mjgil $1
}
alias gcs=git_clone_secure

git_remove_file() {
  git filter-branch --index-filter "git rm -rf --cached --ignore-unmatch $1" HEAD
  rm -rf .git/refs/original/ && git reflog expire --all &&  git gc --aggressive --prune
}
alias grmf=git_remove_file

repo_exists() {
  git ls-remote git@github.com:$1/$2.git > /dev/null 2>&1
  result=$?
  if [ $result == 0 ]; then
    echo "repo exists on github"
    return 0
  else
    echo "repo not on github"
    return 1
  fi
}
alias re=repo_exists

git_create_repo() {
  # takes one argument: repo_name
  if ! repo_exists mjgil $1; then
    echo "making ~/git/$1"
    if mkdir ~/git/$1; then
      cd ~/git/$1
      git init
      touch readme.md
      echo "# $1" >> readme.md
      git add readme.md
      git commit -m 'initial commit'
      hub create $1
      git push -u origin main
    fi
  fi
}
alias gcr=git_create_repo

gh_new() {
  # only for creating completely new repos
  if [ -d "$1" ]; then
    echo "Error: Directory '$1' already exists. Aborting."
    return 1
  fi

  local privacy=${2:-"--private"}
  gh repo create $1 $privacy
  gcs $1
  cd $1
  touch readme.md
  git add readme.md
  git commit -m 'add readme'
  git push --set-upstream origin main
}
alias ghn=gh_new

gh_new_existing() {
  local privacy=${2:-"--private"}
  gh repo create $1 --source=. --push $privacy
}
alias ghne=gh_new_existing

gh_new_existing_add() {
  git init
  c 'initial commit'
  ghne $1 $2
}
alias ghnea=gh_new_existing_add

git_merge() {
  # $1 -- branch to merge into
  local cur_branch=${2:-$(__git_ps1 "%s")}
  gco $cur_branch
  gco $1
  git pull
  gco $cur_branch
  git merge $1
}
alias gm=git_merge


bitbucket_to_github() {
  # $1 -- github repo path
  grr origin bitbucket
  gra origin $1
  gpom
}
alias btg=bitbucket_to_github

yt-dlp3() {
  yt-dlp $1 -x --audio-format mp3 --audio-quality 320k
}

yt-dlpp() {
  yt-dlp "$@" -o "%(playlist_index)004d - %(title)s.%(ext)s" 
}

yt-dlp1080() {
  yt-dlp -f "bv[height<=1080]+ba / b[height<=1080] / b" "$@" 
}


yt-dlpfraction() {
  # $1 -- url of video
  # $2 -- start time of video (00:00:15:00 -> start 15 secs in)
  # $3 -- how much time to capture (00:00:10:00 -> 10 secs)
  # $4 -- output name
  ffmpeg $(yt-dlp -f "bestvideo+bestaudio" -g "$1" | sed "s/^/-ss $2 -i /") -t "$3" -c copy "$4.webm"
}

yt-dlpgif() {
  # $1 -- url of video
  # $2 -- start time of video (00:00:15:00 -> start 15 secs in)
  # $3 -- how much time to capture (00:00:10:00 -> 10 secs)
  # $4 -- output name
  URL=$(yt-dlp -g "$1")
  ffmpeg $(yt-dlp -f "bestvideo" -g "$1" | sed "s/^/-ss $2 -i /") -t "$3" -c copy "$4.mp4"
  vid-gif "$4.mp4"
}

vid-gif() {
  gifgen "$1"
  gifgen  -w 320 -o "$1-small.gif" "$1"
  gifgen  -w 640 -o "$1-medium.gif" "$1"
}


yt-dlpp3() {
  yt-dlpp "$@" -x --audio-format mp3 --audio-quality 320k
}

yt-dlppl() {
  yt-dlp -j --flat-playlist "$@" | jq -r '.id' | sed 's_^_https://youtu.be/_'
}

yt-dlpad() {
  # $1: starting index
  # $2: name of file

  die () {
      echo >&2 "$@"
      exit 1
  }

  [ "$#" -eq 2 ] || die "2 arguments required, $# provided"

  AUTONUMBER_START=$1
  FILE_NAME=$2


  let count=1
  for line in $(cat $FILE_NAME); do
    if [ $count -ge $AUTONUMBER_START ]; then
      printf "   %s %s\n" $count $line
      yt-dlp $line --output "%(autonumber)004d - %(title)s.%(ext)s" --autonumber-start $count
    fi
    let count++
  done
}

convert-audio-tempo() {
  # $1 audio tempo
  # $2 filename with extension
  ffmpeg -i "$2" -filter:a "atempo=$1" -vn "${2%%.mp3}-$1".mp3
}

num-files-count() {
  du -a | cut -d/ -f2 | sort | uniq -c | sort -nr
}
alias nfc=num-files-count

video_resolution() {
  ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$1"
}
alias vr=video_resolution

venv() {
case $1 in
  "init")
    pipenv --python "$2"
    source "$(pipenv --venv)/bin/activate"
    export GIL_PIPENV_HOME="$(pwd)"
    ;;
  "start")
    pipenv install
    source "$(pipenv --venv)/bin/activate"
    export GIL_PIPENV_HOME="$(pwd)"
    ;;
  "stop")
    deactivate
    ;;
  "rm")
    deactivate
    cd "$GIL_PIPENV_HOME"
    pipenv --rm
    cd -
    export GIL_PIPENV_HOME=""
    ;;
  "check")
    which python && which pip
    ;;
  *)
    echo "Error: Invalid Option for venv (init, start, stop, rm, check)"
    ;;
esac
}


alias o="open ."
find_any_open() {
  output=$(fa "$1")
  dname=$(dirname "$output")
  o "$dname"
}
alias fao=find_any_open

# tmux aliases
alias tmxn='tmux new-session -s'
alias tmxa='tmux attach-session -t'
alias tmxk='tmux kill-session -t'
alias tmxl='tmux ls'
# detach -- ctrl+b, d

# node aliases
alias npmi='npm install'
alias npmis='npm install --save'
alias npmisd='npm install --save-dev'
alias niy='npm init -y'
alias goy='go mod init m'
alias gody='go mod tidy'
alias javalt="sudo update-alternatives --config java"


# vagrant aliases
alias vinit='vagrant init'
alias vst='vagrant status'
alias vup='vagrant up'
alias vssh='vagrant ssh'
# vagrant box add (boxname)
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


alias l='ls -aF ${colorflag}'
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

# get print sshkey to console
alias sshkey='cat ~/.ssh/id_rsa.pub'

# reload bashrc
alias rebash='source ~/.bashrc'
alias r='rebash'

# gzipped responses
alias gurl='curl --compressed'

# usage PORT=3000 findPort
alias findPort='lsof -n -i4TCP:$PORT | grep LISTEN'

alias connStates='netstat -tan | grep ":80 " | awk "{print $6}" | sort | uniq -c'
alias connTimers='ss -rota | less'


# pstree --- not on a mac
# EDITOR=subl
# export editor
# non-server config

# IP addresses
alias ipc="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en1"
alias ips="ifconfig -a | grep -o 'inet6\? \(\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)\|[a-fA-F0-9:]\+\)' | sed -e 's/inet6* //'"

# Enhanced WHOIS lookups
alias whois="whois -h whois-servers.net"

# Flush Directory Service cache
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"

# View HTTP traffic
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# test editor stuff
alias t="~/git/up-sublime/main"
ct() {
  cd "$1" && t
}
alias hosts="sudo subl /etc/hosts"

alias cdl="cd ~/Downloads"
alias cdv="cd ~/Videos"
alias cdm="cd ~/Music"
alias cdb="cd ~/Dropbox"
alias cdd="cd ~/git/dotfiles"



# OS X has no `md5sum`, so use `md5` as a fallback
command -v md5sum > /dev/null || alias md5sum="md5"

# OS X has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum > /dev/null || alias sha1sum="shasum"

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
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

rust() {
  name=$(basename $1 .rs)
  rustc $@ && ./$name && rm $name
}

initpy() {
  # Check if a directory name is provided
  if [ -z "$1" ]; then
    echo "Usage: initpy <directory_name>"
    return 1
  fi

  # Check if the directory already exists
  if [ -d "$1" ]; then
    echo "Directory '$1' already exists. Exiting."
    return 1
  fi
  
  ./init.sh "$1"
  cd "$1"
}



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


# Clean and organized PATH settings
export PATH="/usr/local/heroku/bin:$PATH"
export PATH="~/.yarn/bin:$PATH"
export PATH="~/.local/bin:$PATH"

export PATH="$HOME/go/bin:/usr/local/go/bin:$PATH" # go
export PATH="/usr/local/hub/bin:$PATH" # hub
source $HOME/.cargo/env # rust
export PATH="$PATH:/opt/mssql-tools/bin"

# ASDF configuration
if command -v asdf >/dev/null 2>&1; then
  # Golang configuration
  export GOROOT=$(asdf where golang)/go
  export PATH="$GOROOT/bin:$PATH"
  
  # Node.js configuration - ensure global npm packages are in PATH
  if NODEJS_VERSION=$(asdf current nodejs 2>/dev/null | awk '{print $2}'); then
    export PATH="$HOME/.asdf/installs/nodejs/$NODEJS_VERSION/bin:$PATH"
    # Add npm configuration for global installs
    export npm_config_prefix="$HOME/.asdf/installs/nodejs/$NODEJS_VERSION"
  fi
fi

# NPM global package aliases
alias npm-global="npm install -g"
alias npm-list-global="npm list -g --depth=0"


