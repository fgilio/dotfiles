#!/usr/bin/env bash
# Sourced by bin/rm and bin/trash — never executed (tracked 644 on purpose).
# The dangerous-path refusal is the safety core of both wrappers; it used to be
# copy-pasted in each, where a hardening fix applied to one copy would silently
# miss the other. Sourcing is a file read, not a fork, so the callers stay cheap.

is_dangerous_path() {
  local p="$1"
  # Obvious dangerous raw forms, no forking needed
  case "$p" in
    / | . | .. | "" | ./ | ../ | /./* | /../*) return 0 ;; # dangerous
  esac
  # All-slash paths ("//") are root in disguise
  local stripped="${p%"${p##*[!/]}"}"
  [[ -z "$stripped" ]] && return 0 # dangerous
  # Resolve through the filesystem only when the final component is "." or ".."
  # (only those can normalize to /, e.g. "/usr/.."); skipping the resolution
  # for plain names is what keeps the callers from forking per file
  local base="${stripped##*/}"
  if [[ "$base" == "." || "$base" == ".." ]]; then
    local resolved
    resolved="$(cd -- "$p" 2>/dev/null && pwd -P)" || resolved=""
    [[ "$resolved" == "/" ]] && return 0 # dangerous
  fi
  return 1 # safe
}
