---
phase: 21-media-fold-in-contract-close
plan: 05
subsystem: quickshell bar + panel surfaces (frost / do-not-disturb indicator)
tags: [frost-unification, layer-rules, dnd, bar-roles, clock-actions-capsule, render-gate, decision-reversal]
dependency-graph:
  requires: []
  provides:
    - "One shared frost fill/threshold pair across the panel-class surfaces (dashboard, overview, notification family, OSD)"
    - "A do-not-disturb indicator on the bar's clock/actions capsule (lit bell glyph, D-21-27-R)"
  affects:
    - "hypr/.config/hypr/config/windowrules.lua"
    - "quickshell/.config/quickshell/modules/Dashboard.qml"
    - "quickshell/.config/quickshell/modules/Overview.qml"
    - "quickshell/.config/quickshell/modules/bar/BarRoles.qml"
    - "quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml"
tech-stack:
  added: []
  patterns:
    - "Mode-active glyph expressed as a `tint` branch on the one cell that owns the mode — the gamingCell precedent (`gamingOn ? BarRoles.accent : contentColour`), now shared by the bell cell"
    - "Per-surface layer rules placed AFTER the family regex so the specific rule wins"
key-files:
  created: []
  modified:
    - hypr/.config/hypr/config/windowrules.lua
    - quickshell/.config/quickshell/modules/Dashboard.qml
    - quickshell/.config/quickshell/modules/Overview.qml
    - quickshell/.config/quickshell/modules/bar/BarRoles.qml
    - quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml
    - .planning/phases/21-media-fold-in-contract-close/21-UI-SPEC.md
decisions:
  - "D-21-26 (frost unification) shipped as specified — dashboard and overview joined the notification/OSD pair at fill 0.38 / ignore_alpha 0.2; the bar deliberately stays out of the unified set"
  - "D-21-27 (ambient whole-capsule DND tint) REVERSED at Task 3's blocking render gate and superseded by D-21-27-R: do-not-disturb reads as a lit bell glyph instead"
  - "BarRoles gains no DND role pair — dndSurface/dndSurfaceFg were added then removed; a lit glyph reuses the existing accent role"
  - "The DND tint branch sits BELOW the unread branch because BarRoles.accent and BarRoles.fillNotification are both Colours.primary; no signal is lost because the notifications_paused glyph shape already outranks notifications_active"
  - "DND deliberately NOT folded into filled/fillActive/badgeVisible — those derive from the single unreadCount input per D-13/QBAR-06, and DND is a mode, not a count"
metrics:
  duration: ~2h wall (spanning the render-gate pause)
  completed: 2026-08-16
status: complete
actuals:
  tokens: 38000
  tasks: 3
  commits: 3
---

# Phase 21 Plan 05: Frost Unification + Do-Not-Disturb Indicator Summary

Landed the two operator-folded todos this phase absorbed. Frost unification shipped exactly
as designed and passed its render gate untouched. The do-not-disturb indicator shipped as
designed, was **rejected at the same gate**, and was rebuilt on a different mechanism — the
plan's blocking human-verify task doing precisely the job it exists for.

## What Was Built

### Task 1 — Frost unification (D-21-26), commit `4a17b51`

The dashboard drawer and the overview were moved onto the same frost fill/threshold pair the
notification family and OSD already used: fill `0.38`, `ignore_alpha 0.2`. Three coordinated
edits — `windowrules.lua` lowered the dashboard and overview `ignore_alpha` thresholds, and
`Dashboard.qml`'s opacity constant came down to `0.38` to match.

The fill/threshold distinction is the part worth remembering: the fill must strictly *exceed*
the threshold or the compositor skips blur entirely and the surface renders as raw unblurred
transparency. `0.38 > 0.2` holds with margin. The bar is deliberately **not** in the unified
set and was left alone.

### Task 2 — Do-not-disturb capsule tint (D-21-27), commit `8dd0a5c`

Shipped as specified: a `dndSurface`/`dndSurfaceFg` pair in `BarRoles.qml` (accent blended at
`0.28`, foreground kept on `onSurface`), routed into an instance-level `color:` override on
`ClockActionsCapsule.qml`'s own root object so the whole capsule washed accent while
`NotifServer.dnd` was true. `BarCapsule.qml` — the shared component — was correctly left
untouched so no other capsule inherited the tint.

### Task 3 — Blocking human-verify render gate → **reversal**, commit `483d4b3`

Frost: **approved as-is.** All four surfaces read at the same strength, blur intact.

