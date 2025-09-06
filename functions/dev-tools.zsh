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

# Opens the git repository URL in your default browser
git-open() {
    # Get the remote URL, defaulting to 'origin' if no remote is specified
    local remote="${1:-origin}"
    
    # Extract the URL from git config and remove .git suffix
    local url=$(git config --get remote.$remote.url | sed 's/\.git$//')
    
    # Convert SSH URLs to HTTPS format
    url=$(echo $url | sed 's/git@\([^:]*\):/https:\/\/\1\//')
    
    # Open the URL using the system's default browser
    if [[ $(uname) == "Darwin" ]]; then
        open $url
    elif [[ $(uname) == "Linux" ]]; then
        xdg-open $url
    else
        echo "Unsupported operating system"
        return 1
    fi
}

# Aliases for git-open
alias gopen='git-open'
alias gop='git-open'