# Edge bar style directions — design brief

**Status:** APPROVED FOR IMPLEMENTATION, zero code written.
**Decided:** 2026-08-24, operator.
**Source of truth for the shapes:** the design study artifact —
https://claude.ai/code/artifact/b3ebc0ec-7345-4aff-94b4-23c784412789
(local copy of the page source: `/tmp/claude-1000/-home-aorus-dotfiles/19342790-4823-4fd7-9d1f-2b3f513786f5/scratchpad/edge-rail-studies.html` — **ephemeral**, re-read the artifact URL instead.)

The operator's words: *"The options are so great I can't choose just one. So I want
us to implement continuous, brackets, segmented, and halo options with an 'off'
option. Use the webpage you created as the source of truth for the implementation."*

---

## What ships

A **style picker**, not a toggle. Five shapes plus off.

| Style | Ship? | Edges | Screen lost | Rails with a panel |
|---|---|---|---|---|
| Off | ✅ | none | 0 | — |
| Two Rails | ⚠️ SEE OPEN QUESTION 1 | 2 · top, bottom | 12px (6+6) | 2 of 2 |
| Continuous | ✅ | 3 + bar | 12px (6+6) | 3 of 3 |
| Brackets | ✅ | 4 corners | 0 — can overhang entirely | 0 direct |
| Segmented | ✅ | 2 · top, bottom | 12px (6+6) | 2 of 2 |
| Halo | ✅ | 4 · all | 8px (2×4) | 2 of 4 |

**Closed Frame** and **Three Rails** were shown in the study and **not chosen**. Do not
build them; do not quietly reintroduce them as "the left rail" of something else.

---

## The thesis the study was built on — carry this forward

**A rail is an attachment root, not a border.** In this shell each strip is what a panel
grows out of: the bulge is sized to exactly the panel that spawns from it (760 top =
`dashboardMinWidth`, 640 bottom = `launcherPanelWidth`, both shared tokens) and an
`AttachedCorner` flare welds the two into one silhouette.

The measured attachment map — **verified, not assumed**:

| Edge | What is on it | Verdict |
|---|---|---|
| Top | dashboard (Super+D) | rail earns it |
| Bottom | launcher + menu (Super+Space, Super tap) | rail earns it |
| Right | the bar (44px, floating) **and** the notification centre slides in here | already furnished |
| Left | nothing | a rail here is pure geometry |

The notification centre's edge was established by reading which margin it animates
(`NotifCentre.qml`, `margins.right`), not by guessing. That asymmetry is why Closed and
Three Rails lost: both buy symmetry with a dead left edge.

**Correction worth keeping:** Caelestia has **no** four-edge frame. `.planning/research/FEATURES.md:15`
sources it directly — one bar, vertical, right-edge, structurally what this repo already
has. A frame here is a local invention, so the house "Caelestia is the default tiebreaker"
rule gives no cover on this decision.

---

## Geometry constants (the study's own, and they are the live measured values)

```
screen        1920x1080 on the FALLBACK output at capture time; real panel is 2560x1440.
              Everything below is resolution-independent except RIGHT_EDGE.
bar           x = screenW - 50,  w = 44,  y = 10,  h = screenH - 20   (floating, right)
INSET         10      strip inset from each screen side
RIGHT_EDGE    screenW - 50 - 10   (strips stop before the bar's reservation)
T             6       flat run thickness           = Design.edgeBarThickness
SWELL         10      hover/open bulge depth       = Design.edgeBarBulgeSwellExtra
TOPW          760     top bulge width              = Design.edgeBarBulgeWidthTop
BOTW          640     bottom bulge width           = Design.edgeBarBulgeWidthBottom
hover depth   16      = Design.edgeBarHoverDepth   (also the surface depth)
reserved      [0, 6, 50, 6]
```

Per-style specifics as drawn in the study:

- **Continuous** — rails run from `INSET` to `bar.x + bar.w/2` and stop; the bar is drawn
  as a full-height gradient slab (`rx = w/2`) with an inset surface-coloured core, i.e.
  the rail's gradient continues *through* the bar. One silhouette: rail → corner → bar →
  corner → rail. Left edge deliberately open.
- **Brackets** — four L-pieces, arm length **170** at 1920 scale (≈8.9% of screen width;
  derive proportionally, do not hardcode 170), thickness `T`, one horizontal + one
  vertical rect per corner, both with `rx = T/2`. Top bulge still swells on hover.
- **Halo** — thickness **2** (not `T`), all four edges, `rx = 1`. Top/bottom run
  `INSET → RIGHT_EDGE`; left/right run `INSET → H-INSET` at `x = 0` and `x = RIGHT_EDGE`.
  Bulge swells to `2 + SWELL`.
- **Segmented** — top rail only: **n = 10** segments, **gap = 8**, `seg = (RIGHT_EDGE -
  INSET - gap*(n-1)) / n`. Active segment uses the gradient at full opacity; inactive use
  `Colours.outline` at 0.45. Bottom stays an ordinary rail. Bulge overlays the segments.

Colours in the study are the live Dracula palette (`primary #ff79c6`, `secondary #bd93f9`,
`tertiary #8be9fd`, `outline #6272a4`) — in QML these must come from `Colours.qml`, never
literals (`colour-lint` GATE-04 rejects hardcoded colours).

---

