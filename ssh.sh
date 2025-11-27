#!/bin/bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: ssh.sh <your-email-address>"
  exit 1
fi

EMAIL="$1"
KEY_PATH="$HOME/.ssh/id_ed25519"

# Check if key already exists
if [[ -f "$KEY_PATH" ]]; then
  echo "SSH key already exists at $KEY_PATH"
  echo "Delete it first if you want to generate a new one."
  exit 1
fi

echo "Generating a new SSH key for GitHub, GitLab, etc..."

# Ensure .ssh directory exists with correct permissions
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Generating a new SSH key
# https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key
ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH"

# Adding your SSH key to the ssh-agent
# https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#adding-your-ssh-key-to-the-ssh-agent
eval "$(ssh-agent -s)"

# Configure SSH to use keychain (append if not already configured)
touch "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

# Only add config if not already present
if ! grep -q "IdentityFile ~/.ssh/id_ed25519" "$HOME/.ssh/config"; then
  cat >> "$HOME/.ssh/config" << 'EOF'

Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
fi

ssh-add --apple-use-keychain "$KEY_PATH"

# Adding your SSH key to your GitHub account
# https://docs.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account
echo ""
echo "SSH key generated! Run 'pbcopy < ~/.ssh/id_ed25519.pub' and paste into GitHub, GitLab, etc."
