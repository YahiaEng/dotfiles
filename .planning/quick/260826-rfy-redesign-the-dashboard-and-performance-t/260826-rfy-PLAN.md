---
quick_id: 260826-rfy
slug: redesign-the-dashboard-and-performance-t
date: 2026-08-26
status: complete
mode: quick
---

# Quick Task 260826-rfy — Dashboard + Performance redesign study

## Objective

Produce a **design study web page** presenting several distinct, drawn-to-scale
directions for redesigning the **Dashboard** (tab 0) and **Performance** (tab 2)
panes of the Super+D drawer. The operator picks; **no QML changes in this task.**

This follows the `edge-rail-studies.html` precedent (quick task 260823-9ak /
260825-ore): render every direction rather than describing it, vendor the study
into `.planning/notes/`, and expect a plural answer.

## Why this task exists

Measured, not assumed:

| Fact | Source |
|---|---|
| Dashboard tab content column is **400px** wide | `DashboardTab.qml:288` `contentWidth: 400` |
| …inside a **760px** frame floor | `Design.qml:820` `dashboardMinWidth: 760` |
| Performance tab renders at **1040px** live | `PerformanceTab.qml` header note (14-09 Task 4 measurement) |
| So the two tabs disagree on width by **280px**, and the drawer animates the whole frame between them | `Dashboard.qml:443-444` `drawerWidth`/`drawerHeight` |
| Dashboard tab is a **single vertical column**: clock hero → calendar card → compact media → 4-dial resources strip → QuickToggles footer | `DashboardTab.qml` element skeleton |
| Performance tab is a **flat row of five 176px dials** + a network rate row | `PerformanceTab.qml`, `dialGrid.columns: 5` |

The reference has moved on from both shapes — see below.

## Reference (vendored, pinned)

`caelestia-dots/shell` @ **a788c432d9274a123c113eed6d28a241ddfc2cdd**, fetched
2026-08-26. Vendored to `.planning/notes/caelestia-dashboard/` per the
vendor-the-reference-source rule — a subagent or a later session without these
files will invent a plausible design and report it as the reference.

Structural findings read off the source, not off prose:

- **Their Dash tab is a bento `GridLayout`** (`Dash.qml`), 6 columns × 2 rows.
  Every cell is a `surfaceContainer` `Rect` with a **deliberately different
  corner radius** — `large` (DateTime, Resources), `extraLarge` (User,
  Calendar), `extraLarge * 1.5` (SmallWeather), `extraLarge * 2` (Media).
  Media spans both rows on the right.
- **Their Performance tab is cards, not dials** (`Performance.qml`): a left
  column holding a row of two `HeroCard`s (CPU, GPU) above a row of
  Storage/Network/Memory cards, plus a tall `BatteryTank` down the right side.
- `HeroCard` — small ring with the icon inside it, label + device name beside
  it, a **linear** temperature bar bottom-left, and bottom-right a **morphing
  `MaterialShape`** badge carrying the usage %: `Cookie4Sided` under 40%,
  `Sunny` 40–80%, `SoftBurst` at 80%+.
- `MemoryCard` / `StorageCard` — **270° arcs** (`startAngle: -225`,
  `sweepAngle: 270`), not full rings.
- `NetworkCard` — a **dual-line sparkline** (up + down, filled at 0.15/0.2
  alpha) over Download / Upload / Total rows.
- `BatteryTank` — a clipping rect that **fills bottom-up**, drawing its own
  contents **twice in inverted colours** so the text flips as the fill passes it.

## Tasks

1. **Vendor the reference.** Copy the 18 fetched `modules/dashboard/**` files to
   `.planning/notes/caelestia-dashboard/` with a `PROVENANCE.md` recording the
   pinned SHA, the fetch date, the file→role table, and the divergences that
   matter for us (no C++ `MaterialShape`/`SparklineItem` plugin here, no
   `Tokens` singleton — we have `Design.qml`/`Colours.qml`).

2. **Author the design study page.** Draw each direction to scale in the live
   theme's real palette (currently `dracula`, read from
   `~/.local/state/theme/palette.json`), covering both tabs. Every direction
   must state what it costs us in QML terms and what it cannot do on this stack.
   Publish as an Artifact and vendor the HTML to
   `.planning/notes/dashboard-perf-studies.html`.

3. **Record the task.** SUMMARY.md, STATE.md quick-task row, atomic commits,
   push.

## Constraints

- **No QML touched.** This task ends at a decision, not an implementation.
- Draw at real proportions — an SVG study has no compositor, and the last study
  that ignored that put a 10px inset exactly where Hyprland already puts the
  window edge (`design-study-ignores-gaps-out`).
- Any direction that needs a capability we do not have (C++ `MaterialShape`,
  `SparklineItem`, a colour quantiser) must say so **on the page**, next to the
  drawing — not in a footnote.
- Colours come from the live palette; no invented hex values.

## Done when

- `.planning/notes/caelestia-dashboard/` holds the vendored source + PROVENANCE.md
- The study page is published as an Artifact and vendored to `.planning/notes/`
- Every direction is drawn, not described, and carries its own cost line
- SUMMARY.md written, STATE.md updated, commits pushed
