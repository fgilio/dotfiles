#!/usr/bin/env bash
set -euo pipefail

# Builds SublimeSessionBackup.app - a background-only launcher that runs
# bin/sublime-session-backup with an app's TCC identity (see main.swift).
# No Xcode project needed, just swiftc + codesign.

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT/build/SublimeSessionBackup.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"

SDK="$(xcrun --sdk macosx --show-sdk-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"

cp "$ROOT/Info.plist" "$APP_DIR/Contents/Info.plist"

swiftc \
  -parse-as-library \
  -O \
  -target arm64-apple-macos26.0 \
  -sdk "$SDK" \
  "$ROOT/main.swift" \
  -o "$MACOS_DIR/SublimeSessionBackup"

codesign --force --sign - "$APP_DIR"

echo "Built: $APP_DIR"
