# tried xdg-open and open, this one is better
# both of the above don't spawn a new terminal line
# have file descriptor bug as well -- Couldn't get a file descriptor referring to the console
# https://stackoverflow.com/questions/42463929/couldnt-find-a-file-descriptor-referring-to-the-console-on-ubuntu-bash-on-win
alias open="nautilus --new-window"

if [ -f ~/.bashrc_shared ]; then
   source ~/.bashrc_shared
fi

if [ -f ~/.git-prompt.sh ]; then
   source ~/.git-prompt.sh
fi

export PATH="/snap/bin:$PATH" # snap
. "$HOME/.cargo/env"
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export PATH=$PATH:$HADOOP_HOME/bin
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export PATH=$PATH:$HADOOP_HOME/bin
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export PATH=$PATH:$HADOOP_HOME/bin


. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash

# make bash history better
export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, don't overwrite it

run_swift() {
   docker run --rm -v "$(pwd)":/swift-project -w /swift-project swift:5.9 swift $1
}
export PATH="$PATH:$HOME/development/flutter/bin"
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

. "$HOME/.atuin/bin/env"

[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
