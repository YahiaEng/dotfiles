# Deferred Items — Phase 15 (Audio + Connectivity Panels)

Pre-existing issues discovered during 15-11's Task 3 gate sweep that are out
of this plan's scope (Scope Boundary rule: only fix issues directly caused by
this task's changes — none of 15-11's three tasks touch any Hyprland
keybind/config file).

## 1. `hypr-equivalence-check`'s `binds.json` gate fails — pre-existing, from plan 15-02

**STATUS: OPEN, not caused by 15-11.**

**Found during:** 15-11 Task 3's mandated full gate sweep (`theme-doctor`,
which folds in `hypr-equivalence-check`).

**Symptom:** `theme-doctor` reports `[FAIL] hypr-equivalence-check: binds.json:
differs from baseline (structural comparison)`, alongside the two other
`hypr-equivalence-check` sub-checks (`animations.json`, `options.jsonl`)
passing clean. Overall `theme-doctor` tally: 260 passed, 1 failed.

**Root cause — confirmed independent of 15-11's own changes:** the committed
`.hypr-baseline/` snapshot pre-dates plan 15-02's Super+A keybind (`qs ipc
call panel toggle audio`, commit `5e6bf2d`, "tracer — Super+A summons audio
panel via guarded openPanel()"). Running `hypr-equivalence-check` directly
shows the live bind count is 81 vs. baseline 80, with the new `A` key
(modmask 64) accounting for the one-record delta:

```
[DIAGNOSTIC] true order-insensitive delta (15-field identity; dispatcher/arg/keycode/mouse excluded)
  + key='A' modmask=64 x1
  + key='mouse:272' modmask=64 x1
  + key='mouse:273' modmask=64 x1
  - key='mouse:272' modmask=64 x1
  - key='mouse:273' modmask=64 x1
! bind count mismatch: baseline=81 live=82
```

(The `mouse:272`/`mouse:273` add/remove pair is the ALREADY-documented,
already-accepted `{mouse=true}` bind-option divergence recorded since
13.1-04/13.1-08 — see PROJECT.md's Key Decisions table. The genuinely NEW
element here is the unaccounted `A` keybind.)

15-11 touches `theme-engine/lib/motion.sh`, `hypr/scripts/motion-lint`,
`quickshell/modules/Motion.qml`, `WifiBackend.qml`, `WifiPanel.qml`,
`BluetoothPanel.qml` and `15-UI-SPEC.md` — no Hyprland keybind/config file is
in this plan's `<files>` list for any task, and `git log` confirms
`keybinds.lua` was last touched by 15-02, several plans before this one.

**Why not fixed here:** re-snapshotting `.hypr-baseline/binds.json` to absorb
a keybind added by a *different, already-merged* plan is an architectural
bookkeeping task (whose baseline-update ceremony 14-10's own history records
as "surgical, one-record insertion, all pre-existing records proven
byte-identical, never a wholesale re-snapshot") — out of 15-11's declared
scope and files.

**Recommendation for whoever picks this up:** re-run
`hypr-equivalence-check`'s baseline-update path (the same surgical,
proven-byte-identical insertion pattern 14-10 used for the Super+D chord) to
add the Super+A `A`/modmask=64 record, without touching any other row and
without silently absorbing the still-open `{mouse=true}` divergence.
