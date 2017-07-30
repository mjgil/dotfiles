if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi

if [ -f ~/.git-prompt.sh ]; then
   source ~/.git-prompt.sh
fi


alias gd="git diff | tmpin subl"
alias open="nautilus --browser"