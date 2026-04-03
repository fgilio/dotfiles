#!/bin/bash
# xdr-boost: XDR display brightness booster (not in Homebrew)
# https://github.com/levelsio/xdr-boost

if ! command -v xdr-boost &> /dev/null; then
  XDR_BOOST_DIR="/tmp/xdr-boost"
  git clone https://github.com/levelsio/xdr-boost.git "$XDR_BOOST_DIR"
  make -C "$XDR_BOOST_DIR" build
  sudo install -m 755 "$XDR_BOOST_DIR/.build/xdr-boost" /usr/local/bin/xdr-boost
  rm -rf "$XDR_BOOST_DIR"
fi

# Set up launch agent (auto-start on login)
if [[ ! -f "$HOME/Library/LaunchAgents/com.xdr-boost.agent.plist" ]]; then
  XDR_PLIST_DIR="/tmp/xdr-boost-plist"
  git clone --depth 1 https://github.com/levelsio/xdr-boost.git "$XDR_PLIST_DIR" 2>/dev/null || true
  if [[ -f "$XDR_PLIST_DIR/com.xdr-boost.agent.plist" ]]; then
    mkdir -p "$HOME/Library/LaunchAgents"
    sed "s|__BINARY__|/usr/local/bin/xdr-boost|g" "$XDR_PLIST_DIR/com.xdr-boost.agent.plist" \
      > "$HOME/Library/LaunchAgents/com.xdr-boost.agent.plist"
    launchctl load "$HOME/Library/LaunchAgents/com.xdr-boost.agent.plist"
  fi
  rm -rf "$XDR_PLIST_DIR"
fi
