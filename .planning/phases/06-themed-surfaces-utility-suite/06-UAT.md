---
status: complete
phase: 06-themed-surfaces-utility-suite
source: [06-VERIFICATION.md]
started: 2026-07-12T23:23:28Z
updated: 2026-07-13T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. hyprlock placeholder-text contrast under a light theme
test: Switch to a light theme (e.g. rosepine-dawn or tokyonight-day), lock the screen, and inspect the password-field placeholder text contrast. (Follow the documented lockout-recovery procedure: second TTY logged in before testing.)
expected: Placeholder text is legible against the themed input field in both light and dark themes
result: pass

### 2. Live smoke test — capture/record/pickers/SwayOSD with tools installed
test: On a machine with hyprshot, satty, gpu-screen-recorder, hyprpicker, wtype, and swayosd actually installed (fresh install.sh run) and a live Hyprland session, exercise each Print-key capture, Alt+Print region/monitor recording, Super+X color pick, a volume/mute/mic-mute key press, and a caps-lock press
expected: Each Print-key capture opens satty with the frozen screenshot; recordings (monitor and drag-selected region) start/stop with a notification; color picker copies a hex and shows a swatch; volume/mute/mic-mute keys show a themed SwayOSD pill and perform the audio change; caps-lock shows the pill with no keybind
result: issue
reported: "Color picker is a pass. SwayOSD is a pass. Caps lock shows the pill with no keybind. The 'Print' family shortcuts do not work on my keyboard. I tried running all the recording/screenshot scripts through terminal, they worked with some issues. The video recorder passed and saved in the expected directory. But in order to open the videos through VLC player, I needed to install the package 'vlc-plugins-all' so that vlc can decode the video format. The screenshot scripts save the picture to home directory (~) and not inside ~/Pictures/screenshots. When I run the screenshot scripts through terminal, I get: getopt: option requires an argument -- 'r' / Error: Unrecognized image file format / Error: Unrecognized image file format"
severity: major

## Summary

total: 2
passed: 1
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Print-family keybinds (Print / Shift+Print / Alt+Print etc.) trigger the capture/recording scripts"
  status: failed
  reason: "User reported: The 'Print' family shortcuts do not work on my keyboard (scripts work when run manually from a terminal)"
  severity: major
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Screenshot scripts save captures into ~/Pictures/screenshots and run without errors"
  status: failed
  reason: "User reported: screenshots save to home directory (~) instead of ~/Pictures/screenshots; running the scripts in a terminal prints 'getopt: option requires an argument -- r' and 'Error: Unrecognized image file format' (twice)"
  severity: major
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Recorded videos are playable out of the box on a fresh install (install.sh provides required codecs)"
  status: failed
  reason: "User reported: recordings saved to the expected directory but VLC could not decode them until 'vlc-plugins-all' was installed manually — package missing from install.sh"
  severity: minor
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
