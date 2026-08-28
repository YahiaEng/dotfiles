---
plan_id: 260829-2ov
mode: quick
status: complete
date: 2026-08-29
commits:
  - 7350ce2e feat — the `cmd` command-palette route
  - b6cfc7b7 feat — weld end-glyph inset, and the horizontal weld
  - 306e47c5 fix — CommandMode needs the `../dashboard` import
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
