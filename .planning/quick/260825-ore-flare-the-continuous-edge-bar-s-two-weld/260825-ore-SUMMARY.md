---
quick_id: 260825-ore
slug: flare-the-continuous-edge-bar-s-two-weld
date: 2026-08-25
status: complete
---

# Flare the Continuous edge bar's two weld corners — SUMMARY

Both corners where the horizontal rails attach to the vertical bar now flare
into it through one concave tangent fillet each. Verified by raw pixel dump on
the live shell, not by reading tokens.

## What was wrong, measured

`grim -g "2460,0 100x60"` + per-pixel RGB dump, before:

```
y=5   material runs left from x=2543
y=6   material collapses to x=2510
```

Every pixel left of 2510 vanished between two adjacent rows. The rail's
underside was terminating in a hard kink against the slab's pill cap.

## The radius is derived, and that is the whole result

`Design.edgeBarWeldFlareRadius = capRadius - edgeBarThickness`, where
`capRadius = (barColumnWidth + 2 * edgeBarWeldRim) / 2`. On this host: 26 - 6 =
**20**.

That specific value is not a taste call. The slab is a pill, so its cap's
widest point — the one place its tangent is vertical — sits at depth
`capRadius`. `Bar.qml` centres the fillet at `(_weldSlabX - F, t + F)`, which
puts its far end at `(_weldSlabX, t + F)` with a vertical tangent. Choosing
`F = capRadius - t` makes those two points **coincide and their tangents
match**, so the rail's underside, the arc and the slab's flank become one
continuous outline instead of three pieces that meet.

Confirmed numerically before touching pixels: far end `(24, 26)` vs cap widest
`(24, 26.0)` — COINCIDENT.

Any other radius breaks it by construction. Larger and the arc's corner pokes
outside the cap as a square nub; smaller and it lands on the cap's curve at an
angle, leaving the kink the fillet exists to remove. Expressed as a derived
token, so retuning `barColumnWidth` or `edgeBarWeldRim` carries it along.

## The sweep flags were solved, not guessed

The failure mode `AttachedCorner.qml` and `edgebarpath.js` both warn about at
length: the wrong flag picks the other geometrically valid centre for the same
endpoints and radius, drawing a CONVEX bulge that looks deliberate and is wrong,
with no error anywhere.

Both flags were resolved against `edgebarpath.js`'s own `_arcCentre` formula
(in domain — both arcs are quarter circles) and then checked by exhausting both
candidates:

```
flip=False  arc (24,26) -> (4,6)   centre wanted (4,26)  resolves at sweep=[0]  emitted=0  OK
flip=True   arc (24,0)  -> (4,20)  centre wanted (4,0)   resolves at sweep=[1]  emitted=1  OK
```

Exactly one flag is valid per arc and it is the one emitted. The bottom is the
top mirrored in depth, and a mirror flips handedness, so it was re-derived
rather than reused.

## Result, measured on the live shell

Left boundary of material per row, after:

```
top     y= 5 2460(rail)  y= 6 2484  y=10 2494  y=15 2499  y=20 2501  y=26 2502(flank)
bottom  y=1434 2460(rail) y=1433 2485  y=1429 2494  y=1424 2499  y=1419 2501  y=1414 2502(flank)
```

- The `y=5 -> y=6` collapse is **gone**.
- The boundary now walks smoothly across ~20px from the rail's underside to the
  slab's flank at 2502, with a monotonically decreasing rate — the curve
  flattening toward vertical, which is the concave quarter-arc signature. A
  wrong sweep flag would have bulged left of the rail instead; it does not.
- Top and bottom are mirror-symmetric within 1px of antialiasing.
- Predicted arc ends (2482, 2502) vs measured (2484, 2502) — within AA.

## Files

- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — new derived
  `edgeBarWeldFlareRadius`, declared immediately after its last input so no
  member is read before declaration.
- `quickshell/.config/quickshell/modules/Bar.qml` — new `_weldStubPath(flip)`
  builder replacing both stubs' hand-authored rectangle strings; both stub boxes
  grown to contain the flare (`weldStubBottom.y` moved up to match).

One builder serves both corners via a depth mirror — never a second
hand-authored path string, which is the doctrine `edgebarpath.js` already set
for this silhouette.

## Gates — run once each, all green

| Gate | Result |
|------|--------|
| quickshell-doctor | 28 passed, 0 failed |
| colour-lint | 362 passed, 0 failed |
| motion-lint | 549 passed, 0 failed |
| settings-index-check | 121 passed, 0 failed |

No count fell against the last recorded run.

`hyprctl monitors` still reports `reserved [0, 6, 50, 6]` — margins and
`exclusiveZone` were untouched, so the flare overhangs into the client area
exactly as the strip's own bulge already does. The double-count reservation bug
this file has shipped twice could not recur: no reservation term was edited.

Quickshell was NOT restarted — QML hot-reloaded on file change, `Configuration
Loaded` with no new warning in `~/.cache/quickshell.log`.

## Reference finding worth keeping

Caelestia has no butt joint anywhere in its frame because the frame is not
assembled from pieces at all: `modules/drawers/ContentWindow.qml` draws it as
ONE `BlobInvertedRect` inside an SDF `BlobGroup`, with
`plugin/src/Caelestia/Config/borderconfig.hpp` giving `thickness 10`,
`rounding 25`, `smoothing 20`. Its thin border meets its thick bar through the
frame's single inner corner at 2.5x the border thickness.

The transferable property is tangent continuity, not the blob renderer. This
repo reaches the same read with one derived arc per corner and no shader.

## Not done

- The other four styles. Halo, Brackets, Segmented and off do not weld —
  the stubs are `visible: _continuousWeld` only.
- Horizontal bar orientation — `_continuousWeld` requires `vertical`.
- **Unverified here:** the horizontal-bar orientation was not exercised, on the
  standing ground that this host runs vertical. It is inert there by the
  predicate above, not merely untested.
