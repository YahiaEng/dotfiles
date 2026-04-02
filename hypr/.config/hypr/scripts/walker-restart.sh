#!/usr/bin/env bash
# Restart Walker service to pick up new CSS
# Walker caches CSS at startup — must fully kill and relaunch

# Kill walker and wait for it to die (up to 3s), force-kill if it hangs
timeout 3 pkill -w -x walker 2>/dev/null || pkill -9 -x walker 2>/dev/null

# Remove stale socket in case of unclean exit
rm -f "/run/user/$(id -u)/walker/walker.sock" 2>/dev/null

# Relaunch via uwsm
uwsm app -- walker --gapplication-service &
disown
