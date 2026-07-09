################################################################################
# ZSH Configuration File
# Organized into sections for better maintainability
################################################################################

#####################
# History Configuration
#####################
HISTSIZE=50000              # Maximum events for internal history
HISTFILE=~/.zsh_history     # History file location
SAVEHIST=50000             # Maximum events in history file (dedup opts keep file small)
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
bindkey '^[[B' history-beginning-search-forward-end   # Down arrow for forward history search

# Up arrow does backward history search, but after a run of consecutive presses
# it flashes a hint to use ctrl-r instead. $LASTWIDGET tracks consecutiveness:
# any other key resets the count, so a few normal taps stay silent. zle -M shows
# the message below the prompt and the next keystroke clears it (non-destructive).
#
# Widget name has NO leading underscore ON PURPOSE. zsh-autosuggestions' bind loop
# skips every widget matching `_*` (its ignore list, see zsh-autosuggestions.zsh),
# so a `_`-prefixed widget is never wrapped — meaning it can't clear/refresh the
# suggestion. A `_up_arrow_nudge` left the gray suggestion stranded on the recalled
# line (e.g. `php84 artisan native:run` + a stale `4 artisan native:run …` tail).
# Naming it `up-arrow-nudge` lets the plugin wrap it; see ZSH_AUTOSUGGEST_CLEAR_WIDGETS below.
up-arrow-nudge() {
  if [[ "$LASTWIDGET" == up-arrow-nudge ]]; then
    (( _up_arrow_count++ ))
  else
    _up_arrow_count=1
  fi
  # Inline history-search-end's body instead of `zle history-beginning-search-backward-end`.
  # A nested `zle <widget>` call does NOT update $WIDGET, so history-search-end would read
  # $WIDGET=up-arrow-nudge, compute `.${WIDGET%-end}` = `.up-arrow-nudge`, and error with
  # "No such widget" on every press. Driving the builtin directly sidesteps that; the
  # MARK/CURSOR dance (keyed to our own widget via $LASTWIDGET) preserves incremental
  # same-prefix search across consecutive ↑ presses, exactly like the -end widget would.
  integer cursor=$CURSOR mark=$MARK
  # Continue the same search session (reuse the stored prefix via $MARK) when the
  # previous widget was us OR the down-arrow search-forward widget — matching stock
  # history-search-end's own `$LASTWIDGET = history-beginning-search-*-end` check, so
  # reversing Down→Up keeps the original prefix instead of restarting from the line end.
  if [[ $LASTWIDGET == up-arrow-nudge || $LASTWIDGET == history-beginning-search-*-end ]]; then
    CURSOR=$MARK
  else
    MARK=$CURSOR
  fi
  if zle .history-beginning-search-backward; then
    zle .end-of-line
  else
    CURSOR=$cursor
    MARK=$mark
  fi
  (( _up_arrow_count >= 6 )) && \
    zle -M "💡 Spamming ↑? Press ctrl-r to fuzzy-search your history instead."
}
zle -N up-arrow-nudge
bindkey '^[[A' up-arrow-nudge                         # Up arrow (with ctrl-r nudge)

#####################
# Directory Navigation
#####################
setopt auto_cd            # Type a directory name alone to cd into it
setopt auto_pushd         # cd pushes onto the dir stack, so `cd -<TAB>` lists visited dirs
setopt pushd_ignore_dups  # Don't pile duplicate dirs onto the stack
setopt pushd_silent       # Don't print the stack on every pushd/popd

#####################
# Completion System
#####################
# Ensure completion cache directory exists
_zsh_cache_dir="$HOME/.zsh/cache"
[[ -d "$_zsh_cache_dir" ]] || mkdir -p "$_zsh_cache_dir"

# Required for glob qualifiers in compinit cache check
setopt extended_glob

# Homebrew completions must be available before compinit builds or reads its cache.
[[ -d /opt/homebrew/share/zsh/site-functions ]] && fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

