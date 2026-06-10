#!/bin/zsh
# Custom shell functions and aliases, sourced by .zshrc

r() {
    cd ~
    clear
}

edit() {
    if [ -z "$1" ]; then
        zed "."
    else
        zed "$1"
    fi
}

# Throw away all uncommitted work, no confirmation (intentional ergonomic shortcut)
gnah() {
    git reset --hard
    git clean -df
}

gdesktop() {
    open -a 'GitHub Desktop' .
}

# git-open is provided by brew 'git-open' in Brewfile
alias gopen='git-open'
alias gop='git-open'

# List Claude Code skills
clskills() {
    local names=()
    for dir in "$HOME/.claude/skills"/*/; do
        [[ -d "$dir" ]] || continue
        names+=("$(basename "$dir")")
    done
    printf "%s\n" "${(j: - :)names}"
}
