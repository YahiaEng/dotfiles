---
quick_id: 260824-ns3
phase: quick-260824-ns3
plan: 01
subsystem: quickshell-shell
status: complete
tags: [edge-bar, style-picker, layer-shell, qml, hyprland]
requires:
  - quickshell/.config/quickshell/modules/Prefs.qml
  - quickshell/.config/quickshell/modules/GradientPhase.qml
  - quickshell/.config/quickshell/modules/Colours.qml
  - quickshell/.config/quickshell/modules/Motion.qml
provides:
  - "edgeBar.style — one string pref with five values, replacing the retired edgeBar.enabled bool"
  - "Four edge-bar shapes behind one picker: Continuous, Brackets, Segmented, Halo, plus Off"
  - "edgebarpath.js — a pure-JS, axis-transposed, node-testable path builder for every edge-bar shape"
  - "edgebar-path-test.mjs — 123 assertions pinning the path builder, including a character-identical golden"
affects:
  - quickshell/.config/quickshell/shell.qml
  - quickshell/.config/quickshell/modules/EdgeBar.qml
  - quickshell/.config/quickshell/modules/Bar.qml
  - quickshell/.config/quickshell/modules/launcher/Launcher.qml
  - quickshell/.config/quickshell/modules/Dashboard.qml
tech-stack:
  added: []
  patterns:
    - "Along/depth coordinate space with one P(a,d) transposition helper — a vertical run is the horizontal run with its pairs swapped and every sweep flag re-resolved against the centre that axis demands"
    - "Multi-subpath ShapePath for repeated pieces (Brackets' arms, Segmented's segments) — a Repeater cannot instantiate a ShapePath, and one path means every piece shares one gradient coordinate space"
    - "A style change REMOUNTS the layer surfaces rather than mutating them, because exclusiveZone cannot be lowered to zero on a mapped surface"
key-files:
  created:
    - .planning/quick/260824-ns3-implement-the-edge-bar-style-picker-per-/260824-ns3-SUMMARY.md
  modified:
    - quickshell/.config/quickshell/modules/EdgeBar.qml
    - quickshell/.config/quickshell/modules/edgebarpath.js
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/shell.qml
    - quickshell/.config/quickshell/modules/settings/pages/BarPage.qml
    - quickshell/.config/quickshell/modules/settings/RowIndex.qml
    - hypr/.config/hypr/scripts/tests/edgebar-path-test.mjs
decisions:
  - "D-2 REVERSED (Task 3, prior session): the bar paints the bridge that closes Continuous's silhouette"
  - "DC-1: Brackets keeps hover-to-summon; the hit regions move to the corners rather than being removed"
  - "DC-2: Halo's right rail takes the study's drawn position and reserves nothing, rather than the study table's 8px estimate"
  - "NEW — a style change remounts all four strips, because a mapped layer surface's exclusiveZone cannot be lowered to zero (measured)"
metrics:
  duration: single session
  completed: 2026-08-25
actuals:
  tokens: 68000
  tasks: 4
  commits: 4
---

# Quick task 260824-ns3: Edge bar style picker — Tasks 4-7 Summary

Four edge-bar shapes now live behind one five-entry picker — Halo's four
2px edges, Brackets' four corner Ls at zero screen cost, Segmented's ten
workspace pieces with a whole-segment bulge merge, and the settings row
that switches between them — with every reservation measured off
`hyprctl -j monitors` rather than asserted.

## STATUS: COMPLETE — Task 8 signed off by the operator 2026-08-25

**Tasks 4, 5, 6 and 7 are done, committed and pushed.** Tasks 1-3 were
done, committed and operator-approved in the prior session.

**Task 8 remains outstanding.** It is
`type="checkpoint:human-verify" gate="blocking-human"` — the operator's
own visual and hover judgement on all five styles, which this host
structurally cannot make for itself (no pointer-injection tool exists
here; `ydotool`, `wlrctl`, `dotool` and `xdotool` are all absent, and
`wtype` types into whatever window has focus). It was not attempted, not
simulated and not marked done.

## What was built

