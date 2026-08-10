# Phase 14: Dashboard Drawer - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-29 (session started 2026-07-28)
**Phase:** 14-dashboard-drawer
**Areas discussed:** Drawer geometry & summon, Weather backend, Quick-toggle grid & shared state, Tab content & data depth, Entrance choreography, Coexistence policy, Empty-state designs, Namespace & inheritance

**Session-level notes:**
- The user requested deep pros/cons analysis with an explicit recommendation for EVERY decision, repeatedly reinforcing this when analyses were too shallow. Several questions were re-litigated at greater depth on request (wraparound, degraded-state, toggle set, kbd nav, attachment).
- Mid-discussion the user stated a standing lens: **bias toward end-4 (dots-hyprland) and Caelestia shell conventions** on every close call. This reversed one already-made recommendation (theme chip) and decided iconography and choreography. Saved to auto-memory (`reference-shell-bias`).
- Second stated principle: **deprecated-bound software (swaync/walker/wleave, v4.0 targets) should get minimal engineering attention** — reshaped the coexistence decision.
- The user overrode a recommendation once: weather units (chose state-file field over fixed metric).
- One recommendation was self-revised mid-flow: motion control changed from "cycle chip" to "segmented row" after the truth-model decision exposed the theme-apply-per-transition cost; the user also probed the aesthetics before accepting.
- The user probed Open-Meteo data quality in free text before locking the provider.

---

## Drawer geometry & summon (20 decisions)

| # | Question | Options | Selected |
|---|----------|---------|----------|
| 1 | Screen placement | Top drop-down / Centered overlay / Side panel | Top drop-down (rec) |
| 2 | Summon keybind | Super+D / Super+A / Super+G | Super+D (rec) |
| 3 | Dismissal set | Toggle+Esc+click-out / Toggle+click-out / Click-out only | Toggle+Esc+click-out (rec) |
| 4 | Fullscreen refusal | Silent true-fullscreen only / Silent any mode / Refuse+notify | Silent true-fullscreen only (rec) |
| 5 | Size | Compact ~40% / Wide ~55% / Full-width strip | Compact ~40% (rec) |
| 6 | Open/close animation | Slide from top / Global popin / Fade | Slide from top (rec) |
| 7 | Background treatment | House translucent+blur / Solid / Extra glassy | House translucent+blur (rec) |
| 8 | Lifecycle | Destroy+tab memory / Hide keep-alive / Destroy+home tab | Destroy+tab memory (rec) |
| 9 | Tab header design | Icon+label / Icons only / Text only | Icon+label (rec) |
| 10 | Swipe commit | 1/3-or-flick / Strict 50% / Hair-trigger | 1/3-or-flick (rec) |
| 11 | Edge attachment | Flush bottom-rounded / Floating all-rounded / Flush+inverse corners | Flush bottom-rounded (rec after user asked for elaboration; recommendation revised from floating once layer-shell reservation mechanics were checked) |
| 12 | Keyboard nav | Arrows cycle / Arrows+1-4 / Mouse only | Arrows cycle (rec; re-litigated deeper on request) |
| 13 | Header position | Top / Bottom | Top (rec) |
| 14 | Arrow wraparound | Clamp / Wrap / Hybrid | Clamp (rec; re-litigated much deeper on request — traversal math, kitty/browser precedent split, PathView cost) |
| 15 | Height policy | Fixed / Adaptive | Fixed (rec) |
| 16 | Overflow | No-scroll design-to-fit / Scroll allowed | No-scroll design-to-fit (rec) |
| 17 | Tab order | Dash-Media-Perf-Weather / Dash-Weather-Media-Perf / Dash-Perf-Media-Weather | Roadmap order (rec) |
| 18 | Focus on summon | Grab / Passive | Grab (rec) |
| 19 | Scrim | None / Light ~20% | None (rec) |
| 20 | Density | MD3 comfortable / Compact / Split | MD3 comfortable (rec) |

**Notes:** #11 — user asked "elaborate on flush + bottom rounded"; deeper analysis found layer-shell reservation handling makes per-layout offsets unnecessary, flipping the recommendation to flush. #12/#14 — user twice asked for deeper pros/cons before answering.

---

## Weather backend (5 decisions)

