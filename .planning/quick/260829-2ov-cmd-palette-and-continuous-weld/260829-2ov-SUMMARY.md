---
plan_id: 260829-2ov
mode: quick
status: complete
date: 2026-08-29
commits:
  - 7350ce2e feat — the `cmd` command-palette route
  - b6cfc7b7 feat — weld end-glyph inset, and the horizontal weld
  - 306e47c5 fix — CommandMode needs the `../dashboard` import
  - 50d93b5f fix — icon strip clips, and loads in ~0 instead of 27.7s (round 2)
  - fb0ab0b8 feat — horizontal Continuous is a three-sided frame (round 2)
  - 36e6e9b7 fix — dashboard bulge back, round corners, flare seam (round 3)
---

# 260829-2ov — SUMMARY

Three operator items. All three shipped and measured. **One thing is owed:
an operator's eye on the `cmd` palette's rendered rows and on the horizontal
Continuous bar** — see "What I could not check" at the bottom.

## 1 — `cmd`: a flat command palette over MenuTree

`CommandMode.qml` flattens MenuTree's 35 leaves into one fuzzy-searchable
list, reached by typing `cmd` in the launcher. Fourth word route, on the
`pkg`/`icon`/`font` precedent, so `routePrefix`, `routePartial`, `queryArg`
and `_routeQuery` all came free — they iterate `_wordRoutes` generically and
needed no edit.

**A separate file from `MenuMode.qml`, not a mode switch inside it**, because
the two disagree on both of MenuMode's load-bearing properties: `menu` walks
`navStack` and is listed in `_stickyModes` precisely so a keystroke cannot
re-route the surface, while this ignores `navStack` and MUST fall back to
apps mode the moment the query stops starting with "cmd". The four activation
branches are copied from `MenuMode.activate()` in its order rather than
refactored into a shared helper: re-homing them in the same commit that
introduces a new surface would make a regression here indistinguishable from
one there.

One deliberate behavioural difference from the menu: a `mode` handoff clears
the query first. It still reads "cmd theme" at that instant, and the mode
handed off to filters ITSELF on that text — leaving it would open the picker
pre-filtered to the string typed to find the picker.

The walk recurses although every `children:` in MenuTree sits at one
indentation level today, so a future sub-submenu is searchable the day it is
added rather than dropping out silently.

## 2 — the weld's end capsules clear the core's cap

Operator: "App drawer and power menu glyphs are too close to the edge."

**Measured before touching anything** (grim + raw per-pixel dump, x2500–2560):
the core spans x2506–2550 — 44px, `barColumnWidth` exactly — with its pill cap
centred at y=32, radius 22, core top y=10. `barContent` was inset by
`_weldCapDepth` (10) alone and `startZone.y` is 0, so the first capsule's box
began at **the cap's apex, where the pill has zero width** — and the box is
itself 44 wide. Its two corners sat outside the shape. The app-drawer glyph
read at y16–27.

The fix is arithmetic, not taste: a capsule box is `_weldCoreDepth` wide and
the core is `_weldCoreDepth` wide, so the box first fits at the **cap
tangent** — one cap radius past the core's end. 10 + 22 = 32.

Re-measured after: glyph centre **43** against a predicted 44, and every other
capsule moved by exactly the same 22 (cpu 54–64 → 76–86). Both ends confirmed
on screen.

## 3 — horizontal Continuous: the rail wraps the bar

