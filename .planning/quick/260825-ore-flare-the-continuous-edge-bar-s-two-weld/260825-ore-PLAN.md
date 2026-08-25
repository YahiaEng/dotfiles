---
quick_id: 260825-ore
slug: flare-the-continuous-edge-bar-s-two-weld
date: 2026-08-25
mode: quick
---

# Flare the Continuous edge bar's two weld corners

Make the top and bottom corners — where the horizontal rails attach to the
vertical bar — thicker, with a smooth flare, the way Caelestia's frame does it.

## The defect, measured (not assumed)

`grim -g "2460,0 100x60"` + a raw per-pixel RGB dump of the live Continuous
bar (operator's own standing rule: every visual claim comes from pixels, never
from a `Design.qml` token):

```
y=0   material runs left from x=2532
y=5   material runs left from x=2543
y=6   material collapses to x=2510..2544   <- the step
```

Between y=5 and y=6 every pixel left of x=2510 disappears. That step is the
defect: the rail's underside terminates in a hard kink against the slab's pill
cap. The two runs meet at a corner instead of flowing into one another.

## What Caelestia actually does — source-read, HIGH confidence

`caelestia-dots/shell`:

- `modules/drawers/ContentWindow.qml` builds the whole frame as ONE
  `BlobInvertedRect` inside a `BlobGroup` — an SDF (signed-distance-field)
  shape, `smoothing: Config.border.smoothing`.
- `plugin/src/Caelestia/Config/borderconfig.hpp`:
  `thickness 10`, `rounding 25`, `smoothing 20`.
- Its thin border (10px) meets its thick bar (`borderLeft: bar.implicitWidth`)
  through the frame's own single inner corner at `radius: rounding` — 25px,
  i.e. **2.5x the border thickness** — smooth-union'd by the SDF.

There is no butt joint anywhere in that frame. That, and not the blob renderer,
is the property to reproduce: the thin run and the thick body share one
continuous, tangent-continuous outline.

## The fix

A concave tangent fillet added to `weldStubTop` and `weldStubBottom` in
`quickshell/.config/quickshell/modules/Bar.qml`, drawn inside the stubs' own
existing `ShapePath` so it is filled by the same repeating `_stripGradX1`
gradient the stubs already carry — one shape, one gradient, no seam and no new
surface.

### The radius is DERIVED, not tuned — this is the whole point

Live values on this host: `barColumnWidth 44`, `edgeBarWeldRim 4`, so
`_weldSlabWidth = 52` and the slab's pill cap radius `R = 26`. The bar surface
is 76 wide, `_weldSlabX = 24`, `_weldRunEnd = 50`. Rail thickness `t = 6`.

Set the flare radius to

```
F = R - t = _weldSlabWidth / 2 - edgeBarThickness = 26 - 6 = 20
```

Then the fillet's arc, centred at `(_weldSlabX - F, t + F)`, runs from
`(_weldSlabX - F, t)` — where its tangent is horizontal, matching the rail's
underside — to `(_weldSlabX, t + F) = (24, 26)`, where its tangent is vertical.
And `(24, 26)` is **exactly the slab cap's widest point**, where the cap's own
tangent is also vertical.

So the two curves meet coincident AND tangent, by construction. The outline
becomes one continuous sweep: straight rail underside -> 20px quarter arc ->
straight slab flank. Any other radius leaves either a visible nub (the arc's
corner poking outside the cap) or a residual kink.

Expressing F as a derived token rather than a literal `20` keeps that tangency
invariant true if `barColumnWidth` or `edgeBarWeldRim` are ever retuned.

For scale: F=20 against t=6 is 3.3x thickness, versus Caelestia's 25 against 10
(2.5x) — and 20px absolute against Caelestia's 25px absolute. Same order, and
here it is pinned by geometry rather than by taste.

### Sweep flags, derived — never hand-guessed

The trap `AttachedCorner.qml` and `edgebarpath.js` both document at length: the
wrong flag silently picks the other geometrically valid centre and renders a
CONVEX bulge that looks deliberate and is wrong. Worked through
`edgebarpath.js`'s own `_arcCentre` formula (valid here — both arcs are quarter
circles, so its hardcoded scalar holds):

- **Top**, arc `(_weldSlabX, t+F) -> (_weldSlabX - F, t)`, wanted centre
  `(_weldSlabX - F, t+F)`: `x1p = y1p = F/2`, solving `c.x` gives `sign = -1`,
  and `c.y` checks out at `t+F`. `sign = -1` => **sweep-flag 0**.
- **Bottom** is the top mirrored in depth, which flips handedness. Re-derived
  independently rather than assumed: arc `(_weldSlabX, 0) -> (_weldSlabX - F, F)`,
  wanted centre `(_weldSlabX - F, 0)`, gives `sign = +1` => **sweep-flag 1**.

## Tasks

1. **Design token.** Add `edgeBarWeldFlareRadius` to
   `modules/dashboard/Design.qml`, derived as
   `(barColumnWidth + 2 * edgeBarWeldRim) / 2 - edgeBarThickness`, with the
   tangency invariant recorded in its comment.

2. **Top stub.** Grow `weldStubTop.height` from `edgeBarThickness` to
   `edgeBarThickness + flare` (its `y` stays 0) and replace its four-point
   rectangle path with the flared outline.

3. **Bottom stub.** Move `weldStubBottom.y` up to
   `height - (edgeBarThickness + flare)` and grow its height to match; emit the
   depth-mirrored path with the flipped sweep flag.

## Verification

- `grim` + raw per-column RGB dump of both corners. The y=5 -> y=6 collapse
  must be gone; the outline must descend smoothly from the rail underside to
  the slab flank across ~20px.
- Confirm the arc is CONCAVE (material hugs the corner) and not a convex bulge —
  the sweep-flag failure mode.
- Gates, once each: `quickshell-doctor`, `colour-lint`, `motion-lint`,
  `settings-index-check`.
- Do NOT restart quickshell — QML hot-reloads on file change. (Standing rule,
  broken three times: restarting it from the agent shell kills the session.)

## Out of scope

- The other four edge-bar styles. Halo/Brackets/Segmented/off do not weld — the
  weld stubs are `visible: _continuousWeld` only.
- Horizontal bar orientation: `_continuousWeld` requires `vertical`.
- The launcher's and dashboard's `AttachedCorner` flares — a different joint.
