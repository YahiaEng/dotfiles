---
quick_id: 260825-pyf
slug: unify-the-bar-popouts-onto-the-edge-bar-
date: 2026-08-25
mode: quick
---

# Unify the bar popouts onto the edge-bar language

Every bar popout — wifi, ethernet, bluetooth, audio, media, resources, tray,
clock — should pop out of a bulge on the bar's own edge, with the app
dashboard's look and motion. When there is no bulge to come from, they spawn
from the top of the Hyprland windows instead.

## Ground truth, measured before planning

**All eight popouts are one frame.** `modules/bar/SectionPopout.qml` is the
single host; the eight `*Popout.qml` files are bodies declared into it. So this
is one frame change plus wiring, not eight ports.

**The attachment map** (`shell.qml:790`, its own words): *top = dashboard,
bottom = launcher, right = the bar, left = nothing*. `EdgeBar._hasBulge` is
`!_vertical && !_brackets`, so the vertical rails carry no bulge at all, and in
Continuous they are not even mounted — `_edgeBarFourSided` is halo/brackets
only. There is therefore **no existing bulge anywhere near a wifi capsule.**

**Only Continuous paints a continuous bar edge.** `barContent` is a bare `Item`
with no background; the gradient slab and its `Colours.surface` core are both
`visible: barWindow._continuousWeld`. In every other style the capsules float
with no slab behind them.

**The bulge is centred by construction.** `EdgeBar._cx` is hardcoded
`_ww / 2`; `_xl`/`_xr` derive from it. Positioning a bulge anywhere else needs
`_cx` to become settable.

**The trigger's anchor is already in the right coordinate space.**
`PopoutTrigger.publishAnchor()` computes `mapToItem(null, 0, 0)`, which maps
into the item's own window — the bar's `PanelWindow`. That is exactly the space
`Bar.qml` needs to place a bulge, with no conversion. (The popout itself must
add `barSideMargin`; the bar must not. This is the conversion trap
`SectionPopout.qml:216` records at length.)

**A PRE-EXISTING DEFECT, found by measuring rather than reading.**
`SectionPopout.qml:194` aligns popouts to the window edge with
`Design.barSideMargin` (10) standing in for `gaps_out`, and warns in its own
comment: *"It matches gaps_out by value rather than by binding — if
general:gaps_out changes, this alignment needs revisiting."* Live now:

```
general:gaps_out = 20        general:border_size = 0
tiled windows report at=[20, 26]
```

`gaps_out` is 20 (operator-confirmed intended, 2026-08-25), so every popout is
currently **10px off** the window edge it was tuned to. The window's true top
edge is y=26 = `reserved.top (6) + gaps_out (20)`.

## Decisions taken

**D-1 — Origin: a bulge at the trigger** (operator, previews shown). Not the
dashboard's shared centred bulge, and not a popout-sized bulge on the top rail.
The dashboard's bulge is centred *because the dashboard is centred*; the
principle is "bulge sized to the panel, at the panel's position", and here that
is the bar's edge beside the capsule.

**D-2 — The bulge is drawn by the BAR, not by EdgeBar.** The capsules live on
the bar, the bar is always present, and in Continuous the bar's slab already is
the right edge. Routing this through `EdgeBar`'s vertical rails instead would
reach only halo/brackets — which do not even mount in the live style.

**D-3 — Attached only where a continuous bar edge exists, i.e. Continuous.**
Segmented, halo and brackets leave the capsules floating with no slab, so there
is no edge to swell. Those three take the same unattached treatment as `off`.
This is a superset of what was asked (`off` was the only style named) and is
recorded as such rather than silently assumed — it is the honest consequence of
D-2, and it follows the existing `edgeBarPanelsAttach` doctrine, which already
excludes brackets from welding.

**D-4 — Unattached means top-anchored.** "Spawn from the top of Hyprland
windows": the popout's top edge sits on the real window top and it slides down,
the dashboard's own entrance. It no longer tracks the trigger along the bar in
this mode — being pinned to the top is the whole point of the instruction.

## Tasks

1. **Publish the open popout's anchor.** `PopoutController` (already a
   singleton, `qmldir:70`) gains `openCentre` and `openExtent` in bar-window
   along-axis coordinates, set by `SectionPopout` as it opens and cleared as it
   closes. One publisher, one reader — no second `mapToItem` call site.

2. **Live window-edge inset.** Replace the hardcoded `barSideMargin`
   stand-in with a value read from `hyprctl getoption general:gaps_out`,
   following the established `WindowManagerPage.qml` Process-runner pattern for
   reading hyprctl values into QML. Fixes the 10px error above, and gives Task 4
   the true window top rather than a third guess.

3. **The bar's edge bulge.** `Bar.qml`'s weld slab grows a bulge at
   `openCentre`, sized to `openExtent` plus shoulders, on the same concave-fillet
   vocabulary the rails already use (`edgebarpath.js`) and the weld corners just
   adopted. Animated open/closed on the dashboard's spatial register. Continuous
   only, inert elsewhere by the `_continuousWeld` predicate that already gates
   every other weld piece.

4. **`SectionPopout` adopts the dashboard's posture.** Attached: welds to the
   bulge — square edge on the bar side, `AttachedCorner` flares, positioned so
   its edge meets the bulge face, sliding out perpendicular on the dashboard's
   entrance with the mirrored exit. Unattached: top-anchored at the real window
   top, sliding down, rounded corners — the dashboard's own no-rail treatment.

5. **Layer rules, gates, pixel verification.** Popout namespaces
   (`quickshell-bar-<id>`) may need their own `animation`/`ignore_alpha` rows to
   match the dashboard's; per-surface rows go AFTER the `^quickshell-.*` family
   regex or they are shadowed, and `frost.sh` replays in file order.

## Verification

- `grim` + raw per-pixel dump per state, never a Design token. Positive control
  on every absence check.
- The bulge must appear at the trigger's own centre — measured against the
  capsule's real screen position, not assumed from the published number.
- Both bar orientations. This host runs vertical; horizontal was the blind spot
  every automated probe had in 260824-ns3, and the operator had to cover it by
  hand. Exercise it here.
- Gates once each: quickshell-doctor, colour-lint, motion-lint,
  settings-index-check, keybind-doctor.
- Do NOT restart quickshell — QML hot-reloads. Standing rule, broken three
  times: restarting from the agent shell kills the session.

## Risks carried

- **`_cx` is load-bearing for four existing instances.** If Task 3 ends up
  touching `EdgeBar` after all, `_cx` must default to `_ww / 2` so every current
  instance stays byte-identical — the same opt-in discipline `alongStart`,
  `squareEnd` and `bulge` already use in `edgebarpath.js`.
- **The popout is an Overlay-layer surface with `exclusiveZone: 0`.** Nothing
  here may change that; a reservation term must not appear.
- **`triggerCentre` is a snapshot, not a binding** — scene mapping does not
  re-evaluate when an ancestor moves. The bulge must follow the same rule or it
  will drift against the popout it roots.
