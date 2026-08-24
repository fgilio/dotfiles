# fgilio's Dotfiles

![CI](https://github.com/fgilio/dotfiles/actions/workflows/ci.yml/badge.svg)

Special thanks to https://github.com/driesvints whose [dotfiles repo](https://github.com/driesvints/dotfiles) I used as a base.

This repository serves as my way to help me setup and maintain my Mac, to ease the effort out of installing everything manually. It's a constant wip, as I'm almost always tuning my setup. Feel free to explore, learn and copy anything.

## A Fresh macOS Setup

These instructions are for setting up new Mac devices.

### Backup your data

If you're migrating from an existing Mac, you should first make sure to backup all of your existing data. Go through the checklist below to make sure you didn't forget anything before you migrate.

- Did you commit and push any changes/branches to your git repositories?
- Did you remember to save all important documents from non-iCloud directories?
- Did you save all of your work from apps which aren't synced through iCloud?
- Did you remember to export important data from your local database?
- Did you update [mackup](https://github.com/lra/mackup) to the latest version and ran `mackup backup`?

### Setting up your Mac

After backing up your old Mac you may now follow these install instructions to setup a new one.

1. Update macOS to the latest version through system preferences
2. Set up GitHub SSH access by running:

   ```zsh
   curl https://raw.githubusercontent.com/fgilio/dotfiles/HEAD/ssh.sh | bash
   ```

   It creates `~/.ssh/id_ed25519_github`, writes the matching `~/.ssh/config` blocks, trusts GitHub's host keys, and opens the page to register the key. Safe to re-run; the last line reports whether authentication works. This is `curl | bash` against a mutable `HEAD`: if this repo or my GitHub account were compromised, that is code execution on a fresh machine. Read the script first if that bothers you.

3. Paste the key (already on the clipboard) at [github.com/settings/ssh/new](https://github.com/settings/ssh/new), then re-run the script to verify. Skipping this makes the SSH clone below fail with `Permission denied`

4. Clone this repo to `~/.dotfiles` with:

    ```zsh
    git clone git@github.com:fgilio/dotfiles.git ~/.dotfiles
    ```

5. Sign into the App Store (required for `mas` apps in Brewfile)

6. Run the installation with:

    ```zsh
    ~/.dotfiles/fresh.sh
    ```

7. After mackup is synced with your cloud storage, restore preferences by running `mackup restore`
8. Restart your computer to finalize the process

Your Mac is now ready to use!

> You can use a different location than `~/.dotfiles` if you want. Make sure you also update the references in [`.zshenv`](./.zshenv) (`DOTFILES`), [`fresh.sh`](./fresh.sh), and [`.gitconfig`](./.gitconfig) (`excludesfile`).

### Cleaning your old Mac (optionally)

After you've set up your new Mac you may want to wipe and clean install your old Mac. Follow [this article](https://support.apple.com/guide/mac-help/erase-and-reinstall-macos-mh27903/mac) to do that. Remember to [backup your data](#backup-your-data) first!

## Key Components

| File/Directory | Purpose |
|----------------|---------|
| `.zshrc` | Main shell config (~30-40ms startup) |
| `.zshenv` | Environment variables and PATH |
| `Brewfile` | All packages and casks |
| `fresh.sh` | New machine setup script |
| `functions/dev-tools.zsh` | Custom shell functions |
| `starship.toml` | Prompt configuration |
| `.macos` | macOS system preferences |

### SSH identities

Two identities, split by how often they are used:

| Host | Key | Prompt |
|------|-----|--------|
| `github.com` | `~/.ssh/id_ed25519_github`, on disk, no passphrase | none |
| everything else | 1Password SSH agent | Touch ID per use |

Routine `git fetch`/`push` runs constantly, and a biometric prompt on each one is not worth what it buys. What it costs is worth stating plainly: the key has no passphrase, so anything running as my user can copy it and use it from another machine, with access to every repository the GitHub account can reach — private and organization repos included, cloning code and pushing where branch rules allow — until the theft is noticed and the key revoked. FileVault protects a locked volume and mode `0600` protects against other local users; neither protects against malware running as me, or an unencrypted backup. The real control against a stolen push credential is branch protection with required review, not a fingerprint prompt. Server access keeps the agent and keeps the prompt.

Two mechanics worth remembering:

- The `Host github.com` block must stay **above** `Host *` — ssh_config keeps the first value obtained for each keyword, so a later block cannot override `IdentityAgent` and is silently ignored. `ssh.sh` checks the effective result with `ssh -G` rather than grepping for the block, because a misplaced block greps as present while doing nothing.
- `ssh.sh` seeds `known_hosts` from GitHub's TLS-authenticated `api.github.com/meta` rather than `ssh-keyscan`, which trusts whatever answers on port 22. Without it, verification on a fresh machine fails before authentication is attempted, since `BatchMode` refuses to prompt for an unknown host key.

`~/.ssh/config` itself is not tracked here (it holds work hostnames), so `ssh.sh` is the reproducible part.

### Stack

- **Shell**: Zsh with [Starship](https://starship.rs/) prompt (no Oh My Zsh)
- **Package Manager**: [Homebrew](https://brew.sh/)
- **PHP**: [Laravel Herd](https://herd.laravel.com/) (also manages Node via NVM)
- **JavaScript Runtime**: [Bun](https://bun.sh/) (self-managed in `~/.bun`, upgrade with `bun upgrade`)
- **Agent CLIs**: [Claude Code](https://claude.com/claude-code), [Codex](https://developers.openai.com/codex/cli), and [opencode](https://opencode.ai/), each self-managed by its own installer (`bin/cl`, `bin/cx` wrap the first two)
- **Navigation**: [zoxide](https://github.com/ajeetdsouza/zoxide) (smart cd)

## Customizing

Go through the [`.macos`](./.macos) file and adjust the settings to your liking. You can find much more settings at [the original script by Mathias Bynens](https://github.com/mathiasbynens/dotfiles/blob/master/.macos) and [Kevin Suttle's macOS Defaults project](https://github.com/kevinSuttle/MacOS-Defaults).

Check out the [`Brewfile`](./Brewfile) file and adjust the apps you want to install for your machine. Use [their search page](https://formulae.brew.sh/) to check if the app you want to install is available.

When installing these dotfiles for the first time you'll need to backup all of your settings with Mackup. Mackup is installed via the Brewfile, so just run the backup command. Your settings will be synced to iCloud so you can use them to sync between computers and reinstall them when reinstalling your Mac. If you want to save your settings to a different directory or different storage than iCloud, [checkout the documentation](https://github.com/lra/mackup/blob/master/doc/README.md#storage).

```zsh
mackup backup
```

## Many thanks to:

* https://github.com/driesvints/dotfiles
* https://github.com/zellwk/dotfiles
* https://github.com/sam-hosseini/dotfiles
* https://github.com/mathiasbynens/dotfiles
* https://github.com/holman/dotfiles
