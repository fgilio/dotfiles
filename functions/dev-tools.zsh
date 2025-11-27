#!/bin/zsh
# Development utility functions that are useful in both interactive and non-interactive shells

# Move files to trash instead of deleting
trash() { 
    command mv "$@" ~/.Trash 
}

# Change to home directory and clear screen
r() {
    cd ~
    clear
}

# Open in Sublime Text
edit() {
    if [ -z "$1" ]; then
        subl "."
    else
        subl "$1"
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