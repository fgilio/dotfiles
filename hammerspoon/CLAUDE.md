# Hammerspoon Config

## Adding a module

Create `hammerspoon/<name>.lua`, self-contained (it binds its own hotkeys and watchers on load), and add `require("<name>")` at the end of `init.lua`; `bin/check` fails without it. Hammerspoon loads from `~/.hammerspoon/`, not this directory: `fresh.sh` symlinks every `hammerspoon/*.lua` there on a fresh machine, so on this one symlink the new file yourself (`ln -sf`, never a copy).

`Hyper` is `ctrl+alt+cmd+shift` everywhere (`hyper` in `init.lua`).

## Ghostty Font Scaling

Screen watcher debounces 1s because screen change events fire multiple times in rapid succession. Font size is applied via keystrokes sent to Ghostty (`Hyper+1`/`Hyper+2`), not config file edits: this lets Ghostty's own keybindings handle the actual font change.
