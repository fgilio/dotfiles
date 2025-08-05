#!/bin/sh

echo "Setting up your Mac..."

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
rm -rf $HOME/.zshrc
ln -s $HOME/.dotfiles/.zshrc $HOME/.zshrc

# Symlink Starship config
mkdir -p $HOME/.config
ln -sf $HOME/.dotfiles/starship.toml $HOME/.config/starship.toml

# Update Homebrew recipes
brew update

# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle --file $HOME/.dotfiles/Brewfile

# Install Starship prompt
brew install starship

# Install Bun
curl -fsSL https://bun.sh/install | bash

# Install other terminal tools
brew install zoxide btop zsh-autosuggestions

# Create Sublime Text terminal launcher
sudo ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/sublime


# Herd handles PHP and extensions

# Install global Composer packages
composer global require laravel/installer beyondcode/expose ymirapp/cli


# Create a publica.la directory
mkdir $HOME/pla

# Clone Github and GitLab repositories
$DOTFILES/clone.sh

# Symlink the Mackup config file to the home directory
ln -s $DOTFILES/.mackup.cfg $HOME/.mackup.cfg

# Set macOS preferences - we will run this last because this will reload the shell
source $DOTFILES/.macos