Operator picked wrap-the-bar and **keep the top strip mounted**; the
alternative (unmount `edgeBarTop`, make the bar the top rail, re-root the
dashboard's bulge onto it) was drawn for them and declined.

`_continuousWeld` **keeps its exact previous meaning** rather than being
widened. It gates six things that are wrong or meaningless on a horizontal
bar — the top/bottom margin collapse, the `implicitWidth` growth, both weld
stubs, the vertical slab, `popoutBulgeDepth`, and the two `PopoutController`
bindings. Widening the predicate would have switched all six on silently. The
horizontal weld gets `_continuousWeldH`; only the core and `barContent`'s
insets read `_welded`.

**The plan's own assumption was wrong, and measuring caught it.** `hyprctl
layers` puts `quickshell-baredge-top` at **y=48** with a horizontal bar up —
BELOW the bar, not above it. A non-negative exclusive zone is positioned
inside every existing zone, and the bar's own 48 is what it lands under. So
the "top rail" is really the bar's UNDERSIDE rail in this orientation, and the
operator's chosen sketch (rail above, rim below it) does not describe the
actual stack. With the bar reserving its body alone, the strip's 6px run
(48–54) and the slab's bottom rim (52–56) OVERLAPPED, and near the ends the
strip's straight band poked out past the slab's rounded cap. Reserving the
whole slab lands the strip at 56, flush, and because both surfaces paint
through the SAME `_stripGradX1`/`_stripPeriod` mapping the seam is invisible —
measured at x=1280: rim `(203,141,238)` then rail `(203,141,237)`, one 10px
gradient edge. That is the *outcome* the sketch promised, on the other face.

The slab runs to the screen's own corners rather than stopping at
`barSideMargin`. Ending it level with the strip would put the cap's widest
point 25px inboard of the strip's end, leaving a 25px wedge of nothing under
the last stretch of rail.

Also fixed while here: `squareEnd` was unconditional under Continuous. It
exists because the bar carries the run on past the strip's far end, which only
a VERTICAL bar does — a horizontal one lies parallel and nowhere near it, so
the butt end had nothing continuing it and read as a blunt stop 10px short of
the screen edge against a rounded cap at the other end of the same rail.
Threaded from `shell.qml` as `runsIntoBar`, not read off
`BarEntryModel.isVertical` inside `EdgeBar.qml` — that file has no orientation
of its own, only an `edge`, and its header says so.

**Verified live in BOTH orientations and restored.** Horizontal: reserved
`[0, 62, 0, 6]`, strip at y=56, both ends captured and clean. Vertical after
restore: reserved `[0, 6, 50, 6]` and the bar surface `2478,0 76x1440` —
byte-identical to before the flip, and the orientation state file restored
byte-for-byte from a backup taken first.

## The finding worth keeping

**Every gate passed through a live `ReferenceError`.** `CommandMode.qml`
shipped without `import "../dashboard"`, so `Design.spacingSm` was undefined —
and `colour-lint` 575/0, `qml-import-check` 0-unresolved-across-193,
`singleton-prop-check` 0-violations and a clean hot-reload line ALL agreed the
file was fine while the surface threw 18 errors per open. The reference parses
as a name and only fails when the binding is EVALUATED, inside a component the
LazyLoader does not instantiate until the mode is entered. **The only
instrument that saw it was opening the launcher in that mode and reading the
log** — which is why that was done rather than trusting six green gates. This
is the repo's standing "a green gate only proves what it can see" finding,
with a new instance: a lazily-loaded component is a gate blind spot by
construction.

Recovery note: the fix did not take on the first reload, because the editor's
write gave the file a new inode and quickshell's inotify watch died with the
old one (the repo's known trap). The tell was no "Reloading configuration…"
line after the edit. **An in-place append to a file whose watch is still alive
(`shell.qml`) forces a whole-config reload and re-reads the orphaned file** —
cheaper than the unit restart the trap's note prescribes, and it needs no
cgroup safety argument at all. Worth preferring next time.

## Gates

`quickshell-doctor` 28/0 · `colour-lint` 575/0 (572 before — the gate
demonstrably saw the new file) · `motion-lint` 814/0 · `transparent-lint`
194/0 · `settings-index-check` 191/0 · `qml-import-check` 0 unresolved across
193 · `singleton-prop-check` 0 violations.

## What I could not check — for the operator

1. **The `cmd` palette's rendered rows.** The launcher dismisses the instant
   the pointer is not on it (`follow_mouse` + `HyprlandFocusGrab`), and there
   is no input-injection path here, so it could not be screenshotted from the
   agent shell. Load and activation are verified; **layout is not**. Type
   `cmd` and check the two-column row reads well — leaf name left, breadcrumb
   right — then `cmd theme` and Enter.
2. **The horizontal Continuous bar in daily use.** Captured and measured at
   both ends and mid-screen, but judged on a flip-and-flip-back rather than
   lived in. Note the composition it actually produces: a 4px rim above the
   bar, and a fused 10px gradient edge below it (slab rim + the strip). If the
   asymmetry reads wrong, the strip is the removable half.
3. **Nothing else is owed from this task.** The `icon`/`font` routes are still
   missing from the `;` provider list — pre-existing since 260828-ah9, noted in
   code, deliberately not fixed here.


---

# ROUND 2 — operator feedback on the round-1 result

Three items. Two were defects I introduced or missed; one was already-shipped
behaviour that the new frame made conspicuous.

## R2-1 — "horizontal bar only appears when I hover over it"

**Not a regression, and measured before answering.** With
`bar status` at `hidden-idle` the slab IS painted — dumped at x300/x1280/x2300
it reads rim 6–10, core 10–52, rim 52–62 — and only the CONTENT (glyphs) is
hidden, by `opacity: 0` plus the hide translate. The vertical bar does exactly
the same thing and has since long before this task; it was captured that way
in this session's very first screenshot.

So this is `bar.autoHideOnIdle`, which is `true` in prefs. What changed is
only that it became obvious: the vertical hidden state is a 44px column at the
screen's right, while the horizontal one is a full-width band across the top
with a permanent gradient frame around it. **Left as-is and handed back as a
choice**, because turning it off changes both orientations and the operator
has lived happily with it in vertical. One command either way:
`qs ipc call prefs set bar.autoHideOnIdle false`.

## R2-2 — the design was a three-sided frame, not a wrapped band

Round 1 asked the wrong question and got a correct answer to it. The right
framing turned out to be one rule, and the rest fell out:

> Continuous draws THREE runs, the bar is one of them, and the fourth side is
> left open.

  vertical bar   → top + bottom rails, bar on the RIGHT, left open (unchanged)
  horizontal bar → right + bottom rails, bar on the TOP, left open (new)

That makes the right rail's mount and the top strip's UNmount the same
decision, not two. **Round 1's "keep the top strip" was wrong on measurement,
not on taste:** with a horizontal bar that strip lands at y=56, *under* the
bar, as a second parallel band — and at the open left end the two capped
differently (25px pill vs 3px), so the strip protruded ~25px past the slab's
curve. Two parallel bands cannot share one silhouette.

The flare is `Design.edgeBarWeldFlareRadius` (20), the vertical weld's own
token. Its vertical derivation does not transfer — that band's right end is
square, not capped, so a quarter arc is tangent at any radius and the value is
free — but reusing the token is precisely what makes the two orientations look
the same, which is what was asked. **The sweep flag was derived numerically
before being written** (`_arcCentre` gives centre (X,0) for sweepPositive and
(X−F,F) against it; `_shoulderSweep` maps true→1, so flag 0), because the
recorded trap is that the wrong flag draws a convex lump that looks
deliberate.

Cost stated rather than left to be discovered: the top strip carried the
dashboard's bulge and its dwell-hover summon, so in this orientation the
dashboard spawns unattached and is reached by Super+D or the clock. `brackets`
already has no bulge on any edge, so that state is not new.

Verified on pixels at all four corners and restored; vertical came back
byte-identical (`reserved [0,6,50,6]`, bar `2478,0 76x1440`).

## R2-3 — the `icon` strip clipped, and took 27.7 seconds

Both real, both arithmetic rather than opinion.

**Clipping:** the launcher panel is 640 wide with 16px margins → a 608px box;
eight themes at 132px + 7×8 spacing need 1112px. The container was a bare
`Row` — a positioner, so anchoring it left+right sets where it starts, never
how wide its children may be — with no `clip`, so tiles 5–8 painted over the
desktop. Now a horizontal `ListView`, which also fixes something a `Row` never
could: Left/Right past tile 4 used to walk the selection off the panel.
Enumerated rather than assumed: `FontMode` already used a clipped ListView;
`IconMode` was the only one of the pair with an unbounded positioner.

**The 27.7 seconds was not the cache.** `_find_icon_at_size` ran one `find -L`
PER NAME PER TIER — up to 60 tree walks per theme, over a Papirus tree holding
**305,764 files** where one bare walk costs 164ms. One traversal now harvests
all names and ranks by the same unchanged five-tier ladder: **3,862ms, a 7.2×
cut, byte-identical on all eight installed themes.**

The cache existed but was in-memory only. It is on disk now, served instantly
with one real probe per theme per session behind it so a dangling path
self-corrects — deliberately no validity fingerprint, because a theme list or
an index.theme mtime is right about some updates and wrong about others.

**Two bugs I introduced and caught by measuring**, both now carrying the
comment that explains them: a binding loop (`previewFor()` is called from
bindings and my refresh latch read and wrote a property inside it — Qt said
`Binding loop detected for property "_rows"` out loud), and the cache eating
itself (FileView reads ASYNCHRONOUSLY, so `text()` from
`Component.onCompleted` returned "" against a good 8KB file and the first
probe saved a cache holding only what it had probed — 7 themes became 4).

## What round 2 could not check

1. **The `cmd` palette's and the icon strip's rendered rows.** Established
   this session as a hard limit, not a missing effort: the launcher's surface
   maps and stays mapped (`alpha 1`, verified at 0.15/0.5/1.0/2.0s) but paints
   nothing once the pointer is elsewhere, `hyprctl dispatch movecursor` does
   not exist on this Lua-parser build, and there is no injection path. Load,
   activation and absence-of-errors are verified; **layout is not.**
2. **The horizontal frame in daily use.** Every corner is measured and
   captured, but it was flipped to and back rather than lived in.


---

# ROUND 3 — three more on the horizontal frame

## R3-1 — the bulge and its dwell-summon are back

On the bar's own slab, with the retired strip's exact numbers:
`edgeBarBulgeWidthTop` (the dashboard's own width), `edgeBarBulgeExtra` depth,
the same shoulder and corner radii. D-3 still holds — nothing about it is
bound to a hover or open state. Measured across the left shoulder at
x880..940: the rim ends at y=55 left of x=903 and continues to y=59 right of
it, with the fillet on the diagonal between. The summon reuses
`dashboardShortcut.toggle()` verbatim, which is what keeps one dwell, one
`dashboardHoverSummoned` flag and one write to `dashboardLoader.active`.

**It surfaced a bug I had shipped an hour earlier.** `_weldFlareOverhang` runs
the surface 20px past its reserved band so the flare has somewhere to be
drawn, and `Bar.qml` has never had an input mask — so a **2550x20 invisible
strip across the top of every window was swallowing clicks.** There is a mask
now; in every case but the horizontal weld `barInputArea` IS the whole
surface, so it is a no-op elsewhere and the vertical bar's long-standing 32px
leftward overhang is untouched.

## R3-2 — the two right corners are round, and deliberately unequal

`buildOutline` gained `squareEndRadius` (outer corner of a square end, same
verify-the-centre sweep resolution as every other arc there; must stay `<= t`
or the outline self-intersects).

**The band turns with 26, derived twice.** The inner corner is already the
flare at `edgeBarWeldFlareRadius` (20); a turn of constant material thickness
has outer = inner + thickness; the run it turns into is `edgeBarThickness` (6)
thick. 20 + 6 = 26 — which is also exactly `_weldSlabWidth / 2`, the radius the
VERTICAL frame already turns its own screen corners with.

**The bottom rail turns with 6, and that is a limit rather than a taste
call:** 6 is the largest radius a 6px run can express at its own end. A wider
turn there must be a shape spanning BOTH rails, because neither surface
reaches past its own reservation — the right rail stops at y=1434 and the
bottom rail's surface starts at y=1424. The bar's corner is bigger only
because its 50px band can hold the whole turn alone. **Flagged for the
operator:** if the two should match, the corner-patch work is the route.

## R3-3 — the flare's "missing pixels" was one row

Measured at x2530..2559, y48..79: **y=56 carried two single-pixel holes, x2554
and x2559, and every other row was solid.** y=56 is where three edges land on
the same coordinate — the flare patch's right edge, the right rail's left
edge, and the rail's own first row — each antialiased to partial coverage,
with the desktop showing through the sum. Butting geometry exactly is what
produced it, so the patch now runs to the surface's right edge; everything
past that point is territory the rail paints anyway, in the same gradient
through the same mapping, so the overlap is invisible and an overlap cannot
leave a seam. Re-measured: y=56 solid across x2540..2559.

## Round 3 gates

edgebar-path golden 123/123 · `quickshell-doctor` 28/0 · `colour-lint` 575/0 ·
`motion-lint` 814/0 · `qml-import-check` 0 unresolved/193 ·
`singleton-prop-check` 0 · `transparent-lint` 194/0. Verified in horizontal
and restored to vertical byte-identical (`reserved [0,6,50,6]`, bar
`2478,0 76x1440`).

## Round 3 — what still needs the operator

1. **The dwell itself.** The bulge renders and the signal is wired, but firing
   it needs a pointer parked on the bar's underside centre for
   `edgeBarDwellMs`, which cannot be done from the agent shell. Hover just
   below the middle of the horizontal bar and the dashboard should open.
2. **Whether the two right corners should match** — see R3-2.
