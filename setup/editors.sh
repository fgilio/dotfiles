#!/bin/bash
# VSCode config: symlinks settings and keybindings from dotfiles
# Cursor keeps its own independent config (not symlinked)

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

VSCODE_USER="$HOME/Library/Application Support/Code/User"

mkdir -p "$VSCODE_USER"

ln -sf "$DOTFILES/vscode/settings.json" "$VSCODE_USER/settings.json"
ln -sf "$DOTFILES/vscode/keybindings.json" "$VSCODE_USER/keybindings.json"

# Install extensions into available editors
if [[ -f "$DOTFILES/vscode/extensions.txt" ]]; then
    while IFS= read -r ext; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        command -v code &>/dev/null && code --install-extension "$ext" --force 2>/dev/null || true
        command -v cursor &>/dev/null && cursor --install-extension "$ext" --force 2>/dev/null || true
    done < "$DOTFILES/vscode/extensions.txt"
fi
