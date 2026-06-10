#!/bin/bash
# Editor configs: symlink settings + keybindings from dotfiles.
# VSCode, Cursor, and Zed are all tracked. Cursor is a VSCode fork but keeps its
# own (diverged) config, so it gets an independent dotfiles/cursor dir.

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# --- VSCode ---
VSCODE_USER="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSCODE_USER"
ln -sf "$DOTFILES/vscode/settings.json" "$VSCODE_USER/settings.json"
ln -sf "$DOTFILES/vscode/keybindings.json" "$VSCODE_USER/keybindings.json"

# --- Cursor (independent config) ---
CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
mkdir -p "$CURSOR_USER"
ln -sf "$DOTFILES/cursor/settings.json" "$CURSOR_USER/settings.json"
ln -sf "$DOTFILES/cursor/keybindings.json" "$CURSOR_USER/keybindings.json"

# --- Zed (settings + keymap) ---
ZED_USER="$HOME/.config/zed"
mkdir -p "$ZED_USER"
ln -sf "$DOTFILES/zed/settings.json" "$ZED_USER/settings.json"
ln -sf "$DOTFILES/zed/keymap.json" "$ZED_USER/keymap.json"

# Install extensions into available editors (VSCode + Cursor share the list)
if [[ -f "$DOTFILES/vscode/extensions.txt" ]]; then
  # One CLI invocation per editor: each code/cursor call boots Electron, so
  # per-extension invocations (37 ext x 2 editors) cost minutes instead of seconds
  ext_args=()
  while IFS= read -r ext; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue
    ext_args+=(--install-extension "$ext")
  done <"$DOTFILES/vscode/extensions.txt"
  if [[ ${#ext_args[@]} -gt 0 ]]; then
    # || true only to survive fresh.sh's errexit when an editor is missing
    # or one extension id is bad. Errors stay visible on stderr
    command -v code &>/dev/null && code "${ext_args[@]}" --force || true
    command -v cursor &>/dev/null && cursor "${ext_args[@]}" --force || true
  fi
fi
