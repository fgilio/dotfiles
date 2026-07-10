# Hammerspoon Config

## Adding a Module

1. Create the `.lua` file in this directory
2. Add `require("name")` to the end of `init.lua`

Hammerspoon resolves `require()` from `~/.hammerspoon/`, not the dotfiles source dir. `fresh.sh` symlinks every `hammerspoon/*.lua` automatically (per-file, not whole-dir, so Hammerspoon's own writes like `Spoons/` never land in the repo); `bin/check` enforces the `require()` step.

## Module Pattern

Modules are loaded via `require("name")` at the bottom of `init.lua`. Each module is self-contained: it sets up its own hotkeys/watchers on load.

## Hotkey Conventions

| Convention | Detail |
|---|---|
| `Hyper` | `ctrl+alt+cmd+shift` everywhere |
| Pass-through | Disable hotkey, send keystroke, re-enable via `hs.timer.doAfter(0, ...)` |
| Per-app behavior | Check `hs.application.frontmostApplication():name()` inside a global hotkey |

## Ghostty Font Scaling

Screen watcher debounces 1s because screen change events fire multiple times in rapid succession. Font size is applied via keystrokes sent to Ghostty (`Hyper+1`/`Hyper+2`), not config file edits: this lets Ghostty's own keybindings handle the actual font change.
