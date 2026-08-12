---
phase: quick-260812-n9b
plan: 01
subsystem: hypr/quickshell
tags: [systemd, socket2, watchdog, quickshell, bar-resilience]
status: complete
dependency-graph:
  requires: []
  provides:
    - "hypr/.config/hypr/scripts/bar-watchdog.sh"
    - "quickshell-bar-watchdog.service"
  affects:
    - "hypr/.config/hypr/config/autostart.lua"
    - "18-BAR-SOAK.md Section one's permanent-liveness process count (not edited by this plan — see below)"
tech-stack:
  added: []
  patterns:
    - "Reintroduced the retired socket2-listener pattern (python3 stdlib inline body, argv-list-only subprocess calls, EOF-break guard) for a defect the shell itself cannot self-report"
key-files:
  created:
    - hypr/.config/hypr/scripts/bar-watchdog.sh
    - hypr/.config/hypr/scripts/tests/test-bar-watchdog.sh
    - quickshell/.config/systemd/user/quickshell-bar-watchdog.service
  modified:
    - hypr/.config/hypr/config/autostart.lua
decisions:
  - "Added a startup log line to bar-watchdog.sh (connect-time announcement) not specified in the plan's action block, needed so the journal carries evidence of liveness even during the common silent case of zero monitor events — Rule 2 auto-fix, re-verified against the full fixture harness afterward."
metrics:
  duration: "~50min"
  completed: 2026-08-12
actuals:
  tokens: 8323
  tasks: 3
  commits: 3
---

# Quick Task 260812-n9b: Event-Driven Bar Watchdog Summary

One socket2 listener (`bar-watchdog.sh`), its fixture-driven test harness (8 proven cases,
A-H), a supervising systemd `--user` unit (`quickshell-bar-watchdog.service`), and one wired
autostart entry — together a workaround for WINDOWS.md row 67: a monitor removal/re-add
destroys the `quickshell-bar` layer surface while quickshell itself stays perfectly healthy and
keeps reporting the bar as visible.

## What Was Built

**Task 1 — `hypr/.config/hypr/scripts/bar-watchdog.sh` + `hypr/.config/hypr/scripts/tests/test-bar-watchdog.sh`.**
A long-running Hyprland socket2 listener mirroring the retired `waybar-fullscreen-watch.sh`
shape (inline `python3 - <<'PYEOF'` idiom, argv-list-only subprocess calls, EOF-break guard).
On `monitoradded`/`monitoraddedv2`/`monitorremoved`, it debounces (default 3s), then reads
`hyprctl layers -j` and checks for a layer whose `namespace` is EXACTLY `quickshell-bar` —
never a prefix/substring match, and never `bar-visibility.sh status` (which WINDOWS row 67
records printing a false `visible`). If genuinely absent, it runs
`systemctl --user restart quickshell.service`, rate-limited (default: 30s min interval, 3
restarts per 900s rolling window). An unreadable/non-JSON `hyprctl` read is INDETERMINATE and
never triggers a restart. Supports `--check` (one-shot, used by verification and by any future
diagnostic) and `--dry-run` (watch and log, never restart). All four tunables are env-overridable
so the test harness can compress them without editing the script under test.

The fixture harness proves all 8 required cases against a fixture AF_UNIX socket and
PATH-shimmed `hyprctl`/`systemctl` — never the real compositor or user manager — 23/23 checks
passing across repeated runs: event parse (A), the exact-match trap against live sibling
namespaces `quickshell-bar-hotzone`/`quickshell-bardrawer-audio` (B), present-is-left-alone (C),
recovery argv exactly `--user restart quickshell.service` (D), rate-limit suppression under
compressed tunables (E), fail-safe INDETERMINATE on both hyprctl exit-1 and non-JSON output (F),
ignored non-monitor events (G), and clean EOF-exit without spinning (H).

**Task 2 — `quickshell/.config/systemd/user/quickshell-bar-watchdog.service`.** Mirrors
`quickshell.service`'s documented choices point-for-point: no `[Install]` section (started
explicitly from `autostart.lua`, never `enable`d), `PartOf=`/`After=graphical-session.target`,
`Slice=app-graphical.slice`, `Restart=on-failure`/`RestartSec=2`,
`StartLimitIntervalSec=60`/`StartLimitBurst=5`. Deliberately NOT `PartOf=`/`BindsTo=quickshell.service`
— stated explicitly in the header, since this unit's entire job is to restart that unit.
Installed live via `stow -R quickshell` (the systemd user tree is a real directory with
per-file symlinks, unlike the folded `hypr/scripts` symlink) + `systemctl --user daemon-reload`
+ `systemctl --user start`. Verified live: `systemd-analyze verify` clean, `active (running)`
with `NRestarts=0` after 45s of real uptime, journal carries its output, and
`quickshell.service`'s own `ActiveState`/`NRestarts` unchanged throughout.

