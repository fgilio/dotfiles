################################################################################
# ZSH Configuration File
# Organized into sections for better maintainability
################################################################################

#####################
# History Configuration
#####################
HISTSIZE=5000               # Maximum events for internal history
HISTFILE=~/.zsh_history     # History file location
SAVEHIST=5000              # Maximum events in history file
setopt appendhistory       # Append history to the history file (no overwriting)
setopt incappendhistory    # Add commands to the history immediately
setopt sharehistory        # Share history across ZSH sessions
setopt hist_find_no_dups   # Don't display duplicate commands during search
setopt hist_ignore_all_dups # Remove older duplicate entries from history
setopt hist_save_no_dups   # Don't save duplicate entries to history file

# History search bindings
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

# Substring history search with arrow keys
bindkey '^[[A' history-beginning-search-backward-end  # Up arrow for backward history search
bindkey '^[[B' history-beginning-search-forward-end   # Down arrow for forward history search

#####################
# Completion System
#####################
# Ensure completion cache directory exists
[[ -d ~/.zsh/cache ]] || mkdir -p ~/.zsh/cache

# Required for glob qualifiers in compinit cache check
setopt extended_glob

autoload -Uz compinit
# Only regenerate completion dump once per day (check if older than 24h)
if [[ -n ~/.zsh/cache/zcompdump(#qN.mh+24) ]]; then
  compinit -d ~/.zsh/cache/zcompdump
else
  compinit -C -d ~/.zsh/cache/zcompdump  # -C skips security check for speed
fi

# Basic completion behavior
zstyle ':completion:*' menu select      # Enable menu-style completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'  # Case-insensitive + substring matching

# Colored completions
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

# Grouped completions (separate files/directories/commands)
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order builtins commands functions
zstyle ':completion:*' list-dirs-first true

# Recent directories first (using zoxide's frecency when available)
zstyle ':completion:*:cd:*' tag-order 'local-directories directory-stack path-directories'
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select

# Auto-select single match (but still show it)
zstyle ':completion:*' menu select=1

# Performance: Use cache for expensive completions
zstyle ':completion::complete:*' use-cache true
zstyle ':completion::complete:*' cache-path ~/.zsh/cache

#####################
# Path Configuration
#####################
# Function to add path only if not already present
# Path additions using zsh path array (deduplication handled by typeset -U in .zshenv)
# MySQL client
[[ -d "/opt/homebrew/opt/mysql-client@8.4/bin" ]] && path+=("/opt/homebrew/opt/mysql-client@8.4/bin")

# Docker path (OrbStack)
[[ -d "$HOME/.orbstack/bin" ]] && path+=("$HOME/.orbstack/bin")

# Composer global packages
[[ -d "$HOME/.composer/vendor/bin" ]] && path+=("$HOME/.composer/vendor/bin")


#####################
# Bun Configuration
#####################
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"  # Bun completions
# PATH for dotfiles/bin is already set in .zshenv
[[ -d "$HOME/.bun/bin" ]] && path+=("$HOME/.bun/bin")

#####################
# Aliases
#####################
# Basic shortcuts
alias h="history"          # Show command history
alias c="clear"            # Clear terminal
alias f="open ./"          # Open current directory in Finder
alias ..="cd .."           # Change to parent directory
alias ...="cd ../.."       # Change to parent directory twice

# File operations
# Enable colors for common commands
export CLICOLOR=1                   # Enable colors in ls and other commands
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd  # Customize ls colors

alias ls="ls -G"                    # Colorized ls output
alias ll="gls -alth --color=auto"   # GNU coreutils ls (gls) for --color support
# rm wrapper in ~/bin handles safety (moved to ~/.dotfiles/bin/rm)
alias cp="cp -iv"                   # Interactive and verbose copy
alias mv="mv -iv"                   # Interactive and verbose move
alias mkdir="mkdir -pv"             # Create parent dirs as needed, verbose

# Disk and memory utilities
alias df="df -h"                    # Show disk free space in human-readable format (e.g., 1.5G instead of 1500000)
alias du="du -h"                    # Show directory space usage in human-readable format (useful for finding large files/folders)
alias top="btop"                    # Intentionally replaces top with btop (not shadowing)

# Networking
alias ipinfo="curl ipinfo.io"      # Get IP information
alias myip="ipinfo"                # Alternative for IP info
alias ping="prettyping --nolegend" # Installed via Brewfile
alias flushDNS="dscacheutil -flushcache"  # Flush DNS cache
alias edit-hosts='SUDO_EDITOR="$EDITOR" sudo -e /etc/hosts'  # Edit hosts file

# Configuration editing
alias edit-zsh-config='$EDITOR "$HOME/.zshrc"'  # Edit ZSH config (uses Zed)
alias zsh-edit-config='edit-zsh-config'         # Alternative for editing ZSH config

# Show/Hide dotfiles in Finder
alias dfiles-s='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias dfiles-h='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# Development servers
alias php-srv="open http://localhost:4444 && php -S localhost:4444"

# Clipboard operations
alias copy-ssh="cat ~/.ssh/id_ed25519.pub | pbcopy"  # Updated to use Ed25519 key
alias ocr='screencapture -i ~/tmp/screenshot.png && tesseract ~/tmp/screenshot.png stdout | pbcopy && /bin/rm -f ~/tmp/screenshot.png'

#####################
# Custom Functions
#####################
# Development functions are loaded from the dotfiles directory
# This includes: r, edit, gnah, gdesktop, git-open (trash is now in bin/)
source "$DOTFILES/functions/dev-tools.zsh"


#####################
# Shell Integrations
#####################
# Starship configuration
export STARSHIP_COMMAND_TIMEOUT=1000            # 1 second timeout (default 500ms is too aggressive)
# Initialize Starship prompt
eval "$(starship init zsh)"

# Enable ZSH autosuggestions
# Hardcoded path intentional - $(brew --prefix) adds ~30-50ms subprocess overhead
# Guard with file check to prevent startup errors if package missing
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Initialize Zoxide (smart cd command)
eval "$(zoxide init zsh)"

#####################
# Fzf / fd integration
#####################
# Use fd as the default source for fzf (fast, honors .gitignore)
if command -v fd >/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Load fzf key bindings and completion (ctrl-r / ctrl-t / alt-c)
[[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && \
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
[[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]] && \
  source /opt/homebrew/opt/fzf/shell/completion.zsh

# Zoo Shell Integration (currently commented out)
# if [[ -f ~/pla/zoo/zoo_shell_integration.zsh ]]; then
#     source ~/pla/zoo/zoo_shell_integration.zsh
# fi

# Added by LM Studio CLI (lms)
[[ -d "$HOME/.cache/lm-studio/bin" ]] && path+=("$HOME/.cache/lm-studio/bin")

# Source environment variables only on login shells (avoid re-reading in subshells)
if [[ -o login ]] && [[ -f "$HOME/.env" ]]; then
  source "$HOME/.env"
fi

# Zoo formatting and linting commands
alias zsetup-hooks="$HOME/pla/zoo/bin/zsetup-hooks"
[[ -d "$HOME/pla/zoo/bin" ]] && path+=("$HOME/pla/zoo/bin")
[[ -d "$HOME/.local/bin" ]] && path+=("$HOME/.local/bin")

################################################################################
# Herd Configuration (Keep at bottom for auto-injected configs)
# NOTE: Herd auto-injects some lines with hardcoded paths - don't modify those
################################################################################
# PHP binary and configuration directories
[[ -d "$HOME/Library/Application Support/Herd/bin" ]] && path+=("$HOME/Library/Application Support/Herd/bin")

# NVM configuration (lazy-loaded for ~200ms faster shell startup)
# Note: No fallback for missing NVM - this is a personal setup with Herd always installed.
# If NVM is missing, node/npm commands will fail, which is the desired behavior.
export NVM_DIR="$HOME/Library/Application Support/Herd/config/nvm"

# Lazy-load NVM - only initialize on first use of node/npm/npx/nvm
_nvm_lazy_load() {
  unset -f node npm npx nvm nvm_find_nvmrc 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}
# Stub nvm_find_nvmrc to prevent Herd from triggering full NVM load on startup
# After first node/npm/nvm call, real nvm_find_nvmrc becomes available
nvm_find_nvmrc() { echo ""; }
for cmd in node npm npx nvm; do
  eval "$cmd() { _nvm_lazy_load && $cmd \"\$@\" }"
done

# Shell integration (must come after NVM is loaded)
[[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] && builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"

# Herd injected PHP 8.3 configuration.
export HERD_PHP_83_INI_SCAN_DIR="/Users/fgilio/Library/Application Support/Herd/config/php/83/"

# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/fgilio/Library/Application Support/Herd/config/php/84/"

# Antigravity CLI (originally added by installer, refactored for consistency)
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && path=("$HOME/.antigravity/antigravity/bin" $path)
