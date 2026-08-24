# Edge bar style directions — design brief

**Status:** APPROVED FOR IMPLEMENTATION, **all questions settled**, zero code written.
**Decided:** 2026-08-24, operator. Q1/Q3 settled first pass; Q2/Q3-per-style/Q4 settled on resume.
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
| ~~Two Rails~~ | ❌ **REMOVED** — operator, 2026-08-24 | 2 · top, bottom | 12px (6+6) | 2 of 2 |
| Continuous | ✅ | 3 + bar | 12px (6+6) | 3 of 3 |
| Brackets | ✅ | 4 corners | 0 — can overhang entirely | 0 direct |
| Segmented | ✅ | 2 · top, bottom | 12px (6+6) | 2 of 2 |
| Halo | ✅ | 4 · all | 8px (2×4) | 2 of 4 |

**Closed Frame** and **Three Rails** were shown in the study and **not chosen**. Do not
build them; do not quietly reintroduce them as "the left rail" of something else.

**Two Rails — the shape shipped today — is REMOVED**, not kept as a fallback. The picker has
five entries, one of which is off.

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

## DECIDED — settled by the operator 2026-08-24, do not re-litigate

**Q1 — Does "Two Rails" survive as a style? → NO.** Operator's words: *"no two rails does not
survive."* Remove it. The picker is exactly **off · Continuous · Brackets · Segmented · Halo**.

  Consequence, and it is the reason Q4 below exists: Two Rails is what ships TODAY. Removing it
  means the currently-rendered shape has no home in the new picker, so both the default and the
  migration for the existing `edgeBar.enabled: true` become undefined. See Q4.

  **What is NOT discarded with it.** Rounds 7-11 tuned Two Rails, but almost none of that tuning
  was Two-Rails-specific — it is the strip's own vocabulary and it carries forward:
  flat run `T = 6`, side inset `10`, convex pill caps, `edgeBarHoverDepth = 16`, swell `10`,
  the `primary/secondary/tertiary` scrolling gradient, the static bulge shape (extra 4, fillet 3,
  corner 1), and the reversed-entrance dismiss. Continuous and Segmented inherit all of it
  directly; Brackets and Halo inherit the vocabulary but not the bulge geometry.

**Q3 — Does `edgeBar.animatedBulge` need a per-style answer? → YES, and all four are now
answered (operator, 2026-08-24).** Original confirmation: *"yes we will need a per style answer."*

| Style | Bulge behaviour | Toggle in Settings |
|---|---|---|
| Continuous | swells on hover/open exactly as today | **visible**, default ON |
| Segmented | swells; segments inside the bulge span **merge into one solid run** | **visible**, default ON |
| Brackets | **no bulge at all**; the L arms extend toward the centre on hover | **hidden** — nothing to animate |
| Halo | swells 2 → 12; toggle OFF = permanent static bulge at full depth | **visible**, default ON |

  **Continuous** keeps round 11's behaviour untouched — the operator judged it live and approved it,
  and Continuous inherits the whole round 7-11 vocabulary, so the shape it already signed off on is
  the shape it ships with.

  **Segmented** — the bulge wins, the segments yield. Segments falling inside the bulge's 760px span
  collapse into the bulge's own continuous silhouette; segments outside stay separate. The reason is
  the thesis itself: an attachment root cannot have gaps in it, or the `AttachedCorner` flare has
  nothing to weld to and the one-silhouette effect breaks at exactly the joint it exists to hide.

  **Brackets** — no bulge is drawn, and **panels do not attach on this style**. The study's own table
  scores Brackets `0 direct` rails-with-a-panel; that is a property of the shape, not a gap in the
  drawing. The dashboard and launcher open unattached, as they do in `off` mode — no flare, no weld,
  no rim clipping. The hover landmark moves to the corners: the L arms extend toward the centre.
  Grafting a centre bulge onto Brackets was offered and declined; so was growing the arms until they
  meet (which would make Brackets a resting state of Continuous rather than its own shape).

  **Halo** — the toggle behaves as on every other style rather than being forced. Note what OFF means
  here and do not implement it as "no bulge": `animatedBulge: false` is the *static permanent bulge*
  (D-3's original), so Halo with the toggle off is a 2px hairline frame plus two fixed 12px masses —
  still a landmark, just a motionless one. It is a legitimate state, not a dead one.

---

## DECIDED — Q2 and Q4, settled by the operator 2026-08-24

**Q2 — Key shape. → A single `edgeBar.style` string; the bool is retired.**
`edgeBar.style` takes `"continuous" | "brackets" | "segmented" | "halo" | "off"`, allow-listed in
`Prefs.qml`. The `edgeBar.enabled` bool goes away as a stored key.

  **The load-bearing detail that must not be lost.** `Launcher.qml`'s direction branch (D-5) reads a
  boolean today, and it must keep following **"is any rail present"**, never "is the style non-off".
  Those are the same predicate right now — all four shapes render a rail — but they are not the same
  question, and R3 breaks if a future style renders nothing while still being non-off. So `shell.qml`
  resolves the style once and derives an explicit intermediate:

  ```
  readonly property string edgeBarStyle       : Prefs.get("edgeBar.style")
  readonly property bool   edgeBarRailPresent : edgeBarStyle !== "off"   // ← the predicate
  ```

  `Launcher.qml` reads `edgeBarRailPresent`. It must NOT read `edgeBarStyle`.
  Settings gets one `SelectRow` with five entries — no switch, no greyed-out row, and no reachable
  `enabled:false + style:halo` dead state.

**Q4 — Default style, and the migration target for `edgeBar.enabled: true`. → Continuous.**
Default is `"continuous"`; any stored `edgeBar.enabled: true` migrates to `style: "continuous"`, and
`false` migrates to `"off"`. It was the study's own recommendation, it is the only direction where
every edge does a job, and at 12px (6 + 6) it costs exactly what Two Rails cost — so the migration
does not silently change how much screen the operator loses.

  **Accepted cost, stated up front: this reverses D-2.** Task 7's acceptance evidence was that
  `Bar.qml` appears in NO commit of this task; Continuous requires the bar and the rail to share one
  silhouette, so `Bar.qml` must change. Record it as a deliberate reversal exactly the way D-3's was
  in round 11 — not as a deviation discovered mid-execution.

---

## Nothing is open. Implementation scope is fully defined.

Q1 · Q2 · Q3 (all four styles) · Q4 are settled and quoted above. No question remains to be asked
before code is written.

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
5. **Continuous breaks D-2, and Continuous is now the DEFAULT** (Q4), so this is not a
   conditional hazard — it fires on the first install. Task 7's own acceptance evidence was that
   `Bar.qml` appears in NO commit of this task. Continuous requires the bar and the rail to share a
   shape. Record it as a deliberate reversal of D-2, exactly as D-3's reversal was recorded in
   round 11 — not as a mid-execution deviation.
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
| `quickshell/.config/quickshell/modules/Bar.qml` | **Continuous only** — but Continuous is the default, so this WILL be touched; reverses D-2 |
| `quickshell/.config/quickshell/modules/launcher/Launcher.qml` | direction branch must read `edgeBarRailPresent`, not the style string (Q2) |
