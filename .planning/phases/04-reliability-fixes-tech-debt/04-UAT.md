---
status: complete
phase: 04-reliability-fixes-tech-debt
source: [04-VERIFICATION.md]
started: 2026-07-11T17:48:07Z
updated: 2026-07-11T18:17:40Z
---

## Current Test

[testing complete]

## Tests

### 1. D-22 wlogout 5-cycle shutdown/reboot reliability test
expected: From the wlogout menu, perform 5 consecutive real cycles alternating keyboard/mouse selection and Shutdown/Reboot. After each boot, grep `journalctl -b -1` for teardown-timeout signatures. Expected: 5/5 clean cycles, no black-screen hang, no 'stop-sigterm timed out' / nvidia_drm failure lines. (Also settles WR-01: whether hyprshutdown survives uwsm's session-cgroup teardown.)
result: pass

### 2. D-23 hyprlock 10-trial lock-and-type reliability test
expected: With a second TTY logged in, perform ~10 lock-then-immediately-type trials across both the manual-lock keybind and the idle-lock (`loginctl lock-session`) path. Expected: 100% first-try unlock, no dropped first character, no failed-auth loop.
result: issue
reported: "If I start typing the password immediately, hyprlock works just fine. But if I try to press 'ENTER' key and then type my password, it fails authentication and no characters get typed inside the password input box."
severity: major

### 3. D-24 container-gate rerun (verify/container-run.sh)
expected: Push this phase's commits to origin/main, then run `verify/container-run.sh` from the repo root. Expected: clean clone -> install.sh --core-only -> stow.sh -> theme-parity all pass; summary.log records overall=PASS. (Precondition: local main is ~37 commits ahead of origin/main — push required first.)
result: pass

### 4. New-kitty-window fish smoke check
expected: Open a new kitty window in normal daily use and observe the fastfetch greeting + oh-my-posh prompt + node tooling. Expected: fast, clean startup with a working prompt and node/npm/npx available. (Low-value reconfirmation — the clean-env probe already passed live.)
result: pass

## Summary

total: 4
passed: 3
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "After the lock screen activates, the very first keystrokes register — 100% first-try unlock across manual-lock keybind and idle-lock paths, no failed-auth loop"
  status: failed
  reason: "User reported: If I start typing the password immediately, hyprlock works just fine. But if I try to press 'ENTER' key and then type my password, it fails authentication and no characters get typed inside the password input box."
  severity: major
  test: 2
  artifacts: []  # Filled by diagnosis
  missing: []    # Filled by diagnosis
