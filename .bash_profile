if [ -f /usr/local/etc/bash_completion.d/git-completion.bash ]; then
    source /usr/local/etc/bash_completion.d/git-completion.bash
fi


if [ -f /usr/local/etc/bash_completion.d/git-completion.bash ]; then
    source /usr/local/etc/bash_completion.d/git-prompt.sh
fi


if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi
# added by Anaconda 1.9.1 installer
# export PATH="/usr/local/go/bin:/Users/malcomgilbert/Documents/anaconda/anaconda/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"
