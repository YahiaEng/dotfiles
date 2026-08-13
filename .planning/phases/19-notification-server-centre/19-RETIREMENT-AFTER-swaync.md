---
phase: 19-notification-server-centre
plan: 8
artifact: retirement-after
surface: swaync
captured: 2026-08-13
captured_at_commit: 54fe33d30be5f95f6680e6e35e3e5b09383e0c8e
command: "retirement-check swaync"
exit_code: 0
paired_baseline: .planning/phases/19-notification-server-centre/19-RETIREMENT-BASELINE-swaync.md
---

# Swaync Post-Deletion Retirement After-Run

Complete, verbatim output of `retirement-check swaync` captured against
commit `54fe33d30be5f95f6680e6e35e3e5b09383e0c8e` — after Task 4's atomic autostart swap (`d4bb0f6`-class,
see git log), Task 5's repo-side removal commit (`54fe33d`), and the
host-side `sudo pacman -Rns swaync` uninstall the user ran directly. The
registry row reads `retired` at capture time, arming the blocking tier.
This is the "after" half of RETIRE-03's twice-run gate, paired with
`19-RETIREMENT-BASELINE-swaync.md`'s "before" half.

## Result: 13 PASS / 1 architectural SKIP / 0 FAIL — `failed_classes=0`, exit 0

Every one of the 13 blocking-domain classes reports zero references. The
single SKIP is architectural and identical in kind to waybar's own
after-run: `own-tree` skips because the paths it watches
(`swaync/`, `hypr/.config/hypr/scripts/swaync-*`) no longer exist — which
is the deletion having succeeded, not a check that failed to run.

The two REPORT-domain classes are non-blocking by design and are expected
to stay non-zero permanently:

- **planning-archive (1681)** — the phase/milestone planning record, which
  documents the daemon's entire life and retirement. Scrubbing it would
  destroy the audit trail this checklist exists to support.
- **repo-prose (13)** — README.md, VERIFICATION.md, `.claude/CLAUDE.md`,
  `env.lua` and `verify/container-run.sh`. Same disposition waybar's
  after-run took for its own 37.

### Before → after, per blocking class

| # | Class | Before (baseline) | After | Verdict |
|---|-------|------------------:|------:|---------|
| 1 | own-tree | 20 | — | **[SKIP]** paths gone |
| 2 | layer-window-rules | 4 | 0 | [PASS] |
| 3 | autostart | 1 | 0 | [PASS] |
| 4 | keybinds | 0 | 0 | [PASS] |
| 5 | contract-json | 2 | 0 | [PASS] |
| 6 | matugen-templates | 5 | 0 | [PASS] |
| 7 | checker-internals | 7 | 0 | [PASS] |
| 8 | test-fixtures | 15 | 0 | [PASS] |
| 9 | cross-package-refs | 37 | 0 | [PASS] |
| 10 | install-stow-lists | 18 | 0 | [PASS] |
| 11 | systemd-units | 4 | 0 | [PASS] |
| 12 | dbus-activation | 2 | 0 | [PASS] |
| 13 | xdg-autostart | 0 | 0 | [PASS] |
| 14 | host-package | 1 | 0 | [PASS] |

Class 6 fell to 0 rather than the 1 the baseline predicted: the baseline
recorded `swayosd-colors.css:3` as an out-of-scope token-boundary false
positive, but it is a prose mention of a now-deleted daemon inside a
comment, and it is a blocking-class hit — so it was scrubbed rather than
carried, which is the deviation recorded in `54fe33d`.

Class 12 (`dbus-activation`) is the one that mattered most for
correctness: `org.erikreider.swaync.service` declared
`Name=org.freedesktop.Notifications` with `SystemdService=swaync.service`,
meaning the notification bus name itself remained D-Bus-activatable back
onto the old daemon for as long as the package stayed installed. Both
activation files left with `pacman -Rns`, so that path is now closed.

## Verbatim output

```
retirement-check — surface=swaync status=retired root=/home/aorus/dotfiles

[SKIP] swaync/own-tree: own-tree path(s) not present under /home/aorus/dotfiles: swaync/:hypr/.config/hypr/scripts/swaync-*
[PASS] swaync/layer-window-rules: no references
[PASS] swaync/autostart: no references
[PASS] swaync/keybinds: no references
[PASS] swaync/contract-json: no references
[PASS] swaync/matugen-templates: no references
[PASS] swaync/checker-internals: no references
[PASS] swaync/test-fixtures: no references
[PASS] swaync/cross-package-refs: no references
[PASS] swaync/install-stow-lists: no references
[PASS] swaync/systemd-units: no references
[PASS] swaync/dbus-activation: no references
[PASS] swaync/xdg-autostart: no references
[PASS] swaync/host-package: no references
[REPORT] swaync/planning-archive: 1681 reference(s)
[REPORT] swaync/repo-prose: 13 reference(s)

Summary: surface=swaync status=retired failed_classes=0
```
