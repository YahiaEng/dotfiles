---
status: testing
phase: 04-reliability-fixes-tech-debt
source: [04-VERIFICATION.md]
started: 2026-07-11T17:48:07Z
updated: 2026-07-11T17:48:07Z
---

## Current Test

number: 1
name: D-22 wlogout 5-cycle shutdown/reboot reliability test
expected: |
  5/5 clean cycles, no black-screen hang, no 'stop-sigterm timed out' / nvidia_drm failure lines.
awaiting: user response

## Tests

### 1. D-22 wlogout 5-cycle shutdown/reboot reliability test
expected: From the wlogout menu, perform 5 consecutive real cycles alternating keyboard/mouse selection and Shutdown/Reboot. After each boot, grep `journalctl -b -1` for teardown-timeout signatures. Expected: 5/5 clean cycles, no black-screen hang, no 'stop-sigterm timed out' / nvidia_drm failure lines. (Also settles WR-01: whether hyprshutdown survives uwsm's session-cgroup teardown.)
result: [pending]

### 2. D-23 hyprlock 10-trial lock-and-type reliability test
expected: With a second TTY logged in, perform ~10 lock-then-immediately-type trials across both the manual-lock keybind and the idle-lock (`loginctl lock-session`) path. Expected: 100% first-try unlock, no dropped first character, no failed-auth loop.
result: [pending]

### 3. D-24 container-gate rerun (verify/container-run.sh)
expected: Push this phase's commits to origin/main, then run `verify/container-run.sh` from the repo root. Expected: clean clone -> install.sh --core-only -> stow.sh -> theme-parity all pass; summary.log records overall=PASS. (Precondition: local main is ~37 commits ahead of origin/main — push required first.)
result: [pending]

### 4. New-kitty-window fish smoke check
expected: Open a new kitty window in normal daily use and observe the fastfetch greeting + oh-my-posh prompt + node tooling. Expected: fast, clean startup with a working prompt and node/npm/npx available. (Low-value reconfirmation — the clean-env probe already passed live.)
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
