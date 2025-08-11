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
setopt hist_ignore_dups    # Ignore duplicate commands
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
autoload -Uz compinit && compinit    # Initialize completion system

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
zstyle ':completion:*' menu select=1 _complete _ignored _approximate

# Performance: Use cache for expensive completions
zstyle ':completion::complete:*' use-cache true
zstyle ':completion::complete:*' cache-path ~/.zsh/cache

#####################
# Path Configuration
#####################
# Function to add path only if not already present
add_to_path() {
    if [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="$1:$PATH"
    fi
}

# MySQL client
add_to_path "/opt/homebrew/opt/mysql-client@8.4/bin"

# Docker path (OrbStack)
add_to_path "/Users/fgilio/.orbstack/bin"

# Composer global packages
add_to_path "/Users/fgilio/.composer/vendor/bin"


#####################
# Bun Configuration
#####################
[ -s "/Users/fgilio/.bun/_bun" ] && source "/Users/fgilio/.bun/_bun"  # Bun completions
export PATH="/Users/fgilio/.bun/bin:$PATH"

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
alias ll="ls -alth --color=auto"    # Detailed directory listing with colors
alias rm="rm -i"                    # Interactive removal
alias cp="cp -iv"                   # Interactive and verbose copy
alias mv="mv -iv"                   # Interactive and verbose move
alias mkdir="mkdir -pv"             # Create parent dirs as needed, verbose

# Disk and memory utilities
alias df="df -h"                    # Show disk free space in human-readable format (e.g., 1.5G instead of 1500000)
alias du="du -h"                    # Show directory space usage in human-readable format (useful for finding large files/folders)
alias top="btop"                    # Better top command with CPU, memory, network and disk monitoring

# Networking
alias ipinfo="curl ipinfo.io"      # Get IP information
alias myip="ipinfo"                # Alternative for IP info
alias ping="prettyping --nolegend" # Better ping visualization
alias flushDNS="dscacheutil -flushcache"  # Flush DNS cache
alias edit-hosts="subl /etc/hosts"        # Edit hosts file

# Configuration editing
alias edit-zsh-config="subl '/Users/fgilio/.zshrc'"  # Edit ZSH config
alias zsh-edit-config="edit-zsh-config"              # Alternative for editing ZSH config

# Zoo-related aliases
alias zoo='/Users/fgilio/pla/zoo/zoo.sh'
alias zex='/Users/fgilio/pla/zoo/zex.sh'
alias zin='/Users/fgilio/pla/zoo/zin.sh'
alias zar='/Users/fgilio/pla/zoo/zar.sh'
alias zet='/Users/fgilio/pla/zoo/zet.sh'

# Show/Hide dotfiles in Finder
alias dfiles-s="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app"
alias dfiles-h="defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app"

# Development servers
alias php-srv="open http://localhost:4444 && php -S localhost:4444"

# Clipboard operations
alias copy-ssh="cat ~/.ssh/id_ed25519.pub | pbcopy"  # Updated to use Ed25519 key
alias ocr='screencapture -i ~/tmp/screenshot.png && tesseract ~/tmp/screenshot.png stdout | pbcopy && rm -f ~/tmp/screenshot.png'

# Trash command - move files to macOS trash instead of rm
trash() { command mv "$@" ~/.Trash ; }

#####################
# Custom Functions
#####################
# Change to Home and Clear screen
r() {
    cd ~
    clear
}

# Open in Sublime Text
edit() {
    if [ -z "$1" ]; then
        subl "."
    else
        subl "$1"
    fi
}

# Git Reset and Clean
gnah() {
    git reset --hard
    git clean -df
}

# Open GitHub Desktop
gdesktop() {
    open -a 'GitHub Desktop' .
}

# Opens the git repository URL in your default browser
function git-open() {
    # Get the remote URL, defaulting to 'origin' if no remote is specified
    local remote="${1:-origin}"
    
    # Extract the URL from git config and remove .git suffix
    local url=$(git config --get remote.$remote.url | sed 's/\.git$//')
    
    # Convert SSH URLs to HTTPS format
    url=$(echo $url | sed 's/git@\([^:]*\):/https:\/\/\1\//')
    
    # Open the URL using the system's default browser
    if [[ $(uname) == "Darwin" ]]; then
        open $url
    elif [[ $(uname) == "Linux" ]]; then
        xdg-open $url
    else
        echo "Unsupported operating system"
        return 1
    fi
}

# Create the alias for easier usage
alias gopen='git-open'
alias gop='git-open'

alias tm='task-master'

#####################
# Shell Integrations
#####################
# Starship configuration
export STARSHIP_COMMAND_TIMEOUT=3000            # Increase timeout to 3 seconds (default is 500ms)
# Initialize Starship prompt
eval "$(starship init zsh)"

# Enable ZSH autosuggestions (hardcoded path for performance)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Initialize Zoxide (smart cd command)
eval "$(zoxide init zsh)"

# Zoo Shell Integration (currently commented out)
# if [[ -f ~/pla/zoo/zoo_shell_integration.zsh ]]; then
#     source ~/pla/zoo/zoo_shell_integration.zsh
# fi

# Added by LM Studio CLI (lms)
add_to_path "/Users/fgilio/.cache/lm-studio/bin"

# Source environment variables (API keys, etc.)
[ -f ~/.env ] && source ~/.env

# Zoo formatting and linting commands
alias zsetup-hooks='/Users/fgilio/pla/zoo/bin/zsetup-hooks'
add_to_path "/Users/fgilio/pla/zoo/bin"
add_to_path "/Users/fgilio/.local/bin"

################################################################################
# Herd Configuration (Keep at bottom for auto-injected configs)
################################################################################
# PHP binary and configuration directories
add_to_path "/Users/fgilio/Library/Application Support/Herd/bin/"

# NVM configuration
export NVM_DIR="/Users/fgilio/Library/Application Support/Herd/config/nvm"

# Load NVM fully (Node will always be available)
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Shell integration (must come after NVM is loaded)
[[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] && builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"

# Herd injected PHP 8.3 configuration.
export HERD_PHP_83_INI_SCAN_DIR="/Users/fgilio/Library/Application Support/Herd/config/php/83/"

# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/fgilio/Library/Application Support/Herd/config/php/84/"