| # | Question | Options | Selected |
|---|----------|---------|----------|
| 21 | Provider | Open-Meteo / MET Norway / wttr.in / OpenWeatherMap | Open-Meteo (rec; user probed data quality first — model-aggregator answer accepted) |
| 22 | Location source | Seeded state-file / GeoIP / GeoIP-seeded hybrid | Seeded state-file (rec) |
| 23 | Units | Fixed metric / State-file field / Locale | **State-file field — USER OVERRODE the fixed-metric recommendation** |
| 24 | Refresh | TTL cache+on-summon / Perpetual poll / Per-summon fetch | TTL cache+on-summon (rec) |
| 25 | Degradation | Age badge calm / Error banner+dim / Placeholder past TTL | Age badge calm (rec; re-litigated deeper on request — 4-scenario walkthrough, state matrix) |

---

## Quick-toggle grid & shared state (7 decisions)

| # | Question | Options | Selected |
|---|----------|---------|----------|
| 26 | Toggle set | 3 mirrored + motion / 3 exactly / 4+ | 3 mirrored + motion (rec; re-litigated deeper on request — per-toggle mechanics table, deferral-history argument) |
| 27 | Truth model | Truth-driven+pending / Optimistic+revert / Fire-and-forget | Truth-driven+pending (rec) |
| 28 | Chip form | Uniform labeled / Icon-only / Switch rows | Uniform labeled (rec) |
| 29 | Motion control form | Segmented row / Cycle skip-off / Cycle full | Segmented row (rec — REVISED from decision 26's cycle framing after theme-apply-per-transition cost surfaced; user asked "which is better aesthetically" and accepted after the aesthetic analysis) |
| 30 | Theme chip label/lit | Dark+flip swaync / Light lit=light / Dark, disagree | **Dark+flip swaync — recommendation REVERSED by the user's reference lens** (initial rec was Light lit=light; user stated the end-4/Caelestia bias at this question) |
| 31 | Icon system | Material Symbols for QML / Nerd Font everywhere / MS everywhere | Material Symbols for QML (rec under lens) |
| 32 | Chip order | Mirror swaync / Frequency / Redesign both | Mirror swaync (rec) |

---

## Tab content & data depth (7 decisions)

| # | Question | Options | Selected |
|---|----------|---------|----------|
| 33 | Calendar | Display-only month / Events integration / Month+todo | Display-only month (rec) |
| 34 | Media tab | MD3 full player / Mirror AGS card / Minimal strip | MD3 full player (rec; no-QS-Mpris + no-payload-extension fences recorded) |
| 35 | Performance tab | 4 dials+net rates / Sparklines / Bar rows | 4 dials+net rates (rec) |
| 36 | Weather tab | Hero+8h+5day / Hero+5day / Hero+hourly | Hero+8h+5day (rec) |
| 37 | Dashboard layout | Clock hero→toggles footer / Toggles first / Two-column | Clock hero→toggles footer (rec) |
| 38 | Resources strip | CPU-Mem-Battery mini-dials / Text line / All five | CPU-Mem-Battery mini-dials (rec) |
| 39 | Compact media | Art+play-pause+deep-link / Full mini-transport / Pure display | Art+play-pause+deep-link (rec) |

---

## Follow-up areas (4 decisions)

| # | Question | Options | Selected |
|---|----------|---------|----------|
| 40 | Entrance choreography | Summon-only cascade / Settled block / Cascade everywhere | Summon-only cascade (rec under lens) |
| 41 | Coexistence | Focus-loss dismiss only / +close-CC line / No policy | Focus-loss dismiss only (rec — REFRAMED by user: "software that we will deprecate should not get much attention"; original auto-close-CC recommendation withdrawn) |
| 42 | Empty states | In-place placeholders / Collapse-reflow / +First-run hints | In-place placeholders (rec) |
| 43 | Namespace | quickshell-* prefix+regex / Bare per-surface / One shared | quickshell-* prefix+regex (rec) |

---

## Claude's Discretion

Pager component choice (SwipeView-class; PathView excluded), exact pixels /
radii / label abbreviations / Material Symbol picks, weather fetch
implementation + cache format + exact TTL + badge thresholds, performance
read mechanism + poll cadences, stagger token name + cascade timings within
fences, tab-memory persistence scope, plan/wave decomposition (coarse).

## Deferred Ideas

Todo widget; calendar events integration; Dashboard weather chip; number-key
tab jumps; inverse-corner melt; floating-waybar corner patch;
`swaync-client -cp` one-liner; media payload extensions; Performance
sparklines; graphical weather-location picker. Six named research items
recorded in CONTEXT.md `<deferred>`.
