#!/usr/bin/env bash
set -euo pipefail

# Builds FormatTranscription.app - a background-only macOS app that formats
# raw transcription text into Markdown using Apple's on-device LLM.
# No Xcode project needed, just swiftc + codesign.

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT/build/FormatTranscription.app"
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
    -o "$MACOS_DIR/FormatTranscription"

codesign --force --sign - "$APP_DIR"

echo "Built: $APP_DIR"
