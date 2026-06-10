# Claude Code Instructions for .dotfiles

## Important: Public Repository

This is a **public repository**. Even though it's a personal dotfiles project:
- Assume all committed content is visible to anyone
- The `~/.env` file is sourced but intentionally NOT tracked
- Secret scanning is enforced by `gitleaks` (pre-commit + CI)

---

## Target Environment

- **macOS only**: no Linux, no Windows, no WSL
- **Apple Silicon only**: no Intel Mac support needed
- **Homebrew at `/opt/homebrew`**: always this path, never dynamic
- **Herd always installed**: manages PHP and Node (via NVM)

---

## Core Values (Priority Order)

1. **Speed**: shell startup must stay under 100ms. Every millisecond counts.
2. **Simplicity**: no over-engineering. No abstractions for one-time operations.
3. **Developer Experience**: ergonomic aliases, sensible defaults, minimal friction.

---

## Code Style

### Comments: Explain the "Why"

Always add comments explaining **why** a decision was made, especially for:
- Hardcoded values that look wrong but are intentional
- Performance optimizations that sacrifice "correctness"
- Workarounds for bugs or quirks
- Anything that might confuse future-you

```zsh
# Good: explains WHY
# Hardcoded path intentional: $(brew --prefix) adds ~30-50ms subprocess overhead
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Bad: explains WHAT (the code already shows this)
# Source zsh-autosuggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```

### What NOT to Do

- **No cross-platform fallbacks**: this is macOS Apple Silicon only
- **No defensive coding for impossible scenarios**: if Herd is always installed, don't handle "what if NVM is missing"
- **No abstractions for single-use code**: three similar lines > premature helper function
- **No compatibility shims**: if something is unused, delete it completely

---

## Key Files

| File | Purpose | Notes |
|------|---------|-------|
| `.zshrc` | Main shell config | Optimized for ~30-40ms startup |
| `.zshenv` | Environment variables, PATH | Minimal, runs for all shells |
| `Brewfile` | All packages and casks | Single source of truth |
| `fresh.sh` | New machine setup | Run once after cloning |
| `functions/dev-tools.zsh` | Custom shell functions | Sourced by .zshrc |
| `starship.toml` | Prompt configuration | Minimal for speed |
| `.macos` | macOS system preferences | Run once, logout required |

---

## Technical Decisions Log

| Decision | Rationale |
|----------|-----------|
| Hardcoded `/opt/homebrew` | `brew --prefix` subprocess adds ~30-50ms (enforced by `bin/check`) |
| NVM lazy-loaded | Saves ~200ms on shell startup |
| No NVM fallback | Herd always installed on this machine |
| GNU coreutils `gls` for `ll` | Enables `--color=auto` flag (plain `ls` stays BSD `ls -G`) |
| `alias top=btop` | Intentional replacement, not shadowing |
