---
quick_id: 260825-w4c
date: 2026-08-25
status: complete
description: Align every bulge to its panel, retract it with the panel, and settle what "behind the bar" can mean
commits:
  - 6d86a7ee fix(bar): align every bulge to its panel, and retract it with the panel
---

# 260825-w4c — Align every bulge to its panel

## The instruction that mattered most

> "ALWAYS FUCKING MEASURE THE PIXELS FOR UI RELATED CHANGES"

The previous round reasoned about this bulge from tokens and shipped a fix for
the wrong fault. This round summoned each popout over the now-registered
`popout` IPC target, captured the bar edge with `grim`, and read the bytes.
**The pixels found a defect the arithmetic had no reason to suspect.**

## The bulge was the right SIZE in the wrong PLACE

I had assumed a width bug. It was a position bug, and the two look identical
from a token reading.

Measured on `resources` — `triggerCentre=114`, panel `360x270`:

| | span | centre |
|---|---|---|
| bulge | 26..296 | 161 |
| panel | 50..320 | 185 |

**Off by exactly 24 = `flareRadius`.** The bar clamps the bulge's CENTRE to
`cap + half` = 26 + 135 = 161. The popout separately clamps its WINDOW's top
to 26, which puts the panel at 50 because the window is `2 × flareRadius`
taller than the panel. The bar's clamp reasons about the panel; the popout's
reasons about the window. Two clamps, two different minimums.

**The pixels said it first.** `grim -g "2470,0 90x400"`, then classifying by
colour rather than luminance — bar-core cyan `(151,220,246)` is neither the
panel background `(63,62,83)` nor the flare's arc:

```
rows with bar-coloured material left of the panel edge (x 2478..2501):
   y 26..46      <- ABOVE a panel that starts at y=50
   reaches 14 px left of 2502   <- exactly the bulge depth (4 + 10)
```

A *filled* 14px-deep band, at the bulge's exact depth, in rows the panel does
not cover. Nothing below the panel at all — an asymmetry a width bug cannot
produce, and the thing that redirected the diagnosis.

### The fix: the bulge is no longer positioned

Two independent clamps cannot be made to agree by tuning either one — that is
how the 24px got there in the first place. So the popout publishes its panel's
**real post-clamp span** as `PopoutController.openTop`, and the bar draws the
bulge to exactly that, **shrinking** only to fit the slab's straight run and
never **shifting**. Shrinking keeps the bulge a subset of the panel; shifting
is what let it escape.

The operator's invariant — *"the bulge's width must be so that it never pops
out behind of the panel's sideways"* — is now structural, not emergent from two
clamps coinciding.

**One term in it was also measured rather than derived.** `openTop` converts
margin space to screen space: margins here measure from the **usable area**
while the bar draws in **screen space**, and the gap is what the top rail
reserves (`EdgeBar.qml:335`, `exclusiveZone: _t` = `edgeBarThickness`). Without
it the span came back `44..314` against a panel at `50..320` — short by exactly
6. `popoutWindow.y` was probed first as a cleaner source and returns
`undefined`; Quickshell does not expose a PanelWindow's resolved position.

### Verified on all eight, panel span from `hyprctl` geometry

| popout | panel | bulge | |
|---|---|---|---|
| resources | 50..320 | 50..320 | ✓ |
| wifi | 1027..1297 | 1027..1297 | ✓ |
| audio | 960..1292 | 960..1292 | ✓ |
| clock | 1082..1402 | 1082..1402 | ✓ |
| media | 868..1149 | 868..1149 | ✓ |
| bluetooth | 1108..1228 | 1108..1228 | ✓ |
| ethernet | 1109..1287 | 1109..1287 | ✓ |
| tray | 868..988 | 868..988 | ✓ |

Pixel re-capture on the worst case: the widest bar-coloured run escaping the
panel went **14px → 4px**, and the 4px is a thin diagonal, not a filled band —
the flare's own border arc, which is the weld and belongs there.

## Second fault: the shelf let go of the panel on the way out

Found while checking whether the bulge moves *with* the panel. It grew on
`spatialIn` — matching the panel — but collapsed on `spatialOut`, while
`SectionPopout` retracts on `spatialInReverseEasing` over `spatialInDuration`.
So the shelf went flat in roughly a third of the time the panel took to slide
home, and the panel finished retracting into an already-flat bar.

That is precisely the "two objects" read the operator is asking to remove. The
bulge now uses the panel's own pair in both directions: one body growing, one
body retracting.

## "Spawn from behind the bar" — what was established

`exclusiveZone: -1` **does** reach the true screen edge. Tested directly:
`margins.right: 0` with `exclusiveZone: 0` put the surface edge at 2510 (the
usable boundary); with `exclusiveZone: -1` it landed at **2560**. So
`Bar.qml:613`'s note blaming `ExclusionMode.Ignore` names the wrong cause — the
real one is that an explicit `exclusiveZone: 0` overrides the Ignore mapping.
The popout surface *can* be extended behind the bar.

**Stacking, however, is closed by the shell's own architecture, not by the
compositor.** Tested: moving the popout to `Top` and the bar to `Overlay` does
give true occlusion — but `EdgeBar.qml:309` states the rule it breaks,
*"never Overlay — always-on chrome sits below transient dialogs"*, and it would
put the bar above the dashboard, the config panels, notifications and the power
menu. It also shifted the bar to `2478 6 76 1428` from `2478 0 76 1440`,
because at overlay it is processed after the rails and inherits their 6px
reservations — which would break the Continuous weld. Reverted.

So the bar's face is the reveal line. What actually delivers the "one body
extending" read is the two fixes above: before them the panel emerged from a
shelf misaligned with it by 24px and then retracted while that shelf collapsed
early. Both are now measured to be exact.

## Gates

`colour-lint` 365/0, `motion-lint` 552/0, `settings-index-check` 121/0,
`keybind-doctor` 13/0, `hypr-equivalence-check` 3/0, `qmllint` 0 on all three
edited files.

`quickshell-doctor` not run — it restarts the shell and killed the session
earlier today. Operator only.

## Outstanding

- Judge the dismissal now that the bulge retracts with the panel.
- `quickshell-doctor` still unrun against any of today's changes.
