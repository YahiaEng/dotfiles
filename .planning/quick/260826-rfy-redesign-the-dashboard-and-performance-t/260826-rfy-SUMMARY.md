---
quick_id: 260826-rfy
slug: redesign-the-dashboard-and-performance-t
date: 2026-08-26
status: complete
mode: quick
artifact: https://claude.ai/code/artifact/5bcd0725-ecf7-4a81-b3b5-20b6a57e31a9
---

# 260826-rfy — Dashboard + Performance redesign study

**Deliverable: a decision, not a diff.** No QML was touched. The study page is
published as an Artifact and vendored to `.planning/notes/dashboard-perf-studies.html`.

## What shipped

| Artifact | Path |
|---|---|
| Design study (7 plates + 2 current-state plates) | `.planning/notes/dashboard-perf-studies.html` → [artifact](https://claude.ai/code/artifact/5bcd0725-ecf7-4a81-b3b5-20b6a57e31a9) |
| Vendored reference source, 18 files | `.planning/notes/caelestia-dashboard/` |
| Reference provenance + port analysis | `.planning/notes/caelestia-dashboard/PROVENANCE.md` |

Directions offered: **P1** Caelestia Cards · **P2** Weighted Arcs · **P3**
Telemetry Strip · **P4** Tighten What's There · **D1** Caelestia Bento ·
**D2** Two Lanes · **D3** Wide Column.

## THE REFERENCE MOVED, AND OUR CODE STILL CITES THE OLD ONE

`PerformanceTab.qml`'s round-2 comment says its dial cluster follows "the
Caelestia reference's compact-gauge-cluster composition", and 14-10 cites their
`Performance.qml` `gpuCard` for an icon choice. **At the pinned SHA that
composition does not exist upstream.** Their Performance tab is now
`HeroCard` ×2 + Storage/Network/Memory cards + a `BatteryTank` — there is no
dial row anywhere in it.

So the in-tree comments describing the reference are **historical, not current**,
and were never wrong when written. This is the drift class the repo already
names: a reference that stops matching reality does not go red, it goes quietly
stale. Recorded at the top of `PROVENANCE.md` so the next reader does not
"restore parity" with a shell that no longer looks like that.

## FOUR MEASUREMENTS DECIDED THE WHOLE STUDY

Every direction on the page is shaped by these, and none of them came from a
screenshot.

1. **400 in 760.** `DashboardTab.qml:288` `contentWidth: 400` inside
   `Design.qml:820` `dashboardMinWidth: 760` — **180px of dead margin on each
   side**, permanently. The frame is correctly wide (it has to fit a 4-tab
   header); the content simply never grew into it. Plate D-0 hatches the gap.
2. **1040 vs 760.** Performance measures 1040, Dashboard 760, and
   `Dashboard.qml:443` binds `drawerWidth` to the active tab — so the window
   animates 280px wider and back on every crossing. This is why the page insists
   the two tabs be **picked as a pair**, and why the comparison table has a
   "fixes the jump?" column that is answered by the *combination*, not the plate.
3. **One container tint.** `Colours.qml` exposes **19 roles, no helper
   functions, and no `surfaceContainer`** — and on dracula `surfaceVariant`,
   `primaryContainer` and `secondaryContainer` are all byte-identical `#44475a`.
   Caelestia's bento separates six cells using `m3surfaceContainer` sitting
   *between* surface and surfaceVariant. **We do not generate that role.** This
   is the same shape as the 14-10 finding where a GPU ring in `primaryContainer`
   turned out invisible against its own track — measured then, still true now.
4. **No rounding scale.** `Design.qml` carries scattered per-surface radii
   (`popoutCornerRadius: 20`, `attachedCornerRadius: 24`, the drawer's 28) but no
   shared scale. The bento's whole separation trick is four different radii
   across six cells, so D1 cannot be built without adding one.

Findings 3 and 4 are the reason D1 carries a blocker note rather than a
recommendation: **the most faithful direction is the one with an unanswered
prerequisite**, and that is better surfaced on the page than discovered in
execution.

## A PORTING CONFLICT THE REFERENCE CANNOT RESOLVE FOR US

Caelestia gates `BatteryTank` on `UPower.displayDevice.isLaptopBattery` — on a
desktop it does not render and the layout closes up around it. **Our D-41 rule
says the opposite**: always show the slot at a fixed footprint, which is exactly
why P-0 carries a permanent "No battery" dial today. Porting P1 faithfully means
either overturning D-41 or drawing a 104px column of nothing forever. Surfaced on
the plate as a decision to take *before* picking it, not a detail to hit later.

## DRAWN, NOT DESCRIBED — AND AT ONE SHARED SCALE

Every plate is real px at 1:1 with a single `transform: scale(0.60)` over the
whole board, so **the numbers in the CSS are the spec numbers** and a 760 frame
is visually smaller than a 1040 frame on the page. A per-plate scale would have
made the 280px width disagreement — the second finding above — invisible, which
would have hidden the very thing the study exists to show.

Both current states (P-0, D-0) are drawn too. Without them the alternatives have
nothing to be better *than*.

## Deliberately not done

- **No QML.** The task ends at a decision.
- **No recommendation of one winner.** The page closes with four pairings keyed
  to what the operator might actually want (reference fidelity / gain-per-work /
  answering a question / defects gone). The expected answer here is plural.
- **No live verification.** Nothing was restarted and nothing was screenshotted;
  the study is derived from source and the live `palette.json`, both read
  directly.

## Follow-on, if a direction is picked

| Picked | Prerequisite that must land first |
|---|---|
| D1 (bento) | a `surfaceContainer` role in the theme pipeline **and** a rounding scale in `Design.qml` |
| P1 (cards) | container tint; device-name fields on `SystemResources`; a D-41 ruling on the battery slot |
| P3 (telemetry) | ring buffers on `SystemResources`; measure repaint cost against OVER-04's 2.4× headroom rather than assuming it |
| P2 / P4 / D2 / D3 | nothing — layout only |

---

# Stage 2 — the operator picked D2 + P3, and they are now built

Operator's decision 2026-08-26: **D2 + P3 first**, plus a setting to switch
between P1/P2/P3 and D1/D2. This half implements the picks and the switch
mechanism; P1, P2 and D1 are the remaining work.

## A correction to this study's own cost tags

The page tagged **P2 and D1 with "needs a container tint"**. That overstated
it. The real constraint is narrower and was found by reading `Dial.qml`:
its unfilled arc is drawn in `Colours.surfaceVariant`, so a ring placed
*inside* a `surfaceVariant` card disappears — which is the 14-10 finding
exactly, not a missing palette role. **Fixed by drawing in-card tracks as an
alpha overlay on `onSurface`**, which is what `PerfTelemetry.qml`'s `BarTile`
now does. All five layouts are therefore buildable with no theme-pipeline
change. A real `surfaceContainer` would make D1 richer; it is not a
prerequisite. The one genuine blocker left is the D-41 battery ruling, and it
gates only P1.

## What shipped

| Commit | Contents |
|---|---|
| `3ee70c11` | `SystemResources` history buffers + the two `dashboard.layout.*` prefs |
| `8c36565c` | `Sparkline.qml`, `PerfTelemetry.qml` (P3), `DashLanes.qml` (D2), qmldir, Loader switch |
| `1257a8e8` | The two Appearance pickers + their RowIndex entries |

Defaults are `lanes` and `telemetry`. The previous layouts stay registered and
selectable as `column` and `dials`.

## THE SWITCH LIVES AT THE LOADERS, NOT INSIDE THE TABS

`Dashboard.qml`'s two tab Loaders resolve the pref and pick a Component; a
layout file knows nothing about being one of several. That is what makes P1,
P2 and D1 purely additive later — each is a new file plus one `qmldir` line
plus one branch, with no edit to a sibling layout.

**The old layouts were deliberately NOT deleted.** A layout Loader whose
component fails to load leaves an empty pane, not a dead shell — so `column`
and `dials` are the way back out of a bad render, and they are reachable from
the settings picker without a restart. Deleting them would have removed the
only recovery path from a change nobody can verify from the agent shell.

## TWO SIZING BUGS THAT MEASURING CAUGHT, NOT REASONING

1. **A fixed content height would have overlapped the toggles.**
   `QuickToggles.implicitHeight` is `chipsRow(72) + spacingSm + presetRow` —
   about 120, not the ~44 the first draft's fixed 440 left for it. The
   toggles are bottom-anchored and the resources card is top-anchored, so
   they would have collided by roughly 76px. `DashLanes` now **derives**
   `contentHeight` from the right lane's real requirement with a floor for
   the calendar. The loop worry this raises is already answered by precedent:
   `DashboardTab.qml:351` feeds `toggles.implicitHeight` into its own
   `implicitHeight` today and ships fine.
2. **Width parity is real; height parity is not achievable statically.**
   Both layouts declare `contentWidth: 712`, which lands `drawerWidth`
   exactly on its 760 floor and closes the 280px crossing animation. But
   because `DashLanes` must derive its height from a runtime
   `implicitHeight`, `PerfTelemetry` cannot match it with a constant. The
   drawer still animates its *height* a little between these two tabs.
   Recorded in both files' headers rather than quietly left as an implied
   full fix.

## THE CALENDAR IS DUPLICATED ON PURPOSE

`DashLanes` reproduces the column layout's date arithmetic — locale
first-day-of-week, the fixed 42-cell six-row grid, the Friday weekend rule,
and the `firstDayOfWeek` 0-6 Sunday-based vs `dayName` 1-7 Monday-based
split that `DashboardTab.qml` records as verified live rather than assumed.
Extracting it into a shared component would have meant **editing the working
column layout in the same commit that introduces an unverifiable new one**.
The two must now be changed together until `column` is retired, at which
point the duplication resolves itself. Stated in the file header so it is a
known debt, not a discovery.

## Verified statically; NOT verified live

Green: `colour-lint` 434/0, `motion-lint` 621/0, `settings-index-check`
180/0, `qmllint` clean on every touched file, brace/paren balance, and a
reference-resolution pass confirming every `Design.*`, `Motion.*`,
`systemResources.*`, `mediaBackend.*` and `weatherBackend.*` name used in the
new files exists on its target.

**None of that can see a QML import error or a layout defect** — the repo's
own standing finding. The gates were also checked for whether they actually
*saw* the new files rather than skipping them, since a green gate only proves
what it can reach. Nothing was restarted: restarting quickshell from the
agent shell has killed this session three times.

**Operator verification needed:** restart the shell, open Super+D. Expect the
Dashboard tab in two lanes and the Performance tab as three graphs plus two
bars. The graphs need roughly two poll intervals before they draw anything —
"Collecting…" is the correct first state, not a defect. Settings →
Appearance → Dashboard drawer switches either tab back.

## Remaining

| Plate | Work left |
|---|---|
| P2 Weighted Arcs | add `startAngle`/`sweepAngle` to `Dial.qml` (it hardcodes `-90`/`360 * value`), then the layout |
| P1 Caelestia Cards | device-name field on `SystemResources` (`gpuName` already exists, no CPU equivalent), a hand-rolled morphing badge, and **a D-41 ruling on the battery slot** |
| D1 Bento | a rounding scale in `Design.qml`; optionally a real `surfaceContainer` role for richer separation |
