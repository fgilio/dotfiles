#!/bin/bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"

echo "Setting up your Mac..."

# Check for Homebrew and install if we don't have it
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Only add if not already present (idempotent)
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"$HOME/.zprofile"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Symlink shell config files (ln -sf overwrites safely, no rm -rf needed)
ln -sf "$DOTFILES/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES/.zshenv" "$HOME/.zshenv"
ln -sf "$DOTFILES/.gitconfig" "$HOME/.gitconfig"

# Install FormatTranscription.app (on-device LLM markdown formatter)
# .app wrapper needed for TCC/FoundationModels access from Quick Actions.
# Built from source instead of shipping a committed Mach-O nobody can verify;
# swiftc comes with the Xcode CLT, which the Homebrew installer already set up
"$DOTFILES/apps/format-transcription/build.sh"
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/FormatTranscription.app"
cp -R "$DOTFILES/apps/format-transcription/build/FormatTranscription.app" "$HOME/Applications/"

# Symlink Starship config
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"

# Symlink Ghostty config and themes (ghostty.config references themes by name,
# so without the themes dir a fresh machine can't resolve "Hyper Light"/"Hyper")
mkdir -p "$HOME/.config/ghostty"
ln -sf "$DOTFILES/ghostty.config" "$HOME/.config/ghostty/config"
ln -sfn "$DOTFILES/ghostty/themes" "$HOME/.config/ghostty/themes"

# Symlink Hammerspoon config. Glob instead of per-file lines so a new module
# can't be forgotten; per-file symlinks (not a whole-dir link) so Hammerspoon's
# own writes (Spoons/, state) never land inside the repo tree.
mkdir -p "$HOME/.hammerspoon"
for f in "$DOTFILES/hammerspoon/"*.lua; do
  ln -sf "$f" "$HOME/.hammerspoon/"
done

# Create ~/tmp for ocr alias and other temp operations
mkdir -p "$HOME/tmp"

# Pre-download whisper model for Transcribe Audio Quick Action (~466MB)
WHISPER_MODEL="$HOME/.local/share/whisper-cpp/ggml-small.bin"
# Pinned huggingface LFS hash; fail closed (errexit) on mismatch so a tampered
# or truncated download never gets installed
WHISPER_MODEL_SHA256="1be3a9b2063867b937e64e2ec7483364a79917e157fa98c5d94b5c1fffea987b"
if [[ ! -f "$WHISPER_MODEL" ]]; then
  mkdir -p "$(dirname "$WHISPER_MODEL")"
  curl -fL --retry 3 --retry-delay 2 \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin" \
    -o "$WHISPER_MODEL.tmp"
  echo "$WHISPER_MODEL_SHA256  $WHISPER_MODEL.tmp" | shasum -a 256 -c -
  mv "$WHISPER_MODEL.tmp" "$WHISPER_MODEL"
fi

# Install Automator workflows (Quick Actions and Folder Actions)
mkdir -p "$HOME/Library/Services"
mkdir -p "$HOME/Library/Workflows/Applications/Folder Actions"
cp -R "$DOTFILES/workflows/Services/"*.workflow "$HOME/Library/Services/" 2>/dev/null || true
cp -R "$DOTFILES/workflows/Folder Actions/"*.workflow "$HOME/Library/Workflows/Applications/Folder Actions/" 2>/dev/null || true

# Attach Folder Action to Screenshots Runway (for screenshot/video optimization)
# Creates the folder if it doesn't exist and attaches the workflow
SCREENSHOTS_RUNWAY="$HOME/Pictures/Screenshots Runway"
mkdir -p "$SCREENSHOTS_RUNWAY"
osascript <<'APPLESCRIPT'
tell application "System Events"
    set folderPath to (POSIX file (do shell script "echo $HOME/Pictures/Screenshots\\ Runway")) as alias
    set workflowPath to (POSIX file (do shell script "echo $HOME/Library/Workflows/Applications/Folder\\ Actions/Optimize\\ and\\ Move\\ Screenshots.workflow")) as alias

    try
        attach action to folderPath using workflowPath
    end try

    -- Enable folder actions globally
    set folder actions enabled to true
end tell
APPLESCRIPT

# Symlink hushlogin to suppress terminal login message
ln -sf "$DOTFILES/hushlogin" "$HOME/.hushlogin"

# Trust the specific third-party tap items we use before bundling.
# Homebrew now requires explicit trust for third-party taps; we trust only the
# exact formula/cask we need (not whole taps) so the bundle install doesn't halt.
# laravel/moat repo lacks the `homebrew-` prefix; short form 404s, URL required.
brew tap laravel/moat https://github.com/laravel/moat && brew trust --formula laravel/moat/moat
brew tap modem-dev/tap && brew trust --formula modem-dev/tap/hunk
brew tap steipete/tap && brew trust --cask steipete/tap/codexbar
brew tap teamookla/speedtest && brew trust --formula teamookla/speedtest/speedtest

# Install all dependencies with bundle (See Brewfile)
# Includes: starship, zoxide, btop, fzf, fd, zsh-autosuggestions, coreutils, etc.
brew bundle --file "$DOTFILES/Brewfile"

# Install git hooks (idempotent, safe to re-run)
if [[ -d "$DOTFILES/.git" ]]; then
  lefthook install
