#!/bin/bash
# log_utils.sh - Centralized logging utilities

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log function that shows file and function information
log() {
  local message="$1"
  local log_level="${2:-INFO}"
  local color="${3:-$NC}"
  
  # Get calling information
  local calling_file="${BASH_SOURCE[1]##*/}"
  local calling_func="${FUNCNAME[1]:-main}"
  
  # Format timestamp
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Print formatted log message
  printf "${color}[%s] [%s] [%s:%s] %s${NC}\n" "$timestamp" "$log_level" "$calling_file" "$calling_func" "$message"
}

# Convenience logging functions with different levels
log_info() {
  log "$1" "INFO" "$BLUE"
}

log_success() {
  log "$1" "SUCCESS" "$GREEN"
}

log_warning() {
  log "$1" "WARNING" "$YELLOW"
}

log_error() {
  log "$1" "ERROR" "$RED"
}

log_debug() {
  # Only show debug logs if DEBUG is enabled
  if [[ "${DEBUG:-0}" == "1" ]]; then
    log "$1" "DEBUG" "$PURPLE"
  fi
}

# Function to log with the same formatting as regular echo
# Use this for drop-in replacements where formatting is important
log_echo() {
  local message="$1"
  local options="$2" # For options like -n or -e
  
  if [[ "$options" == "-n" ]]; then
    printf "%s" "$message"
  elif [[ "$options" == "-e" ]]; then
    printf "%b\n" "$message"
  else
    printf "%s\n" "$message"
  fi
}

# Export functions
export -f log
export -f log_info
export -f log_success
export -f log_warning
export -f log_error
export -f log_debug
export -f log_echo
