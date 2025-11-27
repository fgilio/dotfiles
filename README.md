# fgilio's Dotfiles

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
2. [Generate a new public and private SSH key](https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) by running:

   ```zsh
   curl https://raw.githubusercontent.com/fgilio/dotfiles/HEAD/ssh.sh | bash -s "<your-email-address>"
   ```

3. Clone this repo to `~/.dotfiles` with:

    ```zsh
    git clone --recursive git@github.com:fgilio/dotfiles.git ~/.dotfiles
    ```

4. Sign into the App Store (required for `mas` apps in Brewfile)

5. Run the installation with:

    ```zsh
    chmod +x ~/.dotfiles/fresh.sh
    ~/.dotfiles/fresh.sh
    ```

6. After mackup is synced with your cloud storage, restore preferences by running `mackup restore`
7. Restart your computer to finalize the process

Your Mac is now ready to use!

> You can use a different location than `~/.dotfiles` if you want. Make sure you also update the reference in the [`.zshrc`](./.zshrc) file.

### Cleaning your old Mac (optionally)

After you've set up your new Mac you may want to wipe and clean install your old Mac. Follow [this article](https://support.apple.com/guide/mac-help/erase-and-reinstall-macos-mh27903/mac) to do that. Remember to [backup your data](#backup-your-data) first!

## Key Components

| File/Directory | Purpose |
|----------------|---------|
| `.zshrc` | Main shell config (~60ms startup) |
| `.zshenv` | Environment variables and PATH |
| `Brewfile` | All packages and casks |
| `fresh.sh` | New machine setup script |
| `functions/dev-tools.zsh` | Custom shell functions |
| `starship.toml` | Prompt configuration |
| `.macos` | macOS system preferences |

### Stack

- **Shell**: Zsh with [Starship](https://starship.rs/) prompt (no Oh My Zsh)
- **Package Manager**: [Homebrew](https://brew.sh/)
- **PHP**: [Laravel Herd](https://herd.laravel.com/) (also manages Node via NVM)
- **JavaScript Runtime**: [Bun](https://bun.sh/)
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
