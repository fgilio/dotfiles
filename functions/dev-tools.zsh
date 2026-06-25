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

# Launch yazi and cd to wherever you quit it (the official wrapper). Plain `yazi`
# can't change the parent shell's dir; this reads its --cwd-file on exit.
# `command rm/cat` bypass the Trash-wrapping rm alias and the bat `cat` alias.
y() {
    local tmp cwd
    tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd"
    fi
    command rm -f -- "$tmp"
}

# Copy the current dir to the clipboard (the 99% reason you type `pwd`).
# Deliberately NOT an override of `pwd`: copying on every `pwd` would spawn
# pbcopy on a builtin (perf tax) and silently clobber the clipboard on glances.
# `printf %s` avoids a trailing newline so the pasted path won't auto-execute.
# `$PWD` is a free var read; `$(pwd)` would fork a subshell.
cpwd() {
    printf %s "$PWD" | pbcopy
    print -r -- "$PWD"
    print -P "%F{8}↑ copied to clipboard%f"
}

# List Claude Code skills
clskills() {
    local names=()
    for dir in "$HOME/.claude/skills"/*/; do
        [[ -d "$dir" ]] || continue
        names+=("$(basename "$dir")")
    done
    printf "%s\n" "${(j: - :)names}"
}