DND tint: **rejected on approach, not on strength.** The operator's report was that the tint
should not extend to the clock pill.

Measurement before acting confirmed the code was doing exactly what the spec described:
`clockFillPill.color` is `BarRoles.fillClock` → `Colours.secondary`, fully opaque, no
`opacity` property, drawn on top of the capsule fill. The pill never took the accent. But the
wash sat *behind and around* that opaque pill, so the tinted region engulfed the clock
regardless. **"The clock pill does not change colour" and "the tint does not extend to the
clock" are different claims** — the spec asserted and verified the first while the design
needed the second. That gap is the whole finding.

The replacement (D-21-27-R) is not a new mechanism. `21-UI-SPEC.md` already reserved accent
for "lit toggle chips (Gaming/**DND**/Dark when ON)" — the capsule-wide wash was the
departure from that rule and the reversal restores it. DND is now one branch on the bell
cell's `tint`, mirroring `gamingCell`'s `gamingOn ? BarRoles.accent : contentColour`
verbatim. The instance-level `color:` override is gone entirely, so the capsule inherits
`BarCapsule.qml`'s shared expression unmodified again, and the `BarRoles` pair was removed
rather than left dangling.

Two ordering constraints are load-bearing and are documented in-file so they survive a later
edit:

1. **The DND branch sits below the unread branch.** `BarRoles.accent` and
   `BarRoles.fillNotification` are *both* `Colours.primary`, so when `unreadCount > 0` the
   glyph draws on a primary-filled `cellFillPill` — an accent glyph there would be
   primary-on-primary and vanish. Nothing is lost: the glyph *shape* already carries DND
   unconditionally (`notifications_paused` outranks `notifications_active`), so the mode
   still reads when both are true; only the redundant colour cue defers.
2. **DND is not folded into `filled`/`fillActive`/`badgeVisible`.** Those derive from the
   single `unreadCount` input per D-13/QBAR-06. Do-not-disturb is a mode, not a count.

`21-UI-SPEC.md` was amended in four places to match the shipped result rather than the
reversed decision: § DND Capsule Tint rewritten as § DND Indicator with the reversal and its
rationale recorded, the E5 consideration rows corrected (including the `error` row, which now
notes the `!available → danger` branch outranks DND so an unavailable source never reads as a
lit chip), the planner-obligation list item struck, and the open-tunables preamble amended.

## Deviations from Plan

| Deviation | Why |
|---|---|
| **D-21-27 reversed; DND rebuilt as a lit bell glyph (D-21-27-R)** | Operator verdict at Task 3's blocking render gate. The plan anticipated only a *strength* result here and wrote an explicit escape valve — "if it reads as visually loud the fix is tuning the tint strength, not rethinking the approach". The gate returned an **approach** result instead, and correctly overrode that escape valve. |
| `dndSurface` / `dndSurfaceFg` removed from `BarRoles.qml` | Consequence of the above. A lit glyph needs no blended surface. Removed rather than left dangling; a comment marks the vacated spot so the pair is not re-added by reflex. |
| `21-UI-SPEC.md` edited, though not in the plan's `files_modified` | The spec asserted a design that no longer ships. Leaving it would have left the phase's own contract document describing a reversed decision. |
| Tint strength is no longer a tunable | The `0.20`–`0.35` alpha range applied to a blended surface. A lit glyph is a full-strength accent role with no alpha of its own. |

## Verification

| Check | Result |
|---|---|
| `colour-lint` | 144 passed, 0 failed |
| `motion-lint` | 291 passed, 0 failed |
| No residual `dndSurface` reference in QML | Confirmed — only in explanatory comments naming the removal |
| `BarCapsule.qml` untouched | Confirmed via `git diff` across all three commits |
| Frost: four surfaces at equal strength, blur intact | **Operator-verified** at the Task 3 render gate |
| DND: tint no longer extends to the clock pill | Follows by construction — no capsule-level `color:` override exists. **Not yet operator-verified live**; the glyph-badge rebuild landed after the gate returned. |

**Carried debt:** the D-21-27-R lit-bell-glyph rendering has not itself been through a live
render gate. It is a single `tint` branch with an in-file precedent (`gamingCell`) that is
already operator-approved in the same capsule, so the risk is low — but D-21-20's blocking
combined render gate (Plan 08) should include an explicit DND-on/DND-off look at the bell
cell, in both bar orientations, rather than treating this as settled.

## Self-Check: PASSED
