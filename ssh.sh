#!/bin/bash
set -euo pipefail

# Sets up GitHub SSH access on a fresh machine.
#
# Two identities live on this machine, on purpose:
#   * every host  -> the 1Password SSH agent, which asks for Touch ID per use
#   * github.com  -> a dedicated on-disk key, no passphrase, no agent
#
# Routine `git fetch`/`push` runs dozens of times an hour, and a biometric
# prompt on each one is not worth the protection: the key it guards reaches
# GitHub only and is revoked in one click at https://github.com/settings/keys.
# Server access keeps the agent and keeps the prompt.
#
# Safe to re-run. Every step checks the EFFECTIVE state (`ssh -G`) rather than
# grepping the config for a string, because a correct-looking block placed
# below `Host *` is silently ineffective.

KEY="$HOME/.ssh/id_ed25519_github"
CONFIG="$HOME/.ssh/config"
KNOWN_HOSTS="$HOME/.ssh/known_hosts"

# The tilde is deliberate and must survive unexpanded: it is written verbatim
# into ssh_config, where ssh performs the expansion itself.
# shellcheck disable=SC2088
AGENT_SOCK="~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Blocks this script writes are fenced so they can be replaced wholesale on a
# re-run. Anything outside the fences is hand-written and never touched.
BEGIN_MARK="# >>> dotfiles ssh.sh: github-only key >>>"
END_MARK="# <<< dotfiles ssh.sh: github-only key <<<"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$CONFIG"
chmod 600 "$CONFIG"

# `ssh -G` reports the settings ssh would really use for a host, Include files
# and block order resolved. It is the only honest test of this config. `-F` names
# the file explicitly: ssh expands `~` from the passwd entry and ignores $HOME,
# so without it these checks could read a different config than the managed one.
github_effective() {
  local resolved
  resolved="$(ssh -F "$CONFIG" -G github.com 2>/dev/null)" || return 1
  grep -qix 'identityagent none' <<<"$resolved" \
    && grep -qi '^identityfile .*id_ed25519_github$' <<<"$resolved"
}

# A host matching no explicit block shows what `Host *` grants everything else.
agent_effective() {
  ssh -F "$CONFIG" -G dotfiles-agent-probe.invalid 2>/dev/null \
    | grep -qi '^identityagent .*com\.1password.*agent\.sock'
}

# ---- 1. the GitHub-only key ---------------------------------------------
# The comment carries the machine name so the entry stays identifiable in
# GitHub's key list years from now.
if [[ -f "$KEY" ]]; then
  # A private key whose public half is missing or mismatched breaks
  # registration later, in a way that is confusing at that distance.
  if [[ ! -f "$KEY.pub" ]]; then
    ssh-keygen -y -f "$KEY" >"$KEY.pub"
    echo "✓ regenerated missing public half: $KEY.pub"
  elif [[ "$(ssh-keygen -y -f "$KEY" | cut -d' ' -f1,2)" != "$(cut -d' ' -f1,2 "$KEY.pub")" ]]; then
    echo "✗ $KEY and $KEY.pub are different keys. Resolve by hand; refusing to guess." >&2
    exit 1
  fi
  echo "✓ key exists: $KEY"
else
  ssh-keygen -t ed25519 -f "$KEY" -C "github-only $(scutil --get LocalHostName)" -N "" -q
  echo "✓ key created: $KEY"
fi

# ---- 2. github.com host keys --------------------------------------------
# Taken from GitHub's TLS-authenticated metadata endpoint, not ssh-keyscan:
# keyscan trusts whatever answers on port 22. Without this, the verification
# below cannot pass on a fresh machine, because BatchMode refuses to prompt
# for an unknown host key and fails before authentication is ever attempted.
if ssh-keygen -F github.com -f "$KNOWN_HOSTS" >/dev/null 2>&1; then
  echo "✓ github.com host keys already trusted"
else
  host_keys="$(curl -fsSL https://api.github.com/meta \
    | tr ',' '\n' \
    | grep -oE '"(ssh-ed25519|ecdsa-sha2-nistp256|ssh-rsa) [A-Za-z0-9+/=]+"' \
    | tr -d '"')"
  if [[ -z "$host_keys" ]]; then
    echo "✗ could not fetch host keys from https://api.github.com/meta" >&2
    exit 1
  fi
  while IFS= read -r host_key; do
    printf 'github.com %s\n' "$host_key" >>"$KNOWN_HOSTS"
  done <<<"$host_keys"
  chmod 600 "$KNOWN_HOSTS"
  echo "✓ github.com host keys added to $KNOWN_HOSTS"
