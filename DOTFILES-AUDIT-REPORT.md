# Dotfiles Audit Report

**Generated:** 2025-11-27
**Shell startup time:** ~550ms (acceptable but improvable)

---

## Executive Summary

Your dotfiles setup is **well-organized** and follows modern best practices. However, there are several **bugs**, **performance issues**, and **portability concerns** that should be addressed.

### Critical Issues
- Broken mackup symlink
- Deprecated homebrew tap
- NVM loading slowing down shell startup
- Hardcoded paths reducing portability

### Quick Wins
- Add fzf for better fuzzy finding
- Lazy-load NVM for 200ms+ faster startup
- Fix broken symlinks

---

## File-by-File Analysis

### `.zshrc` (193 lines)

**Strengths:**
- Well-organized with clear section headers
- Good history configuration with deduplication
- Proper completion system setup with caching
- PATH deduplication via `typeset -U` in `.zshenv`
- `ll` alias correctly uses `--color=auto` (works via GNU coreutils from Brewfile)

**Issues Found:**

| Line | Issue | Severity | Fix |
|------|-------|----------|-----|
| 79 | Hardcoded path `/Users/fgilio/.bun/_bun` | Medium | Use `$HOME/.bun/_bun` |
| 118 | Hardcoded path `/Users/fgilio/.zshrc` | Medium | Use `$HOME/.zshrc` |
| 167 | Hardcoded path in `zsetup-hooks` alias | Low | Use `$HOME/pla/zoo/bin/...` |
| 178 | `export NVM_DIR` with hardcoded path | Medium | Use `$HOME/Library/...` |
| 181 | Full NVM load on every shell - **~200ms penalty** | High | Lazy-load NVM |
| 193 | Hardcoded path in Antigravity PATH | Low | Use `$HOME/.antigravity/...` |

*Note: Lines 187-190 (Herd PHP configs) have hardcoded paths but are auto-injected by Herd - don't modify manually.*

**Note:** Line 149's hardcoded `/opt/homebrew/share/zsh-autosuggestions/...` path is intentional for performance. Using `$(brew --prefix)` would add ~30-50ms subprocess overhead.

**Performance Analysis:**

The NVM initialization (lines 178-184) is the **primary bottleneck**:
```
+nvm_die_on_prefix:96> nvm_npmrc_bad_news_bears ...
```
This adds ~200ms to every shell startup.

**Recommendations:**

1. **Lazy-load NVM** - only initialize when `node`/`npm`/`nvm` is called:
```zsh
# Replace lines 178-181 with:
export NVM_DIR="$HOME/Library/Application Support/Herd/config/nvm"
lazy_load_nvm() {
  unset -f node npm npx nvm
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}
for cmd in node npm npx nvm; do
  eval "$cmd() { lazy_load_nvm; $cmd \"\$@\" }"
done
```

2. **Remove hardcoded paths** - Replace all `/Users/fgilio` with `$HOME`

---

### `.zshenv` (10 lines)

**Status:** Excellent

Clean and minimal as it should be. Properly sets up PATH deduplication with `typeset -gU`.

No changes needed.

---

### `Brewfile` (106 lines)

**Issues Found:**

| Line | Issue | Severity | Fix |
|------|-------|----------|-----|
| 2 | `tap 'homebrew/cask'` is **deprecated** (now built-in) | High | Remove this line |
| 26 | `handbrake` listed as both brew and cask (lines 26, 56) | Medium | Remove brew version |
| - | Missing `fzf` - essential fuzzy finder | Medium | Add `brew 'fzf'` |
| - | Missing `eza` - modern ls replacement | Low | Consider adding |
| 56 | Duplicate: `handbrake` cask | Medium | Already covered |

**Deprecated Tap Warning:**
```
homebrew/cask was deprecated. Formulae were migrated to homebrew/core.
```

**Recommendations:**
1. Remove line 2: `tap 'homebrew/cask'`
2. Add missing essentials:
```ruby
brew 'fzf'      # Fuzzy finder - essential
brew 'eza'      # Modern ls replacement
brew 'fd'       # Modern find replacement
brew 'delta'    # Better git diffs
```
3. Remove duplicate `handbrake` (line 26 brew version)

---

### `fresh.sh` (69 lines)

**Issues Found:**

