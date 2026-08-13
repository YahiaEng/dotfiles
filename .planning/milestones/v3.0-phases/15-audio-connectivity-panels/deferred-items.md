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

---

## CLOSED 2026-08-13 by plan 19-08 Task 5 — live pairing verified at GATE-02

**Status: CLOSED.** Closed on its own owner condition ("closes when the swaync
replacement ships with the capability declared and a real bluetooth pairing verified
against it"), not at a phase boundary. Both halves are now satisfied:

**(c) `GetCapabilities` lists `body` and `actions` — mechanically verified**, not
inferred from the design contract. Queried directly against the live session bus at
close time:

```
$ busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
    org.freedesktop.Notifications GetCapabilities
as 6 "persistence" "body" "body-markup" "body-hyperlinks" "actions" "icon-static"

$ ... GetServerInformation
ssss "quickshell" "quickshell" "" "1.2"
```

Both capabilities this item names as its blocking requirement are present, and the
server answering is the shell itself. This is the condition that decides blueman's
branch at `blueman/gui/Notification.py:295` — with `body` and `actions` both in
`caps`, it selects `_NotificationBubble`, never `_NotificationDialog`. The demotion
path this item was raised to prevent is therefore closed at its source.

**(a) no GTK dialog appears and (b) the confirmation renders through the new server
with working Accept/Reject — confirmed by the user at the GATE-02 render gate**, which
listed this pairing as criterion B.4 and required a real phone paired over bluetooth.
The user approved the gate on all 12 criteria on 2026-08-13, B.4 included.

**Evidence boundary, stated honestly:** (c) is instrumented above and reproducible by
re-running those two commands. (a) and (b) rest on the user's own GATE-02 approval —
they were verified by the human at the gate, not captured mechanically by this plan,
because a pairing confirmation dialog cannot be asserted from a script. That is the
same standard this item's own text set ("pair a real phone and confirm..."), and the
same standard G-15-2 was closed under when the user supplied the Z Fold7 during UAT
round 2. It is recorded this way rather than implying a capture that was never taken.

---

### Prior disposition (superseded 2026-08-13, retained for provenance)

**Status at the time: NOT closed.** This item was dispositioned as **resolved-by-construction
in Phase 19**, with its own stated closing condition ("closes when the swaync
replacement ships with the capability declared and a real bluetooth pairing verified
against it") split across two halves: the declared-capability half is satisfied by this
phase's own design contract, and the live-verification half is explicitly deferred to
plan **`19-08`**.

`19-CONTEXT.md`'s locked decisions already commit to declaring both capabilities this
item names as its blocking requirement — `GetCapabilities` advertising `body` and
`actions` is a stated design contract of the Phase 19 notification server, not an open
question, so the first half of this item's own closing condition is satisfied by
construction as soon as that server ships. What remains is exactly what this item's own
text already specified as its closing verification: *"pair a real phone and confirm (a)
no GTK dialog appears, (b) the confirmation renders through the new server with working
Accept/Reject, (c) `GetCapabilities` lists `body` and `actions`."* That live pairing
test is plan `19-08`'s to run and flip this item closed — not this plan's. Marking this
resolved before a phone has actually been paired against the shipped server would be
exactly the fabricated-resolution failure `19-RESEARCH.md`'s LEDGER-04 Ground Truth
section warns against, so it stays open, pointed forward, until `19-08` performs that
verification and updates this entry itself.

**Boundary note, corrected count:** `19-RESEARCH.md`'s LEDGER-04 Ground Truth section
(taken 2026-08-13) already established that this item is tracked as a SEPARATE ledger
from the five session files in `.planning/debug/` — it is not one of "six open debug
sessions" as ROADMAP.md's stale phrasing conflated. The corrected LEDGER-04 accounting
this phase closes out is: **five open session files in `.planning/debug/`** (all five
dispositioned `resolved` in this same 2026-08-13 pass — see each file's own "Phase 19
Disposition" section), **plus this one separately-tracked deferred item** (dispositioned
resolved-by-construction here, live-verified by `19-08`) — **six dispositions total**,
against the corrected count, not the roadmap's stale "six debug sessions" framing. The
historical sixth debug-session file (`panels-missing-animated-border.md`) was already
moved to `.planning/debug/resolved/` and closed under Phase 18's LEDGER-01, before this
phase began.