fi

# ---- 3. route github.com to the on-disk key ------------------------------
if github_effective; then
  echo "✓ ssh already resolves github.com to the on-disk key"
else
  # Drop any fenced block from an earlier run: it is either stale or in the
  # wrong place, and a second copy below `Host *` would stay ineffective.
  if grep -qF "$BEGIN_MARK" "$CONFIG"; then
    sed -i '' "/^${BEGIN_MARK}\$/,/^${END_MARK}\$/d" "$CONFIG"
  fi

  block="$(mktemp)"
  trap 'rm -f "$block"' EXIT
  cat >"$block" <<BLOCK
$BEGIN_MARK
# GitHub authenticates with a dedicated on-disk key instead of the 1Password
# agent, whose every operation asks for Touch ID. Keep this block ABOVE
# \`Host *\`: ssh_config keeps the first value obtained for each keyword.
Host github.com
  IdentityAgent none
  IdentityFile ~/.ssh/id_ed25519_github
  IdentitiesOnly yes
$END_MARK

BLOCK

  # SSH keywords are case-insensitive, so `host *` and `HOST *` must match too.
  if awk 'tolower($0) ~ /^[[:space:]]*host[[:space:]]+\*[[:space:]]*$/ { found = 1 } END { exit !found }' "$CONFIG"; then
    awk -v block="$block" '
      tolower($0) ~ /^[[:space:]]*host[[:space:]]+\*[[:space:]]*$/ && !inserted {
        while ((getline line < block) > 0) print line
        inserted = 1
      }
      { print }
    ' "$CONFIG" >"$CONFIG.new"
    mv "$CONFIG.new" "$CONFIG"
  else
    cat "$block" "$CONFIG" >"$CONFIG.new"
    mv "$CONFIG.new" "$CONFIG"
  fi
  chmod 600 "$CONFIG"

  if github_effective; then
    echo "✓ ssh config: github.com now uses $KEY"
  else
    echo "✗ wrote the block, but ssh -G github.com still disagrees." >&2
    echo "  Something earlier in $CONFIG (often an Include) sets IdentityAgent first." >&2
    exit 1
  fi
fi

# ---- 4. every other host keeps the 1Password agent -----------------------
if agent_effective; then
  echo "✓ ssh already routes other hosts to the 1Password agent"
else
  # Appended last so it can never land above the github.com block.
  cat >>"$CONFIG" <<BLOCK

# Keys for every other host live in the 1Password SSH agent, not on disk.
Host *
  IdentityAgent "$AGENT_SOCK"
BLOCK
  echo "✓ ssh config: other hosts now use the 1Password agent"
fi

# ---- 4b. flag leftovers from the pre-2026 version of this script ---------
# It used to append `IdentityFile ~/.ssh/id_ed25519` under `Host *`.
# IdentityFile is additive, so that line keeps offering the old key to every
# host, including github.com. Reported rather than deleted: hand-written config
# is not this script's to rewrite.
if grep -qE '^[[:space:]]*IdentityFile[[:space:]]+~/\.ssh/id_ed25519[[:space:]]*$' "$CONFIG"; then
  echo "! $CONFIG still has 'IdentityFile ~/.ssh/id_ed25519' from the old setup."
  echo "  It is additive and offers that key to every host. Remove it by hand."
fi

# ---- 5. register the public key ------------------------------------------
# GitHub cannot be told about the key from here without granting the gh token
# the admin:public_key scope, which is not worth a once-per-machine step.
#
# `ssh -T git@github.com` exits 1 even when authentication succeeds (GitHub
# refuses the shell), so the greeting is matched instead of the exit status.
greeting="$(ssh -F "$CONFIG" -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1 || true)"
if [[ "$greeting" == *"successfully authenticated"* ]]; then
  echo "✓ github.com authentication works"
else
  pbcopy <"$KEY.pub"
  echo ""
  echo "Public key copied to the clipboard. Paste it at the page opening now,"
  echo "title it '$(scutil --get LocalHostName) — github-only', keep type 'Authentication key'."
  echo "Then re-run this script to verify."
  echo ""
  echo "ssh said: $greeting"
  open "https://github.com/settings/ssh/new"
fi
