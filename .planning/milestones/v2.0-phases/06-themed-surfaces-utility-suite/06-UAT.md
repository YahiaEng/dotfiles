---
status: complete
phase: 06-themed-surfaces-utility-suite
source: [06-VERIFICATION.md]
started: 2026-07-13T05:10:00Z
updated: 2026-07-13T12:20:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Capture / annotate / record suite end-to-end (SHOT-01/02/03)
test: |
  Press each of Print / Shift+Print / Ctrl+Print and run the full
  capture -> satty annotate -> save+copy flow. Then press Alt+Print to
  record a drag-selected region, and again for a full monitor. Export a GIF
  from the resulting notification, and play the .mp4 back in VLC.
expected: |
  Every Print variant fires; satty opens on a frozen image; annotations work;
  the saved file lands in ~/Pictures/Screenshots (NOT the home directory) with
  one notification; recordings start/stop cleanly; the .mp4 plays in VLC
  without installing anything by hand; the exported GIF plays.
result: pass

### 2. wlogout redesign renders as the agreed compact centre bar (WLOG-01 / D-09)
test: |
  Trigger the power menu (wlogout). Look at the bar itself, the glyphs, and the
  blurred backdrop behind it.
expected: |
  wlogout opens as a compact horizontal bar centred on screen (not a full-screen
  grid of huge tiles); each button is a 72x72 tile with a 28px glyph centred
  inside it and 16px gaps between buttons; the desktop behind it is blurred with
  a light scrim; colours come from the active theme.
result: pass

## Summary

total: 2
passed: 2
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Print-family keybinds (Print / Shift+Print / Alt+Print etc.) trigger the capture/recording scripts"
  status: resolved
  reason: "User reported: The 'Print' family shortcuts do not work on my keyboard (scripts work when run manually from a terminal)"
  severity: major
  test: 2
  root_cause: "Key-event layer failure, not config/deployment. The us XKB keymap defines <PRSC> as PC_ALT_LEVEL2 [Print, Sys_Req], so 'bind = ALT, Print' can never fire — Alt+PrtSc delivers keysym Sys_Req, which matches no bind."
  resolved_by: "06-14 — Print-family rebound to physical keycode (code:107), bypassing keysym translation entirely. Verified present at keybinds.conf:65-68."
  debug_session: ".planning/debug/print-keybinds-not-firing.md"

- truth: "Screenshot scripts save captures into ~/Pictures/Screenshots and run without errors"
  status: resolved
  reason: "User reported: screenshots save to home directory (~) instead of ~/Pictures/Screenshots; terminal runs printed 'getopt: option requires an argument -- r' and 'Error: Unrecognized image file format' twice"
  severity: major
  test: 2
  root_cause: "hyprshot 1.3.0 optstring bug: short options declare 'r:' (argument-required) while --raw is boolean. getopt errored and dropped the flag, so hyprshot proceeded with RAW=0, saved the PNG itself to ~ (SAVEDIR fallback, xdg-user-dirs absent), and wrote nothing to stdout — leaving satty with empty stdin."
  resolved_by: "06-14 — all three capture scripts switched from '-r' to the long form '--raw' (verified at capture-{region,full,window}.sh); SCREENSHOT_DIR pinned to $HOME/Pictures/Screenshots. 06-15 — xdg-user-dirs added to install.sh."
  debug_session: ".planning/debug/screenshot-script-errors.md"

- truth: "Recorded videos are playable out of the box on a fresh install (install.sh provides required codecs)"
  status: resolved
  reason: "User reported: recordings saved correctly but VLC could not decode them until 'vlc-plugins-all' was installed by hand"
  severity: minor
  test: 2
  root_cause: "Arch's vlc 3.0.23_2 packaging splits codec plugins into vlc-plugins-* packages; install.sh had no vlc entry at all, so a fresh install had no player able to decode gpu-screen-recorder output."
  resolved_by: "06-15 — vlc and vlc-plugins-all added to install.sh PACMAN_PKGS (verified present)."
  debug_session: ""
