---
status: testing
phase: 06-themed-surfaces-utility-suite
source: [06-VERIFICATION.md]
started: 2026-07-12T23:23:28Z
updated: 2026-07-12T23:23:28Z
---

## Current Test

number: 1
name: hyprlock placeholder-text contrast under a light theme
expected: |
  Placeholder text is legible against the themed input field in both light and dark themes
awaiting: user response

## Tests

### 1. hyprlock placeholder-text contrast under a light theme
test: Switch to a light theme (e.g. rosepine-dawn or tokyonight-day), lock the screen, and inspect the password-field placeholder text contrast. (Follow the documented lockout-recovery procedure: second TTY logged in before testing.)
expected: Placeholder text is legible against the themed input field in both light and dark themes
result: [pending]

### 2. Live smoke test — capture/record/pickers/SwayOSD with tools installed
test: On a machine with hyprshot, satty, gpu-screen-recorder, hyprpicker, wtype, and swayosd actually installed (fresh install.sh run) and a live Hyprland session, exercise each Print-key capture, Alt+Print region/monitor recording, Super+X color pick, a volume/mute/mic-mute key press, and a caps-lock press
expected: Each Print-key capture opens satty with the frozen screenshot; recordings (monitor and drag-selected region) start/stop with a notification; color picker copies a hex and shows a swatch; volume/mute/mic-mute keys show a themed SwayOSD pill and perform the audio change; caps-lock shows the pill with no keybind
result: [pending]

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