fi

# Create Sublime Text terminal launcher (subl, not sublime)
mkdir -p "$HOME/.local/bin"
if [[ -d "/Applications/Sublime Text.app" ]]; then
  ln -sf "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" "$HOME/.local/bin/subl"
fi

# Create Zed terminal launcher
if [[ -d "/Applications/Zed.app" ]]; then
  ln -sf /Applications/Zed.app/Contents/MacOS/cli "$HOME/.local/bin/zed"
fi

# Claude Code via native installer, NOT the brew cask: the cask lags behind
# releases and disables self-update; the native install (~/.local/bin/claude)
# keeps itself on the latest version automatically
if ! command -v claude &>/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# Bun via official installer, NOT Homebrew: the formula trails upstream releases
# by hours to days, and a brew-managed bun rejects `bun upgrade`
if ! command -v bun &>/dev/null; then
  zshrc_was_clean=$(git -C "$DOTFILES" status --porcelain .zshrc)
  curl -fsSL https://bun.sh/install | bash
  # The installer appends its own completions block to .zshrc, which symlinks into
  # tracked source. Ours is already zcompiled, so restore the file when we can.
  if [[ -z "$zshrc_was_clean" ]]; then
    git -C "$DOTFILES" checkout -- .zshrc
  fi
fi

# Codex via the standalone installer, NOT the brew cask or a bun global: the
# cask trails releases, and `codex upgrade` only works on a standalone install.
# CODEX_NON_INTERACTIVE stops it prompting to uninstall a rival install or to
# launch the TUI in the middle of setup.
if ! command -v codex &>/dev/null; then
  curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=true sh
fi

# opencode has no Homebrew formula, so the official installer is the only route
# (~/.opencode/bin, upgrade with `opencode upgrade`). --no-modify-path: it would
# otherwise append its own PATH export to .zshrc, which symlinks into tracked
# source; .zshenv already has the entry. The installer resolves the version
# through the unauthenticated GitHub API, so it can fail with "Failed to fetch
# version information" when that hourly limit is spent; rerunning later works.
if ! command -v opencode &>/dev/null; then
  curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
fi

# qmd index refresh: daily launchd job, notifies on failure only
# Plist is copied (not symlinked) because launchd is unreliable with symlinked plists
ln -sf "$DOTFILES/bin/qmd-refresh" "$HOME/.local/bin/qmd-refresh"
cp "$DOTFILES/launchagents/com.fgilio.qmd-refresh.plist" "$HOME/Library/LaunchAgents/"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.fgilio.qmd-refresh.plist" 2>/dev/null || true

# Zed buffer backup: half-hourly snapshot of unsaved buffers and tab lists.
# bin/zed-buffer-backup is already on PATH via $DOTFILES/bin, so no symlink here.
cp "$DOTFILES/launchagents/com.fgilio.zed-buffer-backup.plist" "$HOME/Library/LaunchAgents/"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.fgilio.zed-buffer-backup.plist" 2>/dev/null || true

# Herd handles PHP and extensions

# Install global Composer packages
# Let Composer infer constraints from the latest compatible CLI releases.
if command -v composer &>/dev/null; then
  composer global require \
    beyondcode/expose \
    cpx/cpx \
    humbug/box \
    laravel/cloud-cli \
    laravel/forge-cli \
    laravel/installer
fi

# Symlink the Mackup config file to the home directory
ln -sf "$DOTFILES/.mackup.cfg" "$HOME/.mackup.cfg"

# Install utiluti for managing default apps (not in Homebrew)
# https://github.com/scriptingosx/utiluti (signed and notarized pkg)
if ! command -v utiluti &>/dev/null; then
  UTILUTI_VERSION="1.3"
  # Pinned release hash, verified before handing the pkg to `sudo installer`;
  # mktemp avoids a predictable /tmp path another local process could swap
  # between download and install
  UTILUTI_SHA256="f79d904b3af70bb255d3c095c82b1cdfc31c6884b83bbc9d2bcafd53c5cdf9ea"
  UTILUTI_DIR="$(mktemp -d)"
  UTILUTI_PKG="$UTILUTI_DIR/utiluti-${UTILUTI_VERSION}.pkg"
  curl -fsSL "https://github.com/scriptingosx/utiluti/releases/download/v${UTILUTI_VERSION}/utiluti-${UTILUTI_VERSION}.pkg" -o "$UTILUTI_PKG"
  echo "$UTILUTI_SHA256  $UTILUTI_PKG" | shasum -a 256 -c -
  sudo installer -pkg "$UTILUTI_PKG" -target /
  rm -rf "$UTILUTI_DIR"
fi

# Set default apps using utiluti (Sublime for text/code, VLC for video, etc.)
if command -v utiluti &>/dev/null; then
  utiluti manage --type-file "$DOTFILES/default-apps.plist" --url-file "$DOTFILES/default-urls.plist"
fi

# Editor config (VSCode symlinks + shared extension installs)
source "$DOTFILES/setup/editors.sh"

# Set macOS preferences last because this reloads the shell
# Disable errexit for .macos since many defaults commands exit non-zero on reruns
set +e
# shellcheck source=/dev/null
source "$DOTFILES/.macos"
set -e
