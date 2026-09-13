# Claude Code Instructions for .dotfiles

## Public repository

Everything committed here is visible to anyone. Secrets and machine-local values go in `~/.env` (sourced by `.zshrc`, outside the repo), never in a tracked file.

## Target environment

- macOS on Apple Silicon only: no Linux, Windows, WSL or Intel fallbacks.
- Homebrew lives at `/opt/homebrew`. Hardcode it: `$(brew --prefix)` forks a subprocess (~30-50ms) and `bin/check` fails the commit.
- Herd is always installed and manages PHP and Node (NVM): no handling for a missing Herd or NVM.

## Core Values (Priority Order)

1. **Speed**: shell startup must stay under 100ms. Every millisecond counts.
2. **Simplicity**: no over-engineering. No abstractions for one-time operations.
3. **Developer Experience**: ergonomic aliases, sensible defaults, minimal friction.

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

- **No abstractions for single-use code**: three similar lines > premature helper function
- **No compatibility shims**: if something is unused, delete it completely
