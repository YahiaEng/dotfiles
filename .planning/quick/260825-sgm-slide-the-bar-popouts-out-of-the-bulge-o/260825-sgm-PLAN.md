---
quick_id: 260825-sgm
date: 2026-08-25
status: planned
description: Slide the bar popouts out of the bulge on the dashboard motion, and clear two stale bookkeeping items
planner: inline (mirrored fix — see Provenance)
---

# 260825-sgm — Slide the bar popouts out of the bulge

## Provenance — why there is no planner run

Operator standing rule: when the fix mirrors an existing one that can be named
by file and line, apply it directly and keep the commit/SUMMARY/STATE
guarantees. Both references are named and were read before this plan was
written:

- `modules/Dashboard.qml:741` — `y: opened ? 0 : -height`, `opacity: opened ? 1 : 0`
- `modules/launcher/Launcher.qml:664` — the same pair as a `Translate` off the
  anchored edge, with the arm/settle guard at `:616-:642`
- `modules/launcher/Launcher.qml:612` — **the rule this plan obeys**, quoted
  verbatim: *"never derive a layer-shell surface's entrance geometry from that
  surface's own height. Anchor to the edge and animate a TRANSLATION whose
  distance depends only on the panel's own height."*

## The operator request

> "The reveal and dismissal animations for the right bar panels needs
> adjusting. I want them to be a close copy to the animations of the app
> dashboard and super+space/super-tab. Meaning the animation starts from the
> bulge and the dismissal is a reversal of the spawn animation."

## Scope resolution (measured, not assumed)

Two surface families sit on the shell's edge frame. Which one is "the right bar
panels" was resolved by reading the layer posture of each, not by name:

| Surface | Anchor | Weld | Motion today | Verdict |
|---|---|---|---|---|
| `dashboard/PanelDialog.qml` (Wifi/Bluetooth/Audio) | `anchors.top: true` (`:172`), compositor-centred | flares `edge: "top"` (`:341`, `:355`) | `y: opened ? 0 : -panelHeight` on `spatialInDuration` + `spatialInReverseEasing` (`:236-:250`) | **Already the close copy.** Same edge, same tokens, same reversal as the dashboard. Out of scope. |
| `bar/SectionPopout.qml` (the eight capsule popouts) | `top` + `right: vertical` (`:153-:161`), `margins.right: PopoutController.rootInset` onto the bulge face (`:829`) | flares at `panel.top`/`panel.bottom`, `anchors.right: panel.right` (`:453`, `:468`) | round-4 **width reveal** — `spawnClip`, `width: opened ? width : 0` + `clip` (`:270-:312`) | **In scope.** A growing container, not the dashboard's slide. |

Live geometry confirming the frame (`hyprctl layers`, 1920x1080):
`quickshell-bar` at `1838 0 76 1080` — the right vertical slab;
`quickshell-baredge-top` at `10 0 1850 16` and `-bottom` at `10 1064 1850 16` —
the two horizontal rails. The dashboard and the config panels drop from the top
rail's centre bulge; the launcher rises from the bottom rail
(`Launcher.qml:664`, `edgeBarRailPresent ? panel.height : -panel.height`). The
popouts are the only family welded to the **right** slab.

## Tasks

### Task 1 — Bookkeeping: supersede two stale records

**Files:**
- `.planning/quick/260825-pyf-unify-the-bar-popouts-onto-the-edge-bar-/260825-pyf-SUMMARY.md`
- `.planning/todos/pending/2026-08-23-steamwebhelper-crash-loop-on-nvidia-xwayland.md`

**Action:**
1. The `## Still outstanding` section (`:211`) claims *"The attached popout has
   still never been rendered."* Round 4 of that same task rendered it and
   measured the reveal frame by frame (`w=8 -> 15 -> 22 -> ... -> 357`,
   `clip=true`). Rewrite the section to record that it was closed by round 4,
   naming the evidence. Do not delete the section — supersede it, so the
   record of what was outstanding and what closed it both survive.
2. Move the steamwebhelper todo to `.planning/todos/completed/` with a closing
   note: operator closed it as INTENDED — reason 213 is Chromium's
   `INVALID_INITIATOR_ORIGIN`, a Steam bug, not this repo's.

**Verify:** `## Still outstanding` no longer asserts the popout is unrendered;
`.planning/todos/pending/` holds no `.md` files.

**Done:** Both records match what actually happened.

