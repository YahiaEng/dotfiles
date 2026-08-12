---
status: complete
quick_id: 260812-opa
date: 2026-08-12
description: "Fix GATE-02 F5: popout cards render 52px too low, SectionPopout double-counts the bar extent"
commit: cefcf20
files_modified:
  - quickshell/.config/quickshell/modules/bar/SectionPopout.qml
  - quickshell/.config/quickshell/modules/bar/BarDrawer.qml
---

# Quick Task 260812-opa — GATE-02 finding F5

## What was wrong

The operator, mid-sitting on plan 18-19's GATE-02 blocking render gate, reported: "The popup
cards appear too low. They should be aligned with the top of the window."

`SectionPopout.qml` computed its margin as the bar's own extent plus a gap
(`Design.barEdgeMargin + Design.barHeight + Design.spacingXs` = 52). But the popout is an
anchored layer surface — `PanelWindow`, `anchors { top: true; left: !vertical; right: vertical }`,
`exclusiveZone: 0`, `exclusionMode: Ignore`, `WlrLayer.Overlay` — and the compositor **already**
offsets such a surface past the bar's 48px exclusive zone. Adding the bar's extent a second time
double-counted it: 48 + 52 = 100.

Because all six cards declare `SectionPopout` as their root — `AudioPopout`, `MediaPopout`,
`WifiPopout`, `BluetoothPopout`, `ClockPopout`, `ResourcesPopout` — one expression owned every
card's position. This was one systemic defect, not six.

## The fix was already written, in a sibling file

`BarTooltip.qml:78-90` carries a MEASURED comment recording the identical failure found hours
earlier the same day: it began from `barEdgeMargin + barHeight + spacingXs` (52) *transcribed from
SectionPopout's shape*, measured tooltips at y=100 via `hyprctl layers` against a bar whose bottom
edge is 48, and corrected to keep "only the GAP past the edge the compositor already found,
nothing more."

That fix corrected the file it was reported against and did not sweep the sibling that taught it
the wrong expression. This task applies the same correction to that sibling, so both files now
hold the identical shape.

## Measurement — before and after

Both readings taken with `hyprctl layers -j`, the wifi popout pinned open, on the same live
process (pid `1520318`, never restarted):

| Surface | Before | After | Reference |
|---|---|---|---|
| `quickshell-bar-wifi` | **y=100** | **y=52** | — |
| `quickshell-bar` | y=6 h=42 | y=6 h=42 | bottom edge 48 |
| reserved (`hyprctl monitors -j`) | `DP-1 [0,48,0,0]` | unchanged | window area starts at y=48 |

The card now sits `Design.spacingXs` (4px) clear of the bar's bottom edge, on the repo's 4px grid
— the same relationship the tooltip holds.

## Changes

- `SectionPopout.qml:167-168` — `_horizontalTopMargin` and `_verticalRightMargin` both reduced to
  `Design.spacingXs`. The stale reasoning above them is replaced with the measured record.
- `BarDrawer.qml:101` — `_verticalRightMargin` reduced to `Design.spacingXs`. Required, not
  optional: that file's own comment binds it to SectionPopout's expression pair as "ONE anchoring
  rule, not two (constraint 8)", so leaving it would have broken a stated invariant.

## What is measured and what is not

**Measured:** the horizontal branch, before and after, numbers above.

**Not measured:** the vertical branch (`SectionPopout.qml:168`, `BarDrawer.qml:101`). It is
corrected by the same reasoning — the compositor already offsets past whichever edge the bar
reserves — but no vertical-orientation reading was taken, because doing so requires flipping
orientation and re-pinning surfaces. GATE-02's `B.4` (vertical readouts) and `B.4-DRAWER` (drawer
growth direction) rows are the live confirmation, and both are still unobserved.

## Gates

- `colour-lint` — 110 passed, 0 failed.
- `quickshell-doctor` — 24 passed, 4 failed. The two checks that would catch a regression here both
  pass: `bar-reserved-zone-stability` (delta=48, axis=top, hot-reload identical) and
  `bar-surface-registry` (rows=5, missing=0, unregistered=0). The four failures are in unrelated
  subsystems — MPRIS writers, swayosd key ownership, Hyprland permission-grant paths, and the
  overview content query returning "Not ready to accept queries yet." None reference popout or
  drawer geometry. They were not baselined before the edit; a two-integer margin change cannot
  reach any of them.

No restart or reload of quickshell was performed — the change hot-reloaded through the stow
symlink and the pid is unchanged.

## Consequence for phase 18

GATE-02 iteration 2's checklist is void: this reposition moves a surface that `A.2`, `B.5` and
`B.4-DRAWER` are judged against. Iteration 3 opens against a fresh build fingerprint and
re-observes all fifteen rows. `18-GATE-02-RECORD.md` was not touched by this task — finding F5 is
recorded there at `6bf31f0`, and `## Deletion Authorisation` still reads `RETIRE-02 BLOCKED`, so
plan 18-20's deletion commit remains blocked.