| Task | Commit | What |
|---|---|---|
| 4 — Halo | `e533d9dd` | `edge: string` replaces `bottom: bool`; four surfaces; per-style 2px thickness; `bulge: false` plain runs; the static bulge is a permanent 12px mass |
| 5 — Brackets | `0178c4e9` | `alongStart` in the path builder; four corner Ls at a proportional arm length; zero reservation everywhere; two corner hit regions on the reused dwell chain |
| 6 — Segmented | `c80e9b41` | `buildSegmented()` returning `{gradient, outline}`; ten workspace pieces; the whole-segment span-union merge |
| 7 — Settings | `ae9ec82a` | Per-style visibility for the bulge toggle; one plain-English subtext per shape; widened RowIndex keywords |

## Measured `reserved` vectors — all five styles

Read verbatim from `hyprctl -j monitors | jq '.[0].reserved'` on DP-1,
2560x1440, `[left, top, right, bottom]`, live-switching between styles
with no restart. **Never estimated.**

```
off         reserved=[0,0,50,0]     surfaces: (none)
continuous  reserved=[0,6,50,6]     surfaces: top bottom
brackets    reserved=[0,0,50,0]     surfaces: top bottom left right
segmented   reserved=[0,6,50,6]     surfaces: top bottom
halo        reserved=[2,2,50,2]     surfaces: top bottom left right
```

The `50` is the BAR's own reservation in every row; no edge-bar surface
contributes to the right edge on any style.

## The decisions, and their measured outcomes

### DC-2 — Halo's right rail trades the study table's 8px for the study's drawn position

**Decided in the plan, confirmed live.** Hyprland's reservation is
`margins.<anchored-edge> + exclusiveZone`. The right rail cannot both sit
at the study's `RIGHT_EDGE` (10px inside the bar's own reserved boundary)
*and* reserve only its 2px thickness — those are the same number. The
drawn shape won: `margins.right = Design.edgeBarSideMargin`,
`exclusiveZone: 0`.

**Measured:** the right rail lands at x = 2498-2499, i.e. its outer face
at `screenW - 50 - 10 = 2500`, exactly the study's `RIGHT_EDGE`. Its cost
is **zero** — `reserved` right stays 50, the bar's own. The study table's
8px estimate is not what shipped and is not what was measured.

**Operator verdict: PENDING (Task 8, item 7).**

### DC-1 — Brackets keeps hover-to-summon

**Decided in the plan, implemented, live-confirmable only by the
operator.** The two corner hit regions on each surface feed the *same*
`HoverHandler` / `_bulgeArmed` / dwell-`Timer` / `bulgeHoverTriggered()`
chain the bulge already used — reused verbatim, including the
re-arm-only-on-a-genuine-exit rule, which is now factored into
`_hoverEnter()` / `_hoverExit()` so it has exactly one implementation.
The top surface still opens the dashboard and the bottom still opens the
launcher's menu mode; only *where you aim* changed.

The panels those hovers summon open **unattached**, and that half WAS
confirmed live: with Brackets selected, the launcher's bottom edge sits
at y = 1427 (floating clear of the screen edge), both bottom corners
round inward, and there are no concave `AttachedCorner` flares anywhere.

**Operator verdict: PENDING (Task 8, item 2a/2b).** The 0.4 hover-growth
constant is explicitly flagged for live tuning.

### D-2 reversal — recorded in the prior session, restated here

