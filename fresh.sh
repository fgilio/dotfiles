#!/bin/bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"

echo "Setting up your Mac..."

# Check for Homebrew and install if we don't have it
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Only add if not already present (idempotent)
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Symlink shell config files (ln -sf overwrites safely, no rm -rf needed)
ln -sf "$DOTFILES/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES/.zshenv" "$HOME/.zshenv"
ln -sf "$DOTFILES/.gitconfig" "$HOME/.gitconfig"

# Ensure dotfiles bin directory scripts are executable
chmod +x "$DOTFILES/bin/"*

# Symlink Starship config
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"

# Symlink Ghostty config
mkdir -p "$HOME/.config/ghostty"
ln -sf "$DOTFILES/ghostty.config" "$HOME/.config/ghostty/config"

# Create ~/tmp for ocr alias and other temp operations
mkdir -p "$HOME/tmp"

# Symlink hushlogin to suppress terminal login message
ln -sf "$DOTFILES/hushlogin" "$HOME/.hushlogin"

# Update Homebrew recipes
brew update

# Install all dependencies with bundle (See Brewfile)
# Includes: starship, zoxide, btop, zsh-autosuggestions, coreutils, etc.
brew bundle --file "$DOTFILES/Brewfile"

# Create Sublime Text terminal launcher (subl, not sublime)
if [[ -d "/Applications/Sublime Text.app" ]]; then
  sudo ln -sf "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
fi

# Herd handles PHP and extensions

# Install global Composer packages
if command -v composer &> /dev/null; then
  composer global require laravel/installer beyondcode/expose ymirapp/cli
fi

# Symlink the Mackup config file to the home directory
ln -sf "$DOTFILES/.mackup.cfg" "$HOME/.mackup.cfg"

# Set macOS preferences - we will run this last because this will reload the shell
# Disable errexit for .macos since many defaults commands exit non-zero on reruns
set +e
source "$DOTFILES/.macos"
set -e
