#!/bin/zsh
# Development utility functions that are useful in both interactive and non-interactive shells

# Change to home directory and clear screen
r() {
    cd ~
    clear
}

# Open in Zed
edit() {
    if [ -z "$1" ]; then
        zed "."
    else
        zed "$1"
    fi
}

# Git Reset and Clean
gnah() {
    git reset --hard
    git clean -df
}

# Open GitHub Desktop
gdesktop() {
    open -a 'GitHub Desktop' .
}

# git-open is provided by brew 'git-open' in Brewfile
alias gopen='git-open'
alias gop='git-open'

# List or pick Claude Code skills
clskills() {
    if [[ "$1" == "-p" || "$1" == "--pick" ]]; then
        "$HOME/.claude/skills/picker.sh"
    else
        local names=()
        for dir in "$HOME/.claude/skills"/*/; do
            [[ -d "$dir" ]] || continue
            names+=("$(basename "$dir")")
        done
        printf "%s\n" "${(j: - :)names}"
    fi
}