### Task 2 — Replace the width reveal with the dashboard's slide

**File:** `quickshell/.config/quickshell/modules/bar/SectionPopout.qml`

**Action:**

1. **Strip `spawnClip` back to an opacity carrier.** Drop its animated `width`
   binding, its `Behavior on width` and its `clip`. It must stay in the tree
   and must keep `opacity` + `Behavior on opacity`: `popoutBackground`,
   `popoutRim`, the two `AttachedCorner` flares and the content are **siblings
   of `panel`** anchored to it, not children of it, so they do not inherit
   `panel`'s opacity — the container is their only common parent. Removing it
   would also force six children back out through the interleaved root-level
   `readonly property` declarations that blocked the same move in round 4.

2. **Put the slide on `panel.x`.** Positioned, not transformed — the file's own
   `:233` note gives the reason and it still holds: the flares are siblings
   anchored to `panel`'s edges, anchors track real geometry, and a transform
   would slide the panel out from under two flares left standing at the bulge.

   ```qml
   x: popoutWindow.opened ? 0 : popoutWindow.panelWidth
   ```

   The distance is `panelWidth` — **the panel's own width, never the
   surface's** (`Launcher.qml:612`). Closed, the panel sits one full width to
   the right of its open position; the layer surface's right edge is seated on
   the bulge face by `margins.right: PopoutController.rootInset`, and the
   surface clips to its own buffer, so the closed panel is entirely hidden
   behind the bar and emerges leftward out of the bulge. That is the
   dashboard's mechanism with the axis rotated to the edge this panel belongs
   to.

3. **Mirror the existing `Behavior on y` for `x`** — `Motion.spatialInDuration`,
   `Easing.BezierSpline`, and `_dismissing ? Motion.spatialInReverseEasing :
   Motion.spatialInEasing`. The reversal then costs nothing extra: the closed
   offset is `+panelWidth` in both directions, so the mirrored curve retraces
   the entrance path exactly.

4. **Adopt the launcher's arm/settle guard** (`Launcher.qml:616-:642`), replacing
   the bare `Qt.callLater` at `:872`. This is not optional polish — it is the
   trap that has now bitten this file twice:
   `_slideFromBar` is `attached && vertical`, and `vertical` is assigned by
   `PopoutTrigger.qml:173-175` **after** construction. A closed state that
   branches on it evaluates at construction, when it is still `false`. Shape:
   `property bool _armed`, `_armAndOpen()` arming one tick before the flip via
   `Qt.callLater`, a 60ms `settleTimer` restarted on size change, and a 500ms
   hard stop. Gate `Behavior on x`, `Behavior on y` and `Behavior on opacity`
   on `Motion.motionEnabled && popoutWindow._armed`, so while disarmed the
   closed offset tracks instantly and the panel simply waits off-view.

**Do not touch:** `requestDismiss()` (`:109-:126`) or `exitHold` (`:135-:143`).
The flag is already set before `opened` flips so the first exit runs the
mirrored curve, and the hold is already `max(spatialInDuration,
emphasizedInDuration)`. Both are correct for the new motion unchanged.

**Verify:** `spawnClip` has no `width`/`clip`; `panel` carries `Behavior on x`;
no Behavior in the entrance path is ungated by `_armed`; the slide distance
references `panelWidth` and never `popoutWindow.width`.

**Done:** A popout emerges from the bulge and retracts into it on the mirrored
curve.

### Task 3 — Gates

Run once each (operator standing rule — only re-run one that actually fails):
`quickshell-doctor`, `colour-lint`, `motion-lint`, `settings-index`,
`keybind-doctor`, `hypr-equivalence`. Confirm `reserved` is unchanged at
`[0, 6, 50, 6]`.

## Risks

- **The construction-time trap, third occurrence.** Mitigated by Task 2.4 and
  checked in Task 2's verify: no entrance-path branch may depend on a
  loader-assigned property for its *closed* value.
- **Unattached popouts** keep their vertical drop (`y`), which already reads
  `opened || _slideFromBar` — under the arm guard that now resolves after
  `vertical` has arrived, which is a strict improvement, not a change of
  intent.
- **No live pixel verification is possible this session.** `hyprctl monitors`
  reports the output as `FALLBACK`, i.e. the display is asleep, and layer
  surfaces render black in that state. Diagnostics must go through the shell's
  own `console.log` in `~/.cache/quickshell.log`, never `grim`. The shell must
  not be restarted from the agent shell.