**Task 3 — `hypr/.config/hypr/config/autostart.lua`.** One new `hl.exec_cmd` entry
(`systemctl --user start quickshell-bar-watchdog.service`), placed immediately after the
`quickshell.service` start line (16 -> 17 total entries), with a comment block stating the
D-18-28 reversal and the D-15/D-35 carve-out directly in the file.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - missing critical functionality] Added a connect-time startup log line to
bar-watchdog.sh**
- **Found during:** Task 2's live verification — the plan's own verify step
  (`journalctl ... | grep -q 'bar-watchdog'`) failed against a freshly started unit because the
  script is otherwise completely silent until a monitor event fires, which had not happened yet.
- **Issue:** A watchdog that produces zero journal output for hours (the correct, common case —
  no monitor events) is unverifiable at a glance; there is no way to distinguish "watching
  correctly" from "silently dead" from the journal alone.
- **Fix:** Added one `log(...)` call right after the socket connects, in Task 1's file, before
  Task 2 was completed: `bar-watchdog: watching <socket> for monitor events (mode=...)`.
- **Files modified:** `hypr/.config/hypr/scripts/bar-watchdog.sh`
- **Commit:** b63cddb (bundled with Task 2's commit since it was discovered during that task's
  verification; the full fixture harness — 23/23 — was re-run afterward to confirm nothing
  regressed)

## Three Honesty Obligations (required by this plan's own `<output>` spec)

**1. This reverses D-18-28.** Plan 18-15 deleted this repo's standalone socket2 listener
(`waybar-fullscreen-watch.sh`) outright — its own commit language: "the standalone socket2
listener is deleted outright, not repointed — the fullscreen intent is now reported by the QML
shell itself." That was correct for that defect, because the shell could report its own
fullscreen intent. This plan reintroduces a standalone socket2 listener for a structurally
different reason: WINDOWS row 67's defect is that the shell is precisely the thing that fails —
it keeps reporting `bar: visibility=visible zone=reserved` while no surface exists, so it cannot
report its own outage. A self-healing mechanism cannot live inside the thing that needs healing;
it has to watch from outside. This is a genuine reversal of the pattern D-18-28 retired, not a
regression back into the same problem D-18-28 solved.

**2. This adds ONE permanent long-lived process to the desktop.** `18-BAR-SOAK.md` Section one
currently states the bar carries exactly one permanent child process (quickshell itself). After
this plan, that is no longer true — `quickshell-bar-watchdog.service` is a second permanent
process, supervised independently, running for the lifetime of every graphical session.
`18-BAR-SOAK.md` was deliberately NOT edited by this plan per its hard constraints. The
orchestrator should decide where this correction lands — most likely a small note in
`18-BAR-SOAK.md` Section one on its next legitimate touch, or a dedicated follow-up. QBAR-11's
soak accounting (WINDOWS row 67/68, still open pending a valid quiescent window) should also be
read with this second process in mind going forward.

**3. End-to-end recovery is UNPROVEN until the operator's display next sleeps.** Everything
verified in this plan is either fixture-driven (the 8-case harness, cases A-H) or a live read
against the current session (`--check` -> `present`, the unit's 45s real-uptime stability). The
actual monitor-removal -> surface-loss -> automatic-restore path — the real trigger this
watchdog exists for — has not been observed even once, because reproducing it is unsafe on this
host: WINDOWS row 14 records `quickshell-doctor`'s headless-output add/remove test previously
SEGV-crashing this compositor during a DP-1 hotplug. **WINDOWS row 67 stays OPEN.** This plan is
a workaround installed and armed, not a closed defect — the only way to close row 67 is to
observe a real monitor-sleep event recover the bar under this watchdog, which has not yet
happened.

## Self-Check: PASSED

- FOUND: `hypr/.config/hypr/scripts/bar-watchdog.sh` (executable, `bash -n` clean, python body
  compiles)
- FOUND: `hypr/.config/hypr/scripts/tests/test-bar-watchdog.sh` (executable, 23/23 passing
  across 3 consecutive runs)
- FOUND: `quickshell/.config/systemd/user/quickshell-bar-watchdog.service` (`systemd-analyze
  verify` clean, no `[Install]` section)
- FOUND: symlink `~/.config/systemd/user/quickshell-bar-watchdog.service` resolves into the repo
- FOUND: one new entry in `hypr/.config/hypr/config/autostart.lua` immediately after the
  `quickshell.service` start line; `hl.exec_cmd` count is 17 (was 16); file parses as Lua
- FOUND: commit f425ac3 (`git log --oneline -5` confirms)
- FOUND: commit b63cddb (`git log --oneline -5` confirms)
- FOUND: commit 59ec9ae (`git log --oneline -5` confirms)
- CONFIRMED: `Bar.qml`, `18-BAR-SOAK.md`, `18-GATE-02-RECORD.md`, `stow.sh`, `install.sh`,
  `waybar/` all show zero `git status --short` output (byte-unchanged)
- CONFIRMED: `quickshell.service` ends the plan `active`/`NRestarts=0`, unchanged from its
  starting state
- CONFIRMED: `quickshell-bar-watchdog.service` is `active (running)`, `NRestarts=0` after 45s
  real uptime
- CONFIRMED: `bar-watchdog.sh --check` prints `present`, exit 0, against the live session
- CONFIRMED: no `hyprctl reload`/`hyprctl eval`/`hyprctl dispatch 'hl.dsp.*'` was ever run this
  session
