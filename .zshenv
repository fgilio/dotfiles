#!/bin/zsh
# .zshenv - Loaded for ALL zsh sessions (interactive and non-interactive)
# Keep this minimal for performance

# Add dotfiles bin to PATH for custom commands
# Use typeset -U to prevent duplicate PATH entries
typeset -U path PATH
path=("$HOME/.dotfiles/bin" $path)