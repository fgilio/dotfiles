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