---
created: 2026-08-13T11:21:59.666Z
title: Reset stale idle intent at session start (bar hidden after crash/reboot)
area: tooling
severity: blocker
files:
  - hypr/.config/hypr/config/autostart.lua:152
  - hypr/.config/hypr/scripts/bar-visibility.sh
  - hypr/.config/hypr/hypridle.conf
---

## Problem

The bar-visibility intent files under `~/.cache/bar-visibility.d/` persist across
reboots by design (D-18-27), but the `idle` source is owned by hypridle, whose
state resets every session: `on-resume` (`bar-visibility.sh idle show`) can only
fire after an `on-timeout` in the *same* hypridle session. When a session crashes
while idle-hidden (observed 2026-08-13: hyprlock SIGABRT at 13:15 took down
hypridle mid-idle with `idle=hide` on disk), the next boot's startup resync
faithfully re-applies the stale intent and the bar stays `hidden-idle` while the
user is actively working — nothing can clear it until the next full
idle→resume cycle. Live recovery was `bar-visibility.sh idle show`.

## Solution

Declare `idle show` through the owner script at session start (autostart.lua,
before hypridle launches) — a fresh session is non-idle by definition. The
declare path writes the intent file even if the Quickshell IPC actuation fails
(shell may not be up yet); shell.qml's startup reassert then reads fresh state.

Same-class follow-up (NOT fixed here): `wallpaper-visibility.sh` has the
identical idle-intent model via hypridle's 300s listener; a stale
`idle=hide` would keep the live wallpaper torn down after a crash-reboot.
Excluded because actuating "show" at session start could race theme-init's
wallpaper startup — needs its own look. Gaming intent is a deliberate
persistent toggle (`~/.cache/gaming-mode`) and is correctly left alone.

Separate follow-up: hyprlock SIGABRT coredump (13:15:03, 2026-08-13) available
via `coredumpctl` for a post-mortem of the original crash.
