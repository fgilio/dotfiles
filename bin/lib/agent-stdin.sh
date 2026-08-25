#!/usr/bin/env zsh
# Sourced by bin/cx, bin/cl and bin/cr — never executed (tracked 644 on purpose).
#
# These CLIs append piped stdin to the prompt when stdin is not a TTY. `codex
# exec --help` says it outright: "instructions are read from stdin. If stdin is
# piped and a prompt is also provided, stdin is appended as a `<stdin>` block".
# A caller that hands the wrapper a descriptor nobody ever closes — an agent
# harness, a CI step, `ssh -T` — therefore leaves the CLI waiting on an EOF that
# never arrives.

# Will stdin never deliver anything? Real piped input is readable almost at
# once, an idle descriptor never becomes readable at all.
agent_stdin_is_idle() {
    [[ ${AGENT_CLI_STDIN:-} == inherit ]] && return 1

    # A TTY is never appended, so there is nothing to guard against.
    [[ -t 0 ]] && return 1

    zmodload -F zsh/zselect b:zselect

    # Milliseconds, capped in the pattern so an unusable value can't reach
    # zselect: it returns 1 for a bad argument exactly as it does for a
    # timeout, which would read as idle and drop the input.
    local grace=${AGENT_CLI_STDIN_GRACE:-}
    [[ $grace == <0-60000> ]] || grace=2000

    # EOF counts as readable, so `</dev/null` and an already-closed pipe both
    # fall through to "not idle" and cost nothing. The local `reply` keeps
    # zselect's result array out of the caller's scope.
    local -a reply
    zselect -t $((grace / 10)) -r 0 2>/dev/null && return 1

    return 0
}
