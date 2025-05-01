#!/usr/bin/env bash

# List of programs to check
programs=("git" "hub" "curl" "jq" "google-chrome" "vlc" "tree" "ffmpeg" 
          "tmux" "curl" "wget" "python3" "node" "npm" "java" "javac"
          "python" "pip" "python3" "python3.12" "pip3" "pipenv"
          "brave" "gimp" "go" "cargo" "dfg" "dua" "dug" "dum" "fa"
          "ms" "zipr" "subl" "make" "cmake" "gcloud" "snap" "g++" 
          "g++-10" "mvn" "fastfetch" "asdf" "rg" "ncdu" "dotnet" "cal"
          "sqlite3" "htop" "tsc" "gh" "fd" "just" "hyperfine" "exa"
          "atuin" "lux" "fzf" "bat" "delta" "shellcheck")

# Counters for passed and failed checks
passed=0
failed=0

# Array to store failed programs
failed_programs=()

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

# Function to check if a program is installed
check_program() {
    case "$1" in
        "java")
            if java -version &> /dev/null; then
                echo -e "${GREEN}java: Installed${NC}"
                ((passed++))
            else
                echo -e "${RED}java: Not installed${NC}"
                ((failed++))
                failed_programs+=("$1")
            fi
            ;;
        "javac")
            if javac -version &> /dev/null; then
                echo -e "${GREEN}javac: Installed${NC}"
                ((passed++))
            else
                echo -e "${RED}javac: Not installed${NC}"
                ((failed++))
                failed_programs+=("$1")
            fi
            ;;
        "fd")
            if which "fd" &> /dev/null || which "fdfind" &> /dev/null; then
                echo -e "${GREEN}fd: Installed ($(which fd 2>/dev/null || which fdfind 2>/dev/null))${NC}"
                ((passed++))
            else
                echo -e "${RED}fd: Not installed${NC}"
                ((failed++))
                failed_programs+=("$1")
            fi
            ;;
        "bat")
            if which "bat" &> /dev/null || which "batcat" &> /dev/null; then
                echo -e "${GREEN}bat: Installed ($(which bat 2>/dev/null || which batcat 2>/dev/null))${NC}"
                ((passed++))
            else
                echo -e "${RED}bat: Not installed${NC}"
                ((failed++))
                failed_programs+=("$1")
            fi
            ;;
        "atuin")
            local atuin_path
            atuin_path=$(which atuin 2>/dev/null)
            if [[ -z "$atuin_path" && -f "$HOME/.atuin/bin/atuin" ]]; then
                atuin_path="$HOME/.atuin/bin/atuin"
            fi

            if [[ -n "$atuin_path" ]]; then
                echo -e "${GREEN}atuin: Installed ($atuin_path)${NC}"
                ((passed++))
            else
                echo -e "${RED}atuin: Not installed${NC}"
                ((failed++))
                failed_programs+=("$1")
            fi
            ;;
        *)
            if which "$1" &> /dev/null; then
                echo -e "${GREEN}$1: Installed${NC}"
                ((passed++))
            else
                echo -e "${RED}$1: Not installed${NC}"
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
echo ""
echo "Summary:"
echo -e "${GREEN}Passed: $passed${NC}"
echo -e "${RED}Failed: $failed${NC}"

# Display the failed programs if any
if [ $failed -ne 0 ]; then
    echo ""
    echo "Programs not installed:"
    for program in "${failed_programs[@]}"; do
        echo -e "${RED}- $program${NC}"
    done
fi

# Exit with the number of failed checks
exit $failed
