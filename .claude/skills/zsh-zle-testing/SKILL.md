---
name: zsh-zle-testing
description: >
  Reliably verify changes to zsh interactive / line-editor behavior — ZLE widgets,
  keybindings (bindkey), zsh-autosuggestions, prompt, history — by driving a REAL
  interactive shell under a pty and inspecting live state. Use whenever editing
  .zshrc/.zshenv in ways that touch the terminal, BEFORE claiming a fix works:
  `zsh -n` only checks syntax, never runtime behavior. Trigger words: zsh, zle,
  widget, bindkey, keybinding, autosuggestions, suggestion, prompt, starship,
  .zshrc, .zshenv, history, terminal.
user-invocable: true
disable-model-invocation: false
---

# Testing zsh terminal changes

A change to a ZLE widget, keybinding, autosuggestion, or prompt only exists at
runtime inside the line editor. `zsh -n` proves the file parses; it proves nothing
about behavior. Verify in a real interactive shell, with certainty, before saying
it works.

## The one rule that matters

**Assert a deterministic FACT, not a rendered appearance.** The reliable signal is
shell state you can read at a prompt — `$widgets`, `bindkey` output, `setopt`,
`$ZSH_AUTOSUGGEST_*`, `$path`, any var. The unreliable signal is the gray suggestion
text or cursor render, which depends on async workers and redraw hooks that don't
settle predictably under a test harness. If you're tempted to scrape `$POSTDISPLAY`
or terminal bytes, find the underlying state fact instead and assert that.

```
# DON'T: "after up-arrow, is the gray suggestion gone?"  (flaky to observe)
# DO:    "is the up-arrow widget actually WRAPPED by autosuggestions?"  (deterministic)
```

## The tool: `zle-probe`

Runs a snippet inside a real interactive zsh with your `~/.zshrc` loaded and all
plugins/widgets bound (it runs at the first precmd, after zsh-autosuggestions has
wrapped its widgets). Prints the snippet's output.

```bash
scripts/zle-probe '<zsh code that prints what you want to inspect>'
```

Examples:

```bash
# Is a widget bound and wrapped by the plugin?  (wrapped => impl is _zsh_autosuggest_bound_*)
scripts/zle-probe 'print -r -- "${widgets[up-arrow-nudge]}"'

# What is a key bound to?
scripts/zle-probe 'bindkey "^[[A"'

# Is an option set? Is a path present?
scripts/zle-probe 'print -r -- "AUTO_CD=$(setopt | grep -c autocd)  PATH has herd? $path[(I)*Herd*]"'
```

Compare against a baseline by editing `~/.zshrc`, re-running, and diffing the output —
or by re-deriving the broken state in the snippet itself. Two runs that print
different facts ARE the proof.

## Gotchas (each one cost real time — trust them)

- **zsh-autosuggestions ignores any widget whose name starts with `_`.** Its bind
  loop skips `_*`, so a `_`-prefixed widget is never wrapped and can never clear or
  refresh the suggestion — no matter which `ZSH_AUTOSUGGEST_*_WIDGETS` list you add it
  to. Name custom widgets without a leading underscore (e.g. `up-arrow-nudge`, not
  `_up_arrow_nudge`). Verify with the `${widgets[name]}` probe above.
- **`ZSH_AUTOSUGGEST_CLEAR_WIDGETS` defaults are only seeded when the var is unset.**
  Append with `+=` AFTER sourcing the plugin, or you clobber the defaults.
- **An interactive shell needs a real tty.** A piped or `zsh -c` shell disables ZLE
  entirely, so widgets never bind and the test is meaningless. `zle-probe` uses
  `zpty` + `-i` to supply one.
- **Don't sync a pty harness on prompt output.** Blocking pty reads hang on an idle
  shell, and prompt bytes are unpredictable (starship). Sync on a file written from
  a precmd hook; pace polling with `zselect -t` (`sleep` is unavailable in scripts).
- **Never use `trap … EXIT` for cleanup around `zpty`.** zpty forks a copy of your
  shell that inherits the trap, so it fires when the zpty CHILD exits — mid-run —
  wiping your temp dir before you read the result. Clean up explicitly.
- **A custom `ZDOTDIR` needs `TERM` set,** or zle may not initialize under the pty.
- **`^X` is an emacs multi-key prefix.** A lone `^X` is swallowed waiting for a
  second key; useless as a one-shot test trigger. Use a free sequence like `\eg`.

## When you truly need a keystroke

Most terminal-config changes are verifiable as state facts (above) — reach for that
first. If a test genuinely requires simulating keys, drive them through the same
`zpty` session (`zpty -wn name $'\e[A'` for up-arrow, etc.), but still assert the
resulting STATE, not the render.
