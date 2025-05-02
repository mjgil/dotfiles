#!/usr/bin/env bash

# Import logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/shared/log_utils.sh"

# List of programs to check
programs=("git" "hub" "curl" "jq" "google-chrome" "vlc" "tree" "ffmpeg" 
          "tmux" "curl" "wget" "python3" "node" "npm" "java" "javac"
          "python" "pip" "python3" "python3.12" "pip3" "pipenv"
          "brave" "gimp" "go" "cargo" "dfg" "dua" "dug" "dum" "fa"
          "ms" "zipr" "subl" "make" "cmake" "gcloud" "snap" "g++" 
          "g++-10" "mvn" "fastfetch" "asdf" "rg" "ncdu" "dotnet" "cal"
          "sqlite3" "htop" "tsc" "gh" "fd" "just" "hyperfine" "exa"
          "lux" "fzf" "bat" "delta" "shellcheck")

# Counters for passed and failed checks
passed=0
failed=0

# Array to store failed programs
failed_programs=()

# Using log_utils.sh for colored output now

# Function to check if a program is installed
check_program() {
    case "$1" in
        "java")
            if java -version &> /dev/null; then
                log_success "java: Installed"
                ((passed++))
            else
                log_error "java: Not installed"
                ((failed++))
                failed_programs+=("$1")
            fi
            ;;
        "javac")
            if javac -version &> /dev/null; then
                log_success "javac: Installed"
                ((passed++))
            else
                log_error "javac: Not installed"
                ((failed++))
                failed_programs+=("$1")
            fi
            ;;
        "fd")
            if which "fd" &> /dev/null || which "fdfind" &> /dev/null; then
                log_success "fd: Installed ($(which fd 2>/dev/null || which fdfind 2>/dev/null))"
                ((passed++))
            else
                log_error "fd: Not installed"
                ((failed++))
                failed_programs+=("$1")
            fi
            ;;
        "bat")
            if which "bat" &> /dev/null || which "batcat" &> /dev/null; then
                log_success "bat: Installed ($(which bat 2>/dev/null || which batcat 2>/dev/null))"
                ((passed++))
            else
                log_error "bat: Not installed"
                ((failed++))
                failed_programs+=("$1")
            fi
            ;;

        *)
            if which "$1" &> /dev/null; then
                log_success "$1: Installed"
                ((passed++))
            else
                log_error "$1: Not installed"
                ((failed++))
                failed_programs+=("$1")
            fi
            ;;
    esac
}

# Check each program in the list
for program in "${programs[@]}"; do
    check_program "$program"
done

# Display the results
log_echo ""
log_info "Summary:"
log_success "Passed: $passed"
log_error "Failed: $failed"

# Display the failed programs if any
if [ $failed -ne 0 ]; then
    log_echo ""
    log_warning "Programs not installed:"
    for program in "${failed_programs[@]}"; do
        log_error "- $program"
    done
fi

# Exit with the number of failed checks
exit $failed