Continuous reverses D-2 ("the edge bar is an independent frame, not the
bar"). The strips cannot reach the bar — a surface with a non-negative
exclusive zone is positioned *inside* every other surface's zone, so the
bar's 50 pins the strips' right end no matter what margin is set, and
`exclusiveZone: -1` would surrender the strips' own reservation. So the
**bar paints the bridge**. The cost was stated up front and taken
deliberately: `Bar.qml` now knows the edge-bar style exists, which it
previously did not. That is the whole content of the reversal, and it is
recorded in `Bar.qml`'s own header and in `EdgeBar.qml`'s D-2 block.
Shipped and operator-approved in commits `7498035b` + `9fbd4cea`.

## Deviations from plan

### [Rule 1 — Bug] A mapped layer surface's `exclusiveZone` cannot be lowered to zero

- **Found during:** Task 5, when Brackets measured `[0,6,50,6]` instead of
  the required `[0,0,50,0]`.
- **Issue:** Probed directly rather than theorised:
  - `exclusiveZone: 0` hardcoded → `reserved` `[0,0,50,0]` (the value is fine)
  - `_brackets ? 0 : 99` → `reserved` `[0,99,50,99]` (positive → **not lowered**)
  - `_brackets ? 42 : 0` → `reserved` `[52,42,102,42]` (0 → 42 **applied**)
  - Halo's 6 → 2 also applied.

  So the zone can be **raised** after the surface is mapped and can be
  changed **between two positive values**, but a change **to zero is
  silently not applied** — the old reservation persists for the life of
  the surface.
- **Why it bit here:** the top/bottom loaders are active on every non-off
  style, so they mount before `Prefs` resolves and take the default
  style's reservation; and every *live* switch into Brackets from any
  other style hit the same wall, which is exactly the operator's Task 8
  flow.
- **Fix:** `shell.qml` gains `_edgeBarMountArmed`, which drops for exactly
  one event-loop turn on any `edgeBarStyle` change. All four strips are
  therefore **destroyed and rebuilt** rather than mutated. This is the
  same reasoning R3 already applies to OFF ("a mounted-but-hidden layer
  surface keeps its `exclusiveZone`"), extended to the case R3 did not
  have: a style that is on but costs less than the one before it.
- **Verified:** live-switching `off → continuous → brackets → segmented →
  halo → continuous` with no restart tracks `reserved` correctly in both
  directions (table above).
- **Commit:** `0178c4e9`

### [Rule 3 — Blocking] `hyprctl dispatch workspace N` fails silently on this host

- **Found during:** Task 6, verifying that the lit segment tracks the
  focused workspace. Three switch attempts appeared to succeed while
  `hyprctl activeworkspace` never left workspace 1.
- **Cause:** this Hyprland build routes `hyprctl dispatch` through Lua, so
  `dispatch workspace 2` is parsed as Lua and errors — the error was being
  swallowed by output redirection. `hl.dsp.workspace(...)` does not exist
  either (`attempt to call a table value`).
- **Correct form on this host:** `hyprctl dispatch "hl.dsp.focus({ workspace = N })"`,
  which is the form `hypr/.config/hypr/config/keybinds.lua:315-320` already uses.
- **Impact:** verification tooling only; no shipped code changed.

## What the path test now covers

`node hypr/.config/hypr/scripts/tests/edgebar-path-test.mjs` — **123
assertions, 123 passed** (was 59 at the start of this session). Groups
1-5 are unchanged from Task 2 and the horizontal golden is still
**character-identical**; Tasks 4-6 added:

- **Group 6** — `bulge: false` emits a plain run on both axes and both
  flips: exactly 4 arcs (two two-quarter-arc pill caps, no fillets), 7
  coordinate pairs, and every depth coordinate is 0, `re` or `t` — no
  bulge excursion anywhere.
- **Group 7** — omitting `bulge` is byte-identical to `bulge: true`, so
  every pre-Task-4 caller and the committed golden are unchanged.
- **Group 8** — `alongStart` translates the run along its own axis and
  leaves the depth axis untouched, on both axes and both flips, with the
  same sweep flags on both arms.
- **Group 9** — Segmented's merge, checked against an independently
  recomputed span union: 10 separate segments at bulge depth 0; at depth 4
  and 10 the merged run starts at a **segment** edge (749.4) rather than
  the bulge edge (865.0), 4 segments are absorbed whole, 6 survive, and no
  survivor straddles the merged span. `active: -1` lights nothing.

## Live pixel measurements

All read as **raw RGB per column/row**. Saturation, luminance,
contiguous-run and on/off-diff probes all lie on this host — the Hyprland
window border shares the strip's hue and sits 10px (`gaps_out`) inside the
reserved boundary, which is exactly what one early scan picked up before
the column was re-chosen.

**Halo** (`e533d9dd`)
- left edge: accent at columns 0-1, background from column 2 — a real 2px run
- right rail: accent at x 2498-2499 (outer face at the study's `RIGHT_EDGE`)
- top centre, `animatedBulge` **OFF**: 12px accent mass (rows 0-11)
- top off-centre, same state: 2px hairline (rows 0-1)
- top centre, `animatedBulge` **ON** at rest: 2px — swell depth 0
- four live surfaces: `quickshell-baredge-{top,bottom,left,right}`

**Brackets** (`0178c4e9`)
- top surface painted runs at depth y=2: `(10..229)` and `(2280..2499)` —
  two 220px arms with **nothing between them**, no bulge anywhere
- arm length 220 = `round(2490 x 170/1920)`, i.e. proportional, never the study's raw 170
- left rail at x=14: `y 10..135` and `y 1304..1429` — two 126px arms
- right arm at x 2494..2499 = `RIGHT_EDGE - k .. RIGHT_EDGE`, y 10..136
- cap profile at an arm's end across y 0..5: x reaches 228, 229, 229, 229,
  229, 228 — **convex**, no inward-curving notch (hazard 4 stayed disarmed)
- `reserved` `[0,0,50,0]` — the corners cost nothing
- launcher on this style: bottom at y=1427, both bottom corners round
  inward, no flares — **unattached**, confirmed live

**Segmented** (`c80e9b41`)
- `animatedBulge` **ON**, at rest — **10** separate runs, 9 background gaps:
  `(10..251) (260..500) (510..750) (760..1000) (1009..1250) (1259..1500)
  (1509..1749) (1759..1999) (2009..2249) (2259..2499)`, each ~241px =
  `(2490 - 8x9)/10`, gaps 8-9px
- `animatedBulge` **OFF**, merged — **7** runs, longest **992px** at
  x 759..1750. The merged span starts and ends on **segment** edges
  (759/1750), not on the bulge edges (875/1635) — 4 segments absorbed whole
- depth through the merged centre: 10px accent = `t(6) + staticExtra(4)`
- bottom rail: ONE continuous 2490px run with a centre bulge — an
  ordinary rail, unchanged
- active segment tracks the focused workspace live: `ws 1 → 2` moved the
  lit run from `(10..251)` to `(259..501)` and back. Inactive runs read
  `(40,53,76)` against the lit run's `(198,166,247)`

**Settings** (`ae9ec82a`) — screenshots of Settings > Bar after a restart
- brackets: the Edge bar section shows **only** "Edge bar style"; the
  "Animate the bulge" row is absent
- continuous / halo / off: the row is present, with the per-style subtext

## Gate counts

Baseline at `9fbd4cea` → final at `ae9ec82a`. **No count fell.**

| Gate | Baseline | Final |
|---|---|---|
| `quickshell-doctor` | 28 / 0 | **28 / 0** |
| `colour-lint` | 362 / 0 | **362 / 0** |
| `motion-lint` | 549 / 0 | **549 / 0** |
| `keybind-doctor` | 13 / 0 | **13 / 0** |
| `settings-index-check` | 120 / 0 | **120 / 0** |
| `edgebar-path-test.mjs` | 59 / 59 | **123 / 123** |

`quickshell-doctor` returned 27/1 on two individual reads during the
session and 28/0 on every re-run — the documented live-probe flakiness
(it has previously read 25/3 then 28/0). Every commit's gate line was
taken from a re-run, and the final state was confirmed three times.

Also asserted by grep, comments stripped:
- press-accepting items in `EdgeBar.qml` (`TapHandler|MouseArea|WheelHandler|DragHandler`): **0** — T-ns3-03 holds
- bare `170` in `Design.qml`: **1**, inside `edgeBarBracketArmFraction: 170 / 1920`, never as a length
- `edgeBar.enabled` reads in `BarPage.qml`: **0**
- `Hyprland.focusedWorkspace` bindings in `EdgeBar.qml`: **2**
- exactly ONE `WlrLayershell.namespace` binding in `EdgeBar.qml`; all four
  namespaces pattern-match the single existing registry row, and no second
  row was added

## Hazards that stayed disarmed

- **Hazard 1 (vertical runs)** — one transposed emitter, not a second path
  builder. The vertical golden assertion (Group 5) still passes.
- **Hazard 2 (resizing layer surface)** — no surface dimension changes on
  any frame of any animation. Brackets' arms grow ALONG the edge, never
  into it, which makes this true by construction rather than by discipline.
- **Hazard 3 (fillet invariant)** — still swept 0 → 10 in 0.5 steps.
- **Hazard 4 (`_arcCentre`'s 90-degree domain)** — every arc added by
  Tasks 4-6 is a quarter circle; every pill cap, arm end and segment end
  reuses the existing two-quarter-arc construction. The measured convex
  cap profile on Brackets confirms it live.
- **Trap 2 (`GradientPhase` singleton)** — the vertical rails read the same
  singleton clock; no second infinite animation was introduced.
- **Trap 12 (live-probe flakiness)** — every gate failure was re-run before
  being believed; none survived a re-run.

## Known stubs

None. Nothing was left placeholder, mocked or unwired.

## Deferred / outstanding

**Task 8 — operator sign-off (blocking-human).** Present the plan's own
Task 8 script. What this host genuinely cannot answer, stated plainly:

1. **Hover-dwell behaviour on any style.** No pointer-injection tool
   exists here. Every hover judgement is the operator's, not a probe's.
2. **An open panel's swell.** The bulge is exactly the panel's width and
   the flare extends ~24px past it, so a capture of an open-state swell
   reads 100% non-background. That probe is blind, not the state empty.
3. **Sub-pixel and aesthetic judgement.** Whether the weld reads as one
   silhouette, and whether the segments read as information rather than
   noise, are visual calls.

Two constants are explicitly flagged for live tuning at that checkpoint:
Brackets' `edgeBarBracketArmHoverExtra` (0.4) and, if the 2px Halo
landmark gets lost at that thinness, `edgeBarHaloThickness`.

The shell was left on **Continuous** with `animatedBulge` ON — the
defaults — and restarted after the last edit.

## Self-Check: PASSED

Files verified present on disk:
- `quickshell/.config/quickshell/modules/EdgeBar.qml` — FOUND
- `quickshell/.config/quickshell/modules/edgebarpath.js` — FOUND
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — FOUND
- `quickshell/.config/quickshell/shell.qml` — FOUND
- `quickshell/.config/quickshell/modules/settings/pages/BarPage.qml` — FOUND
- `quickshell/.config/quickshell/modules/settings/RowIndex.qml` — FOUND
- `hypr/.config/hypr/scripts/tests/edgebar-path-test.mjs` — FOUND

Commits verified in `git log`:
- `e533d9dd` — FOUND
- `0178c4e9` — FOUND
- `c80e9b41` — FOUND
- `ae9ec82a` — FOUND

All four pushed to `origin/main`.

---

## Post-summary: operator feedback rounds 12 and 12b (2026-08-25)

Seven further commits after the four Tasks 4-7 landed. All pushed.

### Round 12 — four notes, all fixed and OPERATOR-PASSED

| # | Note | Commit | Outcome |
|---|------|--------|---------|
| 1 | Continuous | — | **PASS**, no change needed |
| 2 | "the brackets are clipping with hyprland windows" | `0b8db18e` | Fixed — REVERSES DC-2 |
| 3 | Segmented pass, but "the always show bulge option should not exist in this style" | `514febd3` | Row hidden + value forced |
| 4 | "the right edge is clipping" + "the bulge size should be thinner in this style" | `0b8db18e`, `e272a88e` | Both fixed |
| new | "make hyprland windows rimless/without the border" for every style except off | `4a9490b4` | Shipped, then **approved** |

**THE CLIPPING'S ROOT CAUSE — the study has no compositor.** It insets rails by
`INSET = 10` and puts the right rail at `RIGHT_EDGE = BAR.x - 10`. Hyprland
insets every client by `gaps_out`, also 10 here, so the window silhouette's outer
edge lands on EXACTLY the pixel the study's inset puts the rail on. Measured
before, window box `x 10..2499`: Brackets arms `10..15` and `2494..2499`, Halo
right rail `2498..2499` — all inside it. Anchoring all four flush to their own
boundary and letting `gaps_out` supply the gap is what the top and bottom rails
always did, which is precisely why THEY were never reported as clipping.

**Why rimless stays, in the operator's own words:** *"so much better than we had
before (it was sensory vomit with so much shifting rainbow gradients)"*. This is
a SENSORY-LOAD argument, not a taste one — Hyprland's animated gradient border
was a second scrolling gradient competing with the rail's. Do not reintroduce a
window border while a rail style is active.

### Round 12b — two items, both OPERATOR-APPROVED

| Item | Commit | Outcome |
|------|--------|---------|
| "the app drawer upper corners in brackets style are cut off" | `1a4d9b9f` | **"dashboard bug fixed"** |
| Hover-summoned drawers dismiss on mouse-leave | `809f60c0` | **"hover dismissal approved"** |

### Measured `reserved` after round 12 — supersedes the table above

```
off         [0,0,50,0]      brackets    [0,0,50,0]
continuous  [0,6,50,6]      halo        [2,2,50,2]
segmented   [0,6,50,6]
```

Gaps between rail and window silhouette, measured as raw per-column RGB:
Brackets left `x 6..9` (4px) and right `x 2500..2503` (4px); Halo left 10px and
right `x 2500..2507` (8px). Halo's static bulge is now `y 0..7` (8px, was 12)
with the off-centre hairline still `y 0..1`.

### Three things later work must not relearn

1. **`edgeBarPanelsAttach` is false in TWO states** — no rail at all, AND
   rail-present-but-unattached. Branching on it alone changes the no-rail case
   too. `Dashboard.qml` now takes `edgeBarRailPresent` as well and collapses the
   pair into `_floatingFromRail`.
2. **The hover-summon provenance flag is reset in ONE place** — the loader's
   `onActiveChanged` deactivate edge — so every non-hover summon starts false by
   construction and there is no caller list to keep in sync.
3. **`hyprctl keyword` is dead on this build** ("can't work with non-legacy
   parsers. Use eval."). Hyprland options go through `hypr-overrides.sh`, which
   evals, verifies against `hyprctl -j` and persists across `hyprctl reload`.

### Gates at `809f60c0` — run once each, per operator instruction

`quickshell-doctor` 28/0 · `colour-lint` 362/0 · `motion-lint` 549/0 ·
`keybind-doctor` 13/0 · `settings-index-check` 120/0 · path golden 123/123.

### Still unverifiable on this host

The pointer-in/pointer-out transition for hover-dismissal. `hl.dsp.movecursor`
is nil on this build and there is no input-injection tool, so the arming
behaviour was proven with a forced positive control (both drawers self-closed
between t=1s and t=4s) and the keyboard exemption with the shipped code (both
stayed open past t=8s). The feel is the operator's call, and they approved it.


---

## Task 8 — OPERATOR SIGN-OFF, 2026-08-25. Task closed.

All five styles judged live by the operator across three feedback rounds.

| Task 8 item | Verdict |
|---|---|
| 1. Continuous — one silhouette, bar still reads as the bar, hover unchanged | **approved** |
| 2. Brackets — four corners, no bulge, corner summon, panels free-floating | **approved** |
| 3. Segmented — lit segment tracks workspace, bulge absorbs whole segments | **approved** |
| 4. Halo — hairline frame, static masses present, thinner swell | **approved** |
| 5. Off — nothing drawn, launcher drops from the top, border restored | **approved**, after one fix |
| 6. Two Rails removal — gone from every style and fallback | **approved** |
| 7. Screen cost — measured vectors match expectation | **approved** |

**ONE DEFECT FOUND AT SIGN-OFF AND FIXED** (`7ee1621c`): Off still showed the
"Animate the bulge" row, which did nothing there. Hidden; the row is now an
allow-list of Continuous and Halo only.

**THE OPERATOR ALSO VERIFIED SOMETHING THIS HOST NEVER TESTED:** every style in
**horizontal bar mode** — *"I also checked all styles with horizontal bar mode
and all styles behave and look correctly."* Every automated measurement in this
task was taken with the bar vertical (the live orientation), so the horizontal
half of Task 2's axis transposition had no live evidence behind it until this.
It now does.

### Final commit range

`8e4417c9` (Task 1) .. `7ee1621c` (Task 8 fix) — 11 code commits plus docs.

### Final gate counts

`quickshell-doctor` 28/0 · `colour-lint` 362/0 · `motion-lint` 549/0 ·
`keybind-doctor` 13/0 · `settings-index-check` 120/0 · path golden 123/123.

### Two constants left deliberately tunable

`edgeBarBracketArmHoverExtra` (0.4) and `edgeBarHaloThickness` (2) — both
approved as-is, both named here so a future round knows where to reach.
