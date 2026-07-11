---
phase: 04-reliability-fixes-tech-debt
plan: 02
subsystem: hyprlock (screen lock / authentication)
tags: [hyprlock, hypridle, uwsm, grace-period, keystroke-drop]

status: in-progress
---

# Phase 4 Plan 2: Hyprlock First-Keystroke Drop (FIX-02) Summary

**IN PROGRESS — this document is being built incrementally across the plan's tasks. Task 1 (lockout-recovery procedure + diagnosis capture harness) is complete; Tasks 2-4 (human-verify checkpoints + the grace=0 fix) have not run yet.**

## Task 1: Lockout-Recovery Procedure and Diagnosis Capture Harness

### Lockout-recovery procedure

Written BEFORE any hyprlock test in this phase, per D-20. This procedure is intentionally
generic/reusable — Phase 6 (LOCK-01) reuses it verbatim.

**Before testing any lock-screen change:**

1. **Log into a second TTY first.** Switch with `Ctrl+Alt+F2` (or F3/F4 — any free VT),
   sign in with your normal user credentials at the text login prompt. Keep this session
   open and logged in for the entire duration of hyprlock testing. Do not log out of it
   until testing is finished.
2. **Return to the graphical session** with `Ctrl+Alt+F1` (or whichever VT Hyprland/uwsm
   is running on — typically VT1).
3. **If the lock screen becomes unresponsive or a real lockout occurs** (password not
   accepted, screen frozen, no keyboard response), switch back to the second TTY
   (`Ctrl+Alt+F2`) using the already-authenticated session and run the escape hatch:
   ```bash
   pkill hyprlock
   ```
   This kills the hung/misbehaving hyprlock process from outside the locked session,
   which immediately returns the graphical session to its unlocked state (Hyprland does
   not re-lock automatically after a killed hyprlock process).
4. **Restore a working session:** after `pkill hyprlock`, switch back to `Ctrl+Alt+F1` —
   the desktop should be usable again. If hyprlock needs to be tested again, simply
   re-trigger the lock (keybind, menu action, or `loginctl lock-session`) once ready.
5. **Never test a lock-screen config change without step 1 done first.** A second TTY
   with an already-authenticated shell is the only guaranteed way to recover from a
   stuck/broken lock screen without a hard power cycle.

### Diagnosis capture procedure (#423 signature)

This autonomous task does **not** lock the screen — the actual lock-and-observe step is
deliberately deferred to the Task 2 human checkpoint, so a real person is present with the
second-TTY safety net already in place before any lock test happens.

**Pre-flight confirmation (done in this task, no lock triggered):**

- Confirmed `hyprlock` is version `0.9.5-4` (via `pacman -Q hyprlock`) — matches the
  research finding that the upstream fix PR (`hyprwm/hyprlock#424`) is not yet in this
  build.
- Confirmed current `hyprlock.conf` `general{}` block still has `grace = 5` (unchanged;
  see `hypr/.config/hypr/hyprlock.conf` lines 7-12) — this task did not modify it.
- Confirmed `hyprlock --help` lists `--grace`/`-g [int]` and notes `--immediate` is
  "[Deprecated] (Use `--grace 0` instead)" — corroborates that `grace = 0` is the
  currently-supported, non-deprecated way to disable the grace period.
- Checked for an existing systemd/journald unit scope for hyprlock
  (`journalctl --user -u app-hyprlock*`) — no matches. Hyprlock is invoked directly
  (`uwsm app -- hyprlock` / `pidof hyprlock || hyprlock`), not as its own systemd
  unit, so there is no journald unit-scoped log to grep after the fact.
- Checked `~/.cache/hyprlock/` — does not exist on this machine. Hyprlock does **not**
  write a log file here by default; verbose output only goes to **stderr of the
  invoking terminal** when run with `-v`/`--verbose`.

**Where hyprlock logs, and how the human should capture it (for Task 2):**

Hyprlock has no persistent log file and no dedicated systemd unit scope on this
machine. The only way to capture verbose diagnostic output is to run it in the
**foreground of an interactive terminal** with `-v`:

```bash
uwsm app -- hyprlock -v
```

This blocks the terminal and streams verbose logs to stderr for as long as the lock
screen is up. The human should keep this terminal visible/scrollback-accessible (or
redirect to a file, e.g. `uwsm app -- hyprlock -v 2>&1 | tee /tmp/hyprlock-grace5.log`)
so the output can be grepped afterward.

**The exact signature to grep for** (from `hyprwm/hyprlock#423` — "Grace cause fail
auth"):

```
In grace and cursor moved more than 5px, unlocking!
```
immediately followed by:
```
Unlock already happend?
```
(sic — the upstream log message itself contains this typo; grep for it verbatim, not
"happened").

**Confirmed symptom fingerprint match (D-17):** the reported drop happens right after a
**manual** lock (keybind/menu → type immediately), not on idle/resume wake — this is
exactly the fingerprint hyprwm/hyprlock#423 describes (the grace-period unlock routine
racing with the very first real input events after lock).

Task 2 (human checkpoint) will run this capture procedure live, report whether the two
log lines above appear, and confirm whether the keystroke drop reproduces.

### Files confirmed unchanged in this task

- `hypr/.config/hypr/hyprlock.conf` — no changes (grace is still 5; git diff will show
  only this SUMMARY.md added)
- `hypr/.config/hypr/hypridle.conf` — no changes
