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

# Nudge toward `cpwd` once you've leaned on bare `pwd` enough — same spirit as the
# up-arrow→ctrl-r hint in .zshrc, but a habit nudge rather than an in-the-moment one.
# Most `pwd`s are really "put this on my clipboard", but auto-copying every `pwd`
# would clobber the clipboard and tax a builtin, so we only hint.
#
# Counts EVERY bare `pwd` (any dir, regardless of what you run in between) within a
# rolling 48h window, persisted across shells. Hitting the threshold fires the hint
# AND resets the count, so it self-spaces instead of nagging on every `pwd` for two
# days. Using `cpwd` doesn't count, so the nudge goes quiet the moment you adopt it.
autoload -Uz add-zsh-hook
zmodload zsh/datetime                      # $EPOCHSECONDS — "now" with no subprocess fork
_CPWD_NUDGE_THRESHOLD=3                     # uses-within-window before we hint (tune freely)
_CPWD_NUDGE_WINDOW=$(( 48 * 3600 ))         # rolling window in seconds
_cpwd_nudge_file="$_zsh_cache_dir/pwd-nudge"  # one epoch timestamp per line
_cpwd_preexec() {
    [[ "${1// /}" == pwd ]] || return
    local now=$EPOCHSECONDS cutoff=$(( EPOCHSECONDS - _CPWD_NUDGE_WINDOW ))
    local -a stamps kept
    # $(<file) is read inline by zsh (no `cat` fork); (f) splits on newlines.
    [[ -f "$_cpwd_nudge_file" ]] && stamps=( ${(f)"$(<$_cpwd_nudge_file)"} )
    local t
    for t in $stamps; do (( t >= cutoff )) && kept+=( $t ); done   # drop stale entries
    kept+=( $now )
    if (( $#kept >= _CPWD_NUDGE_THRESHOLD )); then
        : >| "$_cpwd_nudge_file"            # fired → reset the window
        # Print the hint from preexec (just above pwd's own output), NOT from a
        # precmd hook. Ghostty's zsh shell integration emits its OSC 133 "command
        # done" (D) mark from precmd and explicitly documents that any precmd hook
        # which prints makes that mark land too late — leaving the surface looking
        # like it still has a running process (spurious "Close Terminal?" prompt).
        # preexec runs inside the command's own output window, so D stays correct.
        # No backticks: in a double-quoted print they'd run cpwd as a side effect.
        print -P "%F{8}💡 You keep reaching for pwd — 'cpwd' prints the path AND copies it to your clipboard.%f"
    else
        print -l -- $kept >| "$_cpwd_nudge_file"
    fi
}
add-zsh-hook preexec _cpwd_preexec

# Habit nudges toward the `gpl` / `gcm` aliases, same mechanism as the cpwd nudge
# above: count uses of the long form in a rolling 48h window, fire the hint once
# the threshold is hit, then reset so it self-spaces instead of nagging. Adopting
# the alias makes the nudge go quiet on its own — the alias expands to a different
# command string, so it never trips the match.
_GIT_NUDGE_THRESHOLD=3
_GIT_NUDGE_WINDOW=$(( 48 * 3600 ))
# Bump one nudge's rolling window; fire+reset its hint at the threshold. Mirrors
# _cpwd_preexec's bookkeeping (datetime/add-zsh-hook already loaded above).
_git_nudge_bump() {                            # $1=cache filename  $2=hint (print -P fmt)
    local file="$_zsh_cache_dir/$1" cutoff=$(( EPOCHSECONDS - _GIT_NUDGE_WINDOW ))
    local -a stamps kept; local t
    [[ -f "$file" ]] && stamps=( ${(f)"$(<$file)"} )
    for t in $stamps; do (( t >= cutoff )) && kept+=( $t ); done   # drop stale entries
    kept+=( $EPOCHSECONDS )
    if (( $#kept >= _GIT_NUDGE_THRESHOLD )); then
        : >| "$file"                           # fired → reset the window
        # Print from preexec, not precmd — see the Ghostty OSC 133 note above.
        print -P "$2"
    else
        print -l -- $kept >| "$file"
    fi
}
_git_alias_preexec() {
    # (z) splits like the shell would, collapsing any whitespace runs; rejoining
    # with $[w] gives a single-spaced form for exact matching, so `git pull origin
    # x` (which gpl doesn't replace) won't trip the bare-`git pull` nudge.
    local -a w=( ${(z)1} ); local cmd="${w[*]}"
    case "$cmd" in
        'git pull')
            _git_nudge_bump git-pull-nudge \
                "%F{8}💡 You keep typing 'git pull' — 'gpl' is the alias.%f" ;;
        'git checkout main'|'git checkout master'|'git switch main'|'git switch master')
            _git_nudge_bump git-checkout-main-nudge \
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
