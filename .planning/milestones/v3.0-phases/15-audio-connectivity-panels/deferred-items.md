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

---

## G-15-2 — Bluetooth device-list verification (pair / connect / disconnect / forget)

**Status:** CLOSED 2026-08-02 — the user supplied a real peer (Z Fold7) during UAT
round 2, and the device list was exercised end to end: discovery, pair, connect and
Forget all confirmed. Closed on its owner condition (hardware became available), not
at a phase boundary. Two findings surfaced on top of the working flow and are tracked
separately as G-15-8 (fixed) and G-15-7 (decided) in 15-UAT.md.
**Raised by:** 15-12 (G-15-2 gap closure), 2026-08-02
**Requirement:** PANEL-04

UAT test 2's device-list half — pair, connect, disconnect and forget against a real
peer — was never reachable, because the Enable button was inert on this host and the
panel could never reach a populated state at all. It stays unverified even after this
plan.

**This fix unblocks the test; it does not perform it.** 15-12 makes the blocked adapter
legible and stops the panel offering a control that cannot work, but the device-list
paths remain source-verified only.

The blocker is hardware, not code: this host has **zero paired devices and zero
discoverable peers**, confirmed by a live 8-second scan. No amount of further work in
this repo can close it.

**Owner condition:** closes the first time a real discoverable Bluetooth peer (phone,
headset, etc.) is available near the machine — **not** at a phase boundary. Do not mark
it resolved because a milestone ended.

---

## Notification-server replacement MUST declare `actions` and `body` capability

**Status:** OPEN — a constraint on future work, not a defect in phase 15
**Raised by:** G-15-7 investigation, 2026-08-02
**Owner condition:** closes when the swaync replacement ships with the capability
declared and a real bluetooth pairing verified against it.

Bluetooth pairing confirmations reach the user as an ordinary desktop notification
carrying actions — `BluezAgent._on_request_confirmation` (BluezAgent.py:200-216)
raises `Notification(..., actions=actions, actions_cb=...)`. That is the modern-phone
SSP numeric-comparison path, i.e. the normal case.

blueman picks its presentation by interrogating whatever owns
`org.freedesktop.Notifications`. From `blueman/gui/Notification.py:295`:

```python
if forced_fallback or 'body' not in caps or (actions and 'actions' not in caps):
    klass = _NotificationDialog   # raw GTK dialog
else:
    klass = _NotificationBubble   # desktop notification
```

**So a replacement that does not declare BOTH `body` and `actions` in
`GetCapabilities` silently demotes bluetooth pairing to an unthemed GTK dialog** —
which, being an XDG toplevel, sits unconditionally *behind* any layer-shell overlay
in Hyprland. That is precisely the G-15-4 failure this phase spent a plan removing
for wifi, reintroduced through a different door.

The failure mode is nasty because of where it surfaces: it would look like a
bluetooth panel regression, and be debugged there, while the cause sits in the
notification server.

`Quickshell.Services.Notifications` exposes `actionsSupported` for exactly this, and
also exposes per-notification `actions` plus `invoke` — so the replacement can not
only avoid the regression but route the pairing confirmation into the bluetooth
panel itself, which is what the user originally asked for in G-15-7. That is the
cheap path to containment; building a `org.bluez.Agent1` D-Bus process is not.

**Verification when that phase lands:** pair a real phone and confirm (a) no GTK
dialog appears, (b) the confirmation renders through the new server with working
Accept/Reject, (c) `GetCapabilities` lists `body` and `actions`.
