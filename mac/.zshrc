setopt prompt_subst
autoload -Uz vcs_info # enable vcs_info
precmd () { vcs_info } # always load before displaying the prompt
zstyle ':vcs_info:*' formats ' (%F{yellow}%b%f)' # git(main)



source ~/.bash_profile

# make history better
export HISTSIZE=100000
export SAVEHIST=100000

# Append to the history file, rather than overwriting it
setopt APPEND_HISTORY

# Save the history to the file immediately after each command
setopt INC_APPEND_HISTORY

# Share history across all sessions
setopt SHARE_HISTORY

NEWLINE=$'\n'
PS1='%F{033}[%n@%m] jobs:%j %T $(date +%m-%d-%Y)%f${NEWLINE}%F{yellow}%/%f${vcs_info_msg_0_}  ${NEWLINE}%F{red}m%f: '
