#!/bin/bash
set -euo pipefail

# Sets up GitHub SSH access on a fresh machine.
#
# Two identities live on this machine, on purpose:
#   * every host  -> the 1Password SSH agent, which asks for Touch ID per use
#   * github.com  -> a dedicated on-disk key, no passphrase, no agent
#
# Routine `git fetch`/`push` runs dozens of times an hour, and a biometric prompt
# on each one is not worth the protection: the key it guards can only reach
# GitHub and is revoked with one click at https://github.com/settings/keys.
# Server access keeps the agent and keeps the prompt.
#
# Safe to re-run: every step is skipped when it is already in place.

KEY="$HOME/.ssh/id_ed25519_github"
CONFIG="$HOME/.ssh/config"
# The tilde is deliberate and must survive unexpanded: it is written verbatim
# into ssh_config, where ssh performs the expansion itself.
# shellcheck disable=SC2088
AGENT_SOCK="~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$CONFIG"
chmod 600 "$CONFIG"

# 1. The GitHub-only key. Comment carries the machine name so the entry is
# identifiable in GitHub's key list years from now.
if [[ -f "$KEY" ]]; then
  echo "✓ key exists: $KEY"
else
  ssh-keygen -t ed25519 -f "$KEY" -C "github-only $(scutil --get LocalHostName)" -N "" -q
  echo "✓ key created: $KEY"
fi

# 2. The github.com block. It MUST precede `Host *`: ssh_config keeps the first
# value it obtains for each keyword, so a later block cannot override the
# IdentityAgent set by `Host *`.
if grep -q 'id_ed25519_github' "$CONFIG"; then
  echo "✓ ssh config already routes github.com to the on-disk key"
else
  cat >/tmp/gh-ssh-block.$$ <<'BLOCK'
# GitHub authenticates with a dedicated on-disk key instead of the 1Password
# agent, whose every operation asks for Touch ID. Keep this block ABOVE `Host *`:
# ssh_config keeps the first value obtained for each keyword.
Host github.com
  IdentityAgent none
  IdentityFile ~/.ssh/id_ed25519_github
  IdentitiesOnly yes

BLOCK

  if grep -qE '^[[:space:]]*Host[[:space:]]+\*' "$CONFIG"; then
    awk -v block="/tmp/gh-ssh-block.$$" '
      /^[[:space:]]*Host[[:space:]]+\*/ && !done {
        while ((getline line < block) > 0) print line
        done = 1
      }
      { print }
    ' "$CONFIG" >"$CONFIG.new"
    mv "$CONFIG.new" "$CONFIG"
  else
    cat /tmp/gh-ssh-block.$$ >>"$CONFIG"
  fi

  rm -f /tmp/gh-ssh-block.$$
  chmod 600 "$CONFIG"
  echo "✓ ssh config: github.com now uses $KEY"
fi

# 3. Every other host goes to the 1Password agent. Appended last so it can never
# land above the github.com block.
if grep -q 'IdentityAgent' "$CONFIG" && grep -q '1password' "$CONFIG"; then
  echo "✓ ssh config already points other hosts at the 1Password agent"
else
  cat >>"$CONFIG" <<BLOCK

# Keys for every other host live in the 1Password SSH agent, not on disk.
Host *
  IdentityAgent "$AGENT_SOCK"
BLOCK
  echo "✓ ssh config: other hosts now use the 1Password agent"
fi

# 4. Register the public key. GitHub cannot be told about it from here without
# granting the gh token the admin:public_key scope, which is not worth a
# once-per-machine step.
# `ssh -T git@github.com` exits 1 even when authentication succeeds (GitHub
# refuses the shell), so the greeting is matched instead of the exit status.
greeting="$(ssh -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1 || true)"
if [[ "$greeting" == *"successfully authenticated"* ]]; then
  echo "✓ github.com authentication works"
else
  pbcopy <"$KEY.pub"
  echo ""
  echo "Public key copied to the clipboard. Paste it at the page opening now,"
  echo "title it '$(scutil --get LocalHostName) — github-only', keep type 'Authentication key'."
  echo "Then re-run this script to verify."
  open "https://github.com/settings/ssh/new"
fi
