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

# Ensure dotfiles bin directory scripts are executable
chmod +x "$DOTFILES/bin/"*

# Install FormatTranscription.app (on-device LLM markdown formatter)
# Pre-built .app wrapper needed for TCC/FoundationModels access from Quick Actions
# Rebuild with: apps/format-transcription/build.sh
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

# Symlink Hammerspoon config
mkdir -p "$HOME/.hammerspoon"
ln -sf "$DOTFILES/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"

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

# Install all dependencies with bundle (See Brewfile)
# Includes: starship, zoxide, btop, fzf, fd, zsh-autosuggestions, coreutils, etc.
brew bundle --file "$DOTFILES/Brewfile"

# Install git hooks (idempotent, safe to re-run)
if [[ -d "$DOTFILES/.git" ]]; then
  lefthook install
fi

# Install fzf key bindings and completion (no shell rc modifications)
if [[ -x /opt/homebrew/opt/fzf/install ]]; then
  /opt/homebrew/opt/fzf/install --key-bindings --completion --no-update-rc
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

# Herd handles PHP and extensions

# Install global Composer packages
if command -v composer &>/dev/null; then
  composer global require laravel/installer beyondcode/expose ymirapp/cli
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

# Set default apps using utiluti (Zed for text/code, VLC for video, etc.)
if command -v utiluti &>/dev/null; then
  utiluti manage --type-file "$DOTFILES/default-apps.plist" --url-file "$DOTFILES/default-urls.plist"
fi

# Editor config (VSCode symlinks + shared extension installs)
source "$DOTFILES/setup/editors.sh"

# xdr-boost (XDR display brightness booster)
source "$DOTFILES/setup/xdr-boost.sh"

# Set macOS preferences last because this reloads the shell
# Disable errexit for .macos since many defaults commands exit non-zero on reruns
set +e
# shellcheck source=/dev/null
source "$DOTFILES/.macos"
set -e
