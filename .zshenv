#!/bin/zsh
# .zshenv - Loaded for ALL zsh sessions (interactive and non-interactive)
# Keep this minimal for performance

# Set up PATH with automatic deduplication
typeset -gU path PATH
export PATH  # Ensure PATH is exported

# Add dotfiles bin to PATH for custom commands
path=("$HOME/.dotfiles/bin" $path)