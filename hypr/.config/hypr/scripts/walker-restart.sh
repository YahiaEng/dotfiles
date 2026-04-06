#!/usr/bin/env bash
# Restart Walker service to pick up new CSS

# Kill by command-line match (handles uwsm scope wrapping)
pkill -f "walker.*gapplication-service" 2>/dev/null
timeout 3 pkill -w -f "walker.*gapplication-service" 2>/dev/null
pkill -9 -f "walker.*gapplication-service" 2>/dev/null

# Also kill any standalone walker process
pkill -x walker 2>/dev/null

# Remove stale socket
rm -f "/run/user/$(id -u)/walker/walker.sock" 2>/dev/null

# Remove Walker's auto-generated default theme if it shadows my custome theme
rm -rf "$HOME/.local/share/walker/themes/rice" 2>/dev/null

# Small delay for cleanup
sleep 0.3

# Relaunch via uwsm
uwsm app -- walker --gapplication-service &
disown
