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

## Code style

- Comment the why: hardcoded values that look wrong, optimizations that trade correctness, workarounds, anything that would confuse future-you. Never a comment that restates the code.
- No abstractions for single-use code: three similar lines beat a premature helper.
- No compatibility shims: delete unused things completely.