## OPEN QUESTIONS — settle these at the top of the implementation task, do not settle them silently

1. **Does "Two Rails" survive as a style?** The operator listed four styles + off and did
   not name the current shipped shape. It is approved, verified and is what `edgeBar.enabled`
   renders today. Dropping it silently would discard round 10's sign-off. **Recommendation:
   keep it as the default style.** Ask.
2. **Key shape.** `edgeBar.enabled` (bool) already exists and is allow-listed in `Prefs.qml`
   with a default of `true`, and `shell.qml` resolves it once into `root.edgeBarEnabled`
   which BOTH `EdgeBar` instances and `Launcher.qml`'s direction branch read (D-5). Options:
   (a) add `edgeBar.style` string alongside, with "off" as a value and retire the bool;
   (b) keep the bool as a master and add the style beneath it. (a) is cleaner but the bool
   is load-bearing for the launcher's direction branch — that branch must follow "is any
   rail present", not "is the style non-off", or R3 breaks.
3. **`edgeBar.animatedBulge`** (round 11) is orthogonal today. Under Brackets there is no
   centre bulge in the study's drawing, and under Halo the bulge is the only landmark. Decide
   per style whether the swell applies, or gate the toggle's visibility.

---

## Implementation hazards — every one of these was paid for already this task

1. **`EdgeBar.qml` is horizontal-only.** `_outlinePath` is x-major throughout (`ww`, `_xl`/`_xr`,
   pill caps on the left/right ends, `Y()` mirroring for top vs bottom). Halo and Brackets need
   VERTICAL runs. That is not a parameter flip — it is either a second path builder or a
   transposed coordinate helper. Budget for it.
2. **The layer surface must never resize.** Pin every surface's depth to the maximum its style
   can reach and animate only the painted path. A resizing layer surface is re-configured and
   re-buffered every frame and drags its own content (round 5 lost a full round to this on the
   launcher).
3. **`fillet + cornerRadius <= bulgeExtra` at EVERY frame**, not just at the endpoints. Round 10
   measured what breaking it looks like: a dark notch cutting into the strip, from the outline
   self-intersecting. Nothing warns — no QML error, no gate.
4. **`_arcCentre` in `EdgeBar.qml` is valid for 90° arcs ONLY.** It hardcodes SVG F.6.5's offset
   scalar to 1. Any new arc that is not a quarter circle will silently resolve to the wrong sweep
   flag and curve inward. The function carries a full note; read it before adding an arc.
5. **Continuous breaks D-2.** Task 7's own acceptance evidence was that `Bar.qml` appears in NO
   commit of this task. Continuous requires the bar and the rail to share a shape. That is a
   deliberate reversal of D-2 and must be recorded as one, exactly as D-3's reversal was in
   round 11.
6. **Reservation is `margins.<anchored-edge> + exclusiveZone`.** Only the flat run may contribute.
   Left/right rails will each add their own reservation — Halo's four 2px edges cost 8px total,
   Brackets can cost **0** if the corners overhang entirely.
7. **Declare QML members before construction-time use.** A binding that reaches forward to an id
   declared later in the file evaluates against something that does not exist yet — one log line
   and an otherwise silent wrong answer. `EdgeBar.qml`'s `_bulgeHovered` is pushed up from the
   HoverHandler for exactly this reason; `Design.qml:736` records the original.
8. **Measuring the strip:** saturation thresholds pick up the wallpaper, luminance thresholds pick
   up the Hyprland window border (same hue), on/off diffs are worthless (the reservation changes so
   every window moves), and contiguous-run scans count uniform background as full depth. **What
   works: dump raw RGB per column/row and read where the strip colour stops.**
9. **A `LazyLoader` serves an incubated STALE component after a file edit.** `systemctl --user
   restart quickshell.service` is required; touching `shell.qml` is not enough.
10. **An open panel always occludes the bulge it grew from** — the bulge is exactly the panel's
    width and the flare extends ~24px past it. Do not try to verify an open-state swell by capture;
    the probe reads 100% non-background and is blind, not empty.

---

## Gates that must stay green

`quickshell-doctor` 28/0 · `colour-lint` 359/0 · `motion-lint` 546/0 · `keybind-doctor` 13/0,
plus `motion-lint --self-test` 12/0 and `quickshell-doctor --self-test` 59/0 if a gate is edited.

`motion-lint` CHECK A derives its allow-list from `motion.json`'s semantic keys and now also
accepts `<camelKey>ReverseEasing`. Any new `Motion.*` token name must be derivable that way or
CHECK A reports it dangling — which it correctly did during round 9.

---

## Files this will touch

| File | Why |
|---|---|
| `quickshell/.config/quickshell/modules/EdgeBar.qml` | the shapes; needs a vertical path builder |
| `quickshell/.config/quickshell/modules/dashboard/Design.qml` | per-style tokens (arm length, halo thickness, segment count/gap) |
| `quickshell/.config/quickshell/shell.qml` | style resolution point, instance mounting per style |
| `quickshell/.config/quickshell/modules/Prefs.qml` | allow-list + default for the style key |
| `quickshell/.config/quickshell/modules/settings/pages/BarPage.qml` | the picker row (`SelectRow`, not `ToggleRow`) |
| `quickshell/.config/quickshell/modules/Bar.qml` | **Continuous only** — and this reverses D-2 |
