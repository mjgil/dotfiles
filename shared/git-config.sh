#!/usr/bin/env bash
# Centralized Git configuration script
# Import logging utilities if not already sourced
if [ -z "$LOG_UTILS_SOURCED" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${SCRIPT_DIR}/log_utils.sh"
fi

# Setup Git configuration
setup_git_config() {
  local dry_run=${1:-false}
  log_info "Setting up Git configuration..."
  
  if $dry_run; then
    log_info "[DRY RUN] Would configure Git"
    return 0
  fi

  # Write to home directory gitconfig file explicitly using echo
  log_info "Creating .gitconfig file at $HOME/.gitconfig"
  echo "[user]
	name = Malcom Gilbert
	email = malcomgilbert@gmail.com
[core]
	editor = subl -n -w
	excludesfile = $HOME/.gitignore
[push]
	default = matching
[filter \"lfs\"]
	process = git-lfs filter-process
	required = true
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
[init]
	defaultBranch = main" > "$HOME/.gitconfig"
  log_info "Created .gitconfig file"
  
  # Create .gitignore file if it doesn't exist
  if [ ! -f "$HOME/.gitignore" ]; then
    log_info "Creating .gitignore file at $HOME/.gitignore"
    touch "$HOME/.gitignore"
    log_info "Created .gitignore file"
  fi
  
  # Add common patterns to .gitignore if not already present
  if ! grep -q "\.DS_Store" "$HOME/.gitignore"; then
    log_info "Adding .DS_Store to .gitignore"
    echo "*.DS_Store" >> "$HOME/.gitignore"
  fi
  
  # Setup git-prompt if not already present
  if [ ! -f "$HOME/.git-prompt.sh" ]; then
    log_info "Downloading git-prompt.sh"
    curl -o "$HOME/.git-prompt.sh" \
      https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
  fi
}

# If this script is being run directly, not sourced
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  setup_git_config
fi
