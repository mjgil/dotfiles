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
