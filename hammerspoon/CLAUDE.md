# Hammerspoon Config

## Adding a module

Create `hammerspoon/<name>.lua`, self-contained (it binds its own hotkeys and watchers on load), and add `require("<name>")` at the end of `init.lua`; `bin/check` fails without it. Hammerspoon loads from `~/.hammerspoon/`, not this directory: `fresh.sh` symlinks every `hammerspoon/*.lua` there on a fresh machine, so on this one symlink the new file yourself (`ln -sf`, never a copy).

## Hotkey Conventions

| Convention | Detail |
|---|---|
| `Hyper` | `ctrl+alt+cmd+shift` everywhere |
| Pass-through | Disable hotkey, send keystroke, re-enable via `hs.timer.doAfter(0, ...)` |
| Per-app behavior | Check `hs.application.frontmostApplication():name()` inside a global hotkey |

## Ghostty Font Scaling

Screen watcher debounces 1s because screen change events fire multiple times in rapid succession. Font size is applied via keystrokes sent to Ghostty (`Hyper+1`/`Hyper+2`), not config file edits: this lets Ghostty's own keybindings handle the actual font change.
