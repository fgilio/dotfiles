#!/bin/zsh
# .zshenv - Loaded for ALL zsh sessions (interactive and non-interactive)
# Keep this minimal for performance

# Global dotfiles directory reference
export DOTFILES="$HOME/.dotfiles"


# Set up PATH with automatic deduplication
typeset -gU path PATH
export PATH  # Ensure PATH is exported

# Add dotfiles bin to PATH for custom commands
path=("$DOTFILES/bin" $path)

# Default editor
export EDITOR="zed --wait"
export VISUAL="$EDITOR"

# Herd - PHP binary and configuration
[[ -d "$HOME/Library/Application Support/Herd/bin" ]] && path+=("$HOME/Library/Application Support/Herd/bin")
export HERD_PHP_83_INI_SCAN_DIR="/Users/fgilio/Library/Application Support/Herd/config/php/83/"
export HERD_PHP_84_INI_SCAN_DIR="/Users/fgilio/Library/Application Support/Herd/config/php/84/"

# NVM configuration (lazy-loaded for ~200ms faster shell startup)
export NVM_DIR="$HOME/Library/Application Support/Herd/config/nvm"
# Lazy-load NVM on first use of node/npm/npx/nvm.
# May return non-zero if nvm.sh is missing - callers use ; not && to handle this.
_nvm_lazy_load() {
  unset -f node npm npx nvm nvm_find_nvmrc 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}
nvm_find_nvmrc() { echo ""; }
# Use ; instead of && so the command runs even if NVM is unavailable,
# falling back to any system-installed binary
for cmd in node npm npx nvm; do
  eval "$cmd() { _nvm_lazy_load; $cmd \"\$@\" }"
done

# Antigravity CLI
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && path=("$HOME/.antigravity/antigravity/bin" $path)
