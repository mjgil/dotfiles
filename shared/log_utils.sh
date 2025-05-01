#!/usr/bin/env bash
# log_utils.sh - Common logging functions

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Get the base name of the script that sourced this file
CALLING_SCRIPT_BASENAME=$(basename "${BASH_SOURCE[1]:-$0}")

# Function to log informational messages
function log_info() {
  local message="$1"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "[$timestamp] ${BLUE}[INFO]${NC} [${CALLING_SCRIPT_BASENAME}:${BASH_LINENO[0]}] $message"
}

# Function to log success messages
function log_success() {
  local message="$1"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "[$timestamp] ${GREEN}[SUCCESS]${NC} [${CALLING_SCRIPT_BASENAME}:${BASH_LINENO[0]}] $message"
}

# Function to log warning messages
function log_warning() {
  local message="$1"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "[$timestamp] ${YELLOW}[WARNING]${NC} [${CALLING_SCRIPT_BASENAME}:${BASH_LINENO[0]}] $message" >&2
}

# Function to log error messages
function log_error() {
  local message="$1"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "[$timestamp] ${RED}[ERROR]${NC} [${CALLING_SCRIPT_BASENAME}:${BASH_LINENO[0]}] $message" >&2
}

# Convenience logging functions with different levels
log_debug() {
  # Only show debug logs if DEBUG is enabled
  if [[ "${DEBUG:-0}" == "1" ]]; then
    log "$1" "DEBUG" "$MAGENTA"
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
export -f log_info
export -f log_success
export -f log_warning
export -f log_error
export -f log_debug
export -f log_echo
