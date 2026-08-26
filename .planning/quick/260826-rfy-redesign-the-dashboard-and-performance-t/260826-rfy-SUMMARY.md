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
