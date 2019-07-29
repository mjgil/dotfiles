if [ -f ~/.bashrc_shared ]; then
   source ~/.bashrc_shared
fi

if [ -f ~/.git-prompt.sh ]; then
   source ~/.git-prompt.sh
fi


alias gd="git diff | tmpin subl"
alias open="xgd-open"