#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Strip Padding
# @raycast.mode silent
# @raycast.packageName Clipboard

# Strips 2-space left padding from clipboard (Claude Code adds this to all output)
pbpaste | sed 's/^  //' | pbcopy
