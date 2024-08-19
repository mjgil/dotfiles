#!/usr/bin/env bash

# List of programs to check
programs=("git" "hub" "curl" "jq" "google-chrome" "vlc" "tree" "ffmpeg" 
          "tmux" "curl" "wget" "python3" "node" "npm" "java" "javac"
          "python" "pip" "python3" "python3.9" "pip3" "pipenv" "yt-dlp"
          "brave" "gimp" "go" "cargo" "n" "dfg" "dua" "dug" "dum" "fa"
          "ms" "zipr" "subl" "make" "cmake" "gcloud" "snap" "g++" 
          "g++-10" "mvn" "fastfetch" "asdf" "rg" "ncdu" "dotnet" "cal")

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
    if [[ "$1" == "java" ]]; then
        if java -version &> /dev/null; then
            echo -e "${GREEN}java: Installed${NC}"
            ((passed++))
        else
            echo -e "${RED}java: Not installed${NC}"
            ((failed++))
            failed_programs+=("java")
        fi
    elif [[ "$1" == "javac" ]]; then
        if javac -version &> /dev/null; then
            echo -e "${GREEN}javac: Installed${NC}"
            ((passed++))
        else
            echo -e "${RED}javac: Not installed${NC}"
            ((failed++))
            failed_programs+=("javac")
        fi
    elif which $1 &> /dev/null; then
        echo -e "${GREEN}$1: Installed${NC}"
        ((passed++))
    else
        echo -e "${RED}$1: Not installed${NC}"
        ((failed++))
        failed_programs+=($1)
    fi
}

# Check each program in the list
for program in "${programs[@]}"; do
    check_program $program
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