| Line | Issue | Severity | Fix |
|------|-------|----------|-----|
| 36 | `brew tap homebrew/bundle` - deprecated, now built-in | Low | Remove |
| 39-46 | Redundant installs - already in Brewfile | Medium | Remove duplicates |
| 62-65 | `$DOTFILES` variable never defined | Critical | Should be `$HOME/.dotfiles` |

**Critical Bug (lines 62-65):**
```sh
$DOTFILES/clone.sh           # UNDEFINED!
ln -s $DOTFILES/.mackup.cfg  # UNDEFINED!
source $DOTFILES/.macos      # UNDEFINED!
```

The `$DOTFILES` variable is never set. This causes:
1. `clone.sh` to fail
2. **Broken mackup symlink** (currently points to `/.mackup.cfg`)
3. `.macos` to fail

**Current broken symlink:**
```
~/.mackup.cfg -> /.mackup.cfg  # BROKEN!
```

**Fix:** Add at the top of `fresh.sh`:
```sh
DOTFILES="$HOME/.dotfiles"
```

---

### `clone.sh` (19 lines)

**Status:** Functional but fragile

**Issues:**
- No error handling - fails silently if git clone fails
- No check for existing directories
- Hardcoded organization repos may not be accessible on fresh machine

**Recommendations:**
```sh
clone_if_missing() {
  local repo="$1" dest="$2"
  if [ ! -d "$dest" ]; then
    git clone "$repo" "$dest" || echo "Failed: $repo"
  fi
}
```

---

### `.gitconfig` (48 lines)

**Status:** Excellent

Following modern best practices from the Git Core team. Notable good settings:
- `push.autoSetupRemote = true` - auto-tracks remote branches
- `rerere.enabled = true` - remembers conflict resolutions
- `rebase.autoSquash = true` - respects fixup commits
- `diff.algorithm = histogram` - better diff algorithm
- `merge.conflictstyle = zdiff3` - superior conflict markers

**One Issue:**

| Line | Issue | Severity | Fix |
|------|-------|----------|-----|
| 41 | Hardcoded excludesfile path | Medium | Use `~/.dotfiles/.gitignore_global` |

---

### `.gitignore_global` (44 lines)

**Status:** Good

**Missing entries to consider:**
```gitignore
# Node
node_modules/

# Environment files (security)
.env.local
.env*.local

# Editor
*.swp
*.swo
*~

# macOS
.AppleDouble
.LSOverride
```

---

### `starship.toml` (62 lines)

**Status:** Excellent

Minimal, fast configuration. All version displays disabled for speed.

**Minor improvements:**
```toml
# Add scan_timeout to prevent slow git repos from blocking
[git_status]
disabled = false  # Keep git status
format = '([$all_status$ahead_behind]($style) )'

# Consider adding for large repos:
[git_status]
windows_starship = "/mnt/c/..."  # Only if using WSL
```

---

### `functions/dev-tools.zsh` (59 lines)

**Status:** Good

**Issues:**

| Line | Issue | Severity |
|------|-------|----------|
| 36-55 | `git-open` function duplicates `brew 'git-open'` | Low |
| 41 | `sed 's/\.git$//'` doesn't handle all URL formats | Low |

The `git-open` function is redundant since you have `brew 'git-open'` installed.

---

### `.macos` (439 lines)

**Status:** Comprehensive

Well-documented macOS preferences. Based on Mathias Bynens' popular script.

**Issues:**

| Line | Issue | Severity |
|------|-------|----------|
| 16-19 | Hardcoded computer name "tesla" | Medium |
| 113 | Hardcoded screenshot path with email | Medium |
| 116 | Screenshots set to JPG (lossy) - PNG better for code | Low |

**Security Note:**
Line 45 disables Gatekeeper quarantine:
```sh
defaults write com.apple.LaunchServices LSQuarantine -bool false
```
This is a **security risk** - consider keeping enabled.

---

### `ssh.sh` (21 lines)

**Status:** Functional

**Issues:**

| Line | Issue | Severity |
|------|-------|----------|
| 14 | `echo "..."` with `\n` won't work in `/bin/sh` | Medium |
| 16 | `-K` flag deprecated, use `--apple-use-keychain` | Medium |

**Fix for line 14:**
```sh
printf "Host *\n AddKeysToAgent yes\n UseKeychain yes\n IdentityFile ~/.ssh/id_ed25519\n" > ~/.ssh/config
```

---