autoload -Uz compinit
# Only regenerate completion dump once per day (check if older than 24h)
if [[ -n "$_zsh_cache_dir/zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$_zsh_cache_dir/zcompdump"
  # compinit only rewrites the dump when it's stale, so a still-valid dump keeps
  # its old mtime — without the touch, every shell after the first 24h would take
  # this slow path (compaudit re-scans fpath, ~6ms+) instead of once per day.
  touch "$_zsh_cache_dir/zcompdump"
else
  compinit -C -d "$_zsh_cache_dir/zcompdump"  # -C skips security check for speed
fi

if [[ -s "$_zsh_cache_dir/zcompdump" && ( ! -s "$_zsh_cache_dir/zcompdump.zwc" || "$_zsh_cache_dir/zcompdump" -nt "$_zsh_cache_dir/zcompdump.zwc" ) ]]; then
  zcompile "$_zsh_cache_dir/zcompdump"
fi

# Basic completion behavior
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

# cd completion order: local directories before the directory stack and cdpath dirs
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
# Path additions use the zsh path array (deduplication handled by typeset -U in .zshenv)
# MySQL client
[[ -d "/opt/homebrew/opt/mysql-client@8.4/bin" ]] && path+=("/opt/homebrew/opt/mysql-client@8.4/bin")

# Docker path (OrbStack)
[[ -d "$HOME/.orbstack/bin" ]] && path+=("$HOME/.orbstack/bin")

# Composer global packages
[[ -d "$HOME/.composer/vendor/bin" ]] && path+=("$HOME/.composer/vendor/bin")


#####################
# Bun Configuration
#####################
# Bun completions, zcompiled once: parsing the 1000-line source costs ~1.8ms per shell
if [[ -s "$HOME/.bun/_bun" ]]; then
  [[ ! -s "$HOME/.bun/_bun.zwc" || "$HOME/.bun/_bun" -nt "$HOME/.bun/_bun.zwc" ]] && zcompile "$HOME/.bun/_bun"
  source "$HOME/.bun/_bun"
fi
[[ -d "$HOME/.bun/bin" ]] && path+=("$HOME/.bun/bin")

#####################
# Aliases
#####################
# Basic shortcuts
alias h="history"
alias c="clear"
alias f="open ./"   # Open current directory in Finder
alias ..="cd .."
alias ...="cd ../.."

# File operations
# Enable colors for common commands
export CLICOLOR=1                   # Enable colors in ls and other commands
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd  # Customize ls colors
# Colorized, syntax-highlighted man pages via bat (col strips backspace overstrike)
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"              # Avoid bat rendering garbled groff escapes

alias ls="ls -G"                    # Colorized ls output
alias ll="gls -alth --color=auto"   # GNU coreutils ls (gls) for --color support
# bat as cat: --style=plain keeps it cat-like (no line numbers/borders) but adds
# syntax color; bat auto-passes through raw bytes when piped, so | pbcopy etc. are
# unaffected. Use `command cat` for true raw output.
alias cat="bat --paging=never --style=plain"
# No rm alias needed: dotfiles/bin/rm intercepts and moves to Trash instead of deleting
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

# Claude Code
alias today='claude --resume "today" --model sonnet'  # Resume today's Claude Code session
alias blog='cd ~/dev/fgilio.com && claude'  # Claude Code session for the blog

# Configuration editing
alias edit-zsh-config='$EDITOR "$HOME/.zshrc"'  # Edit ZSH config (uses Zed)
alias zsh-edit-config='edit-zsh-config'         # Alternative for editing ZSH config

# Show/Hide dotfiles in Finder
alias dfiles-s='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'
alias dfiles-h='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'

# Development servers
alias php-srv="open http://localhost:4444 && php -S localhost:4444"

# Clipboard operations
alias copy-ssh="cat ~/.ssh/id_ed25519.pub | pbcopy"
# /bin/rm on purpose: the screenshot is throwaway, keep it out of the Trash wrapper
alias ocr='screencapture -i ~/tmp/screenshot.png && tesseract ~/tmp/screenshot.png stdout | pbcopy && /bin/rm -f ~/tmp/screenshot.png'

#####################
# Custom Functions
#####################
# Cache `<command> init zsh` output to a file and source it, skipping the init
# fork on every startup. Regenerates when the binary is newer than the cache
# (i.e. after upgrades). On generation failure the old cache stays in place and
# stderr lands in <cache>.log for debugging.
_source_generated_init() {
  local command_name="$1"
  local cache_file="$2"
  local command_path

  shift 2

  (( $+commands[$command_name] )) || return 0
  command_path="${commands[$command_name]}"

  if [[ ! -s "$cache_file" || "$command_path" -nt "$cache_file" ]]; then
    local cache_tmp="${cache_file}.$$"
    local log_tmp="${cache_file}.log.$$"

    if "$command_name" "$@" >| "$cache_tmp" 2>| "$log_tmp"; then
      command mv -f "$cache_tmp" "$cache_file"
      command rm -f "$log_tmp" "$cache_file.log"
    else
      command rm -f "$cache_tmp"
      if [[ -s "$log_tmp" ]]; then
        command mv -f "$log_tmp" "$cache_file.log"
      else
        command rm -f "$log_tmp"
      fi
    fi
  fi

  [[ -s "$cache_file" ]] && source "$cache_file"
}

# Custom functions and aliases: r, edit, gnah, gdesktop, gopen/gop, clskills
source "$DOTFILES/functions/dev-tools.zsh"


#####################
# Shell Integrations
#####################
# Starship configuration
export STARSHIP_COMMAND_TIMEOUT=1000            # 1 second timeout (default 500ms is too aggressive)
# Initialize Starship prompt
_source_generated_init starship "$_zsh_cache_dir/starship-init.zsh" init zsh
# Bake the continuation prompt into the cache: the generated init forks
# `starship prompt --continuation` synchronously on every shell (~7-20ms, the
# top startup cost) for output that only changes with starship.toml. Sourcing
# above already paid that fork and set PROMPT2, so write the literal back into
# the cache; every later shell skips the fork. The content check below is a
# pure-zsh file read (no fork) and only matches right after a regeneration.
# After changing continuation_prompt in starship.toml: rm the cache file.
_starship_cache="$_zsh_cache_dir/starship-init.zsh"
if (( $+commands[starship] )) && [[ -s "$_starship_cache" && "$(<"$_starship_cache")" == *"starship prompt --continuation"* ]]; then
  _baked=()
  while IFS= read -r _line; do
    [[ "$_line" == PROMPT2=* ]] && _line="PROMPT2=${(qq)PROMPT2}"
    _baked+=("$_line")
  done < "$_starship_cache"
  print -rl -- "${_baked[@]}" >| "$_starship_cache"
  unset _baked _line
fi
unset _starship_cache

# Initialize Zoxide (smart cd command)
_source_generated_init zoxide "$_zsh_cache_dir/zoxide-init.zsh" init zsh

#####################
# Fzf / fd integration
#####################
# Use fd as the default source for fzf (fast, honors .gitignore)
if command -v fd >/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Global layout, plus preview windows for the two file/dir pickers:
# ctrl-t previews file contents with bat, alt-c previews dir trees with tree.
# These are env strings (no fork) read by the widgets sourced just below.
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

# Load fzf key bindings and completion (ctrl-r / ctrl-t / alt-c)
[[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && \
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
[[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]] && \
  source /opt/homebrew/opt/fzf/shell/completion.zsh

#####################
# Syntax highlighting + autosuggestions (load order is mandatory)
#####################
# Both plugins wrap ZLE widgets, so they must be sourced AFTER everything that
# defines widgets (compinit, fzf key-bindings above). Per the plugins' own
# READMEs the order between them is fixed: zsh-syntax-highlighting first, then
# zsh-autosuggestions last of all, or the suggestion highlight gets clobbered.
# Hardcoded paths intentional: $(brew --prefix) adds ~30-50ms subprocess overhead.
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Suggestion color. Both themes (theme=light:Hyper Light,dark:Hyper) share ONE
# palette and only swap bg/fg black<->white. #2e6df5 sits at ~4.5:1 against BOTH
# white and black, so Ghostty's minimum-contrast=4.5 leaves it untouched in either
# mode (a paler blue gets darkened to near-black on white). italic needs zsh>=5.8.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#2e6df5,italic'
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Register our up-arrow widget so the suggestion clears on recall, matching how the
# plugin already treats the (default-listed) down-arrow *-end widgets. up-arrow-nudge
# rewrites $BUFFER on every press; without clearing, the prior suggestion's gray text
# is left stranded on the recalled line. The non-underscore name (see the widget above)
# is what lets the plugin wrap it at all. Append AFTER sourcing: the plugin seeds the
# default list only when the var is unset, so pre-setting would clobber the defaults;
# widget binding happens at first precmd, after .zshrc finishes.
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(up-arrow-nudge)

# LM Studio CLI (lms)
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
# Herd
################################################################################
# Herd's zshrc.zsh is intentionally NOT sourced: its only content is the .nvmrc
# auto-switch chpwd hook, which forks nvm subshells on every cd and which the
# nvm_find_nvmrc stub in .zshenv disables anyway.

# The export blocks below duplicate .zshenv on purpose: Herd re-injects them
# into .zshrc on updates when it doesn't find its own marker comments, so they
# stay verbatim (hardcoded /Users/fgilio path included) to keep updates from
# dirtying the tree. .zshenv stays the canonical copy for non-interactive shells.

# Herd injected PHP 8.4 configuration.
export HERD_PHP_84_INI_SCAN_DIR="/Users/fgilio/Library/Application Support/Herd/config/php/84/"


# Herd injected PHP 8.5 configuration.
export HERD_PHP_85_INI_SCAN_DIR="/Users/fgilio/Library/Application Support/Herd/config/php/85/"


# Herd injected PHP 8.3 configuration.
export HERD_PHP_83_INI_SCAN_DIR="/Users/fgilio/Library/Application Support/Herd/config/php/83/"
