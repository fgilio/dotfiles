# Claude Code Instructions for .dotfiles

## Public repository

Everything committed here is visible to anyone. Secrets and machine-local values go in `~/.env` (sourced by `.zshrc`, outside the repo), never in a tracked file.

## Target environment

- macOS on Apple Silicon only: no Linux, Windows, WSL or Intel fallbacks.
- Homebrew lives at `/opt/homebrew`. Hardcode it: `$(brew --prefix)` forks a subprocess (~30-50ms) and `bin/check` fails the commit.
- Herd is always installed and manages PHP and Node (NVM): no handling for a missing Herd or NVM.

## Priorities, in order

1. Startup speed: an interactive shell must start in under 50ms, and every fork at startup counts.
2. Simplicity: no over-engineering.
3. Ergonomics: sensible defaults, minimal friction.

## Code style

- Comment the why: hardcoded values that look wrong, optimizations that trade correctness, workarounds, anything that would confuse future-you. Never a comment that restates the code.
- No abstractions for single-use code: three similar lines beat a premature helper.
- No compatibility shims: delete unused things completely.