### `.mackup.cfg` (6 lines)

**Status:** Good configuration, but **symlink is broken**

The file content is correct, but the symlink points to `/.mackup.cfg` instead of `~/.dotfiles/.mackup.cfg`.

---

### `bin/` Scripts

#### `cl` (Claude Code wrapper)
**Issue:** `ANTHROPIC_API_KEY=""` clears the API key - intentional?

#### `cr` (Cursor Agent wrapper)
**Issue:** References `gpt-5` model which doesn't exist publicly

#### `cx` (Codex wrapper)
**Issue:** References `gpt-5.1-codex-max` model which doesn't exist publicly

---

### `minimal.zsh-theme` (300 lines)

**Status:** Not currently used (Starship is active)

Consider removing if not planning to use Oh-My-Zsh.

---

### Empty Directories

- `plugins/` - empty, remove or populate
- `git/` - empty, remove or populate

---

## Performance Optimization

### Current Shell Startup: ~550ms

**Breakdown:**
- compinit: ~50ms
- zsh-autosuggestions: ~30ms
- Starship init: ~50ms
- zoxide init: ~20ms
- **NVM full load: ~200ms** (biggest offender)
- Herd shell integration: ~100ms
- Other: ~100ms

### Optimized Target: ~300ms

**Actions to achieve this:**

1. **Lazy-load NVM** (-200ms)
2. **Cache compinit** (-30ms):
```zsh
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C  # Skip security check
fi
```

3. **Consider Herd integration** - can it be lazy-loaded?

---

## Portability Assessment

### Score: 7/10

**Portable:**
- Brewfile handles all package installation
- Symlink strategy is good
- SSH key generation script works
- macOS preferences are automated

**Not Portable:**

1. **Hardcoded paths** - 8 instances of `/Users/fgilio`
2. **Missing `$DOTFILES` variable** in `fresh.sh`
3. **Broken mackup symlink**

### Portability Fixes

1. **Define DOTFILES everywhere:**
```sh
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
```

2. **Fix all hardcoded paths**

---

## Security Review

### Issues Found:

| Item | Risk | Recommendation |
|------|------|----------------|
| Gatekeeper disabled (`.macos:45`) | Medium | Re-enable |
| `--dangerously-skip-permissions` in `cl` | Low | Intentional for dev |
| API keys may be in `~/.env` | Medium | Ensure not in git |
| `.gitignore_global` missing `.env` | Medium | Add `.env*` patterns |

---

## Action Items (Priority Order)

### Critical (Do Now)
1. Fix `$DOTFILES` variable in `fresh.sh`
2. Fix broken mackup symlink: `ln -sf ~/.dotfiles/.mackup.cfg ~/.mackup.cfg`
3. Remove deprecated `homebrew/cask` tap from Brewfile

### High (This Week)
4. Implement NVM lazy-loading
5. Replace hardcoded paths with `$HOME`
6. Update `ssh.sh` deprecated `-K` flag

### Medium (Soon)
7. Add fzf to Brewfile and configure
8. Add compinit caching
9. Update `.gitignore_global` with missing patterns
10. Remove empty `plugins/` and `git/` directories
11. Remove duplicate `git-open` function (use brew version)

### Low (When Convenient)
12. Consider adding `eza`, `fd`, `delta` to Brewfile
13. Update README.md (references Oh-My-Zsh which isn't used)
14. Remove unused `minimal.zsh-theme`

---

## Appendix: Quick Copy-Paste Fixes

### Fix broken mackup symlink
```sh
rm ~/.mackup.cfg
ln -s ~/.dotfiles/.mackup.cfg ~/.mackup.cfg
```

### Fix fresh.sh DOTFILES variable
```sh
# Add after line 3 in fresh.sh:
DOTFILES="$HOME/.dotfiles"
```

### Remove deprecated tap
```sh
# Remove from Brewfile line 2:
# tap 'homebrew/cask'  # DELETE THIS LINE
```

### Add NVM lazy-loading
```sh
# Replace .zshrc lines 178-181 with:
export NVM_DIR="$HOME/Library/Application Support/Herd/config/nvm"
_nvm_lazy_load() {
  unset -f node npm npx nvm 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}
for cmd in node npm npx nvm; do
  eval "$cmd() { _nvm_lazy_load && $cmd \"\$@\" }"
done
```

---

*Report generated by Claude Code*
