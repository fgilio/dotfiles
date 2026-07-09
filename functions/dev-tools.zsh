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

# Two of the most-typed git commands. `gpl` over `gl` to avoid the common
# `gl`=git-log expectation.
alias gpl='git pull'

# Checkout the repo's actual default branch. My repos are split between `main`
# and `master`, so a literal `git checkout main` breaks half the time.
# Read origin/HEAD (set by `git remote set-head`/clone) and strip to the branch
# name; fall back to main then master if origin/HEAD isn't populated locally.
gcm() {
    local def
    def=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null)
    git checkout "${def##*/}" 2>/dev/null || git checkout main 2>/dev/null || git checkout master
}

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

# Habit nudges — same spirit as the up-arrow→ctrl-r hint in .zshrc, but habit
# nudges rather than in-the-moment ones. Each nudge counts uses of a long-form
# command in a rolling 48h window, persisted across shells. Hitting the
# threshold fires the hint AND resets the count, so it self-spaces instead of
# nagging for two days. Adopting the short form makes a nudge go quiet on its
# own: the replacement never trips the match.
autoload -Uz add-zsh-hook
zmodload zsh/datetime                      # $EPOCHSECONDS — "now" with no subprocess fork
_NUDGE_THRESHOLD=3                          # uses-within-window before we hint (tune freely)
_NUDGE_WINDOW=$(( 48 * 3600 ))              # rolling window in seconds
# Bump one nudge's rolling window (one epoch timestamp per line in the cache
# file); fire+reset its hint at the threshold.
_nudge_bump() {                            # $1=cache filename  $2=hint (print -P fmt)
    local file="$_zsh_cache_dir/$1" cutoff=$(( EPOCHSECONDS - _NUDGE_WINDOW ))
    local -a stamps kept; local t
    # $(<file) is read inline by zsh (no `cat` fork); (f) splits on newlines.
    [[ -f "$file" ]] && stamps=( ${(f)"$(<$file)"} )
    for t in $stamps; do (( t >= cutoff )) && kept+=( $t ); done   # drop stale entries
    kept+=( $EPOCHSECONDS )
    if (( $#kept >= _NUDGE_THRESHOLD )); then
        : >| "$file"                       # fired → reset the window
        # Print the hint from preexec (just above the command's own output), NOT
        # from a precmd hook. Ghostty's zsh shell integration emits its OSC 133
        # "command done" (D) mark from precmd and explicitly documents that any
        # precmd hook which prints makes that mark land too late — leaving the
        # surface looking like it still has a running process (spurious "Close
        # Terminal?" prompt). preexec runs inside the command's own output window,
        # so D stays correct.
        print -P "$2"
    else
        print -l -- $kept >| "$file"
    fi
}

# Most `pwd`s are really "put this on my clipboard", but auto-copying every `pwd`
# would clobber the clipboard and tax a builtin, so we only hint. Counts EVERY
# bare `pwd` (any dir, regardless of what you run in between); using `cpwd`
# doesn't count. No backticks in the hint: in a double-quoted print they'd run
# cpwd as a side effect.
_cpwd_preexec() {
    [[ "${1// /}" == pwd ]] || return
    _nudge_bump pwd-nudge \
        "%F{8}💡 You keep reaching for pwd — 'cpwd' prints the path AND copies it to your clipboard.%f"
}
add-zsh-hook preexec _cpwd_preexec

# Nudges toward the `gpl` / `gcm` aliases.
_git_alias_preexec() {
    # (z) splits like the shell would, collapsing any whitespace runs; rejoining
    # with $[w] gives a single-spaced form for exact matching, so `git pull origin
    # x` (which gpl doesn't replace) won't trip the bare-`git pull` nudge.
    local -a w=( ${(z)1} ); local cmd="${w[*]}"
    case "$cmd" in
        'git pull')
            _nudge_bump git-pull-nudge \
                "%F{8}💡 You keep typing 'git pull' — 'gpl' is the alias.%f" ;;
        'git checkout main'|'git checkout master'|'git switch main'|'git switch master')
            _nudge_bump git-checkout-main-nudge \
                "%F{8}💡 You keep checking out the default branch — 'gcm' does it (and picks main vs master for you).%f" ;;
    esac
}
add-zsh-hook preexec _git_alias_preexec

# List Claude Code skills
clskills() {
    local names=()
    for dir in "$HOME/.claude/skills"/*/; do
        [[ -d "$dir" ]] || continue
        names+=("$(basename "$dir")")
    done
    printf "%s\n" "${(j: - :)names}"
}
