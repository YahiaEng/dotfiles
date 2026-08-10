# Phase 14: Dashboard Drawer — Plan Outline

**Drafted:** 2026-07-29
**Granularity:** coarse · **Tracer mode:** on · **MVP mode:** off · **Reversibility gates:** on
**Plans:** 9 across 5 waves

Chunked planning: this outline is the contract each per-plan chunk task expands into a
`14-NN-PLAN.md`. Sections after the table are binding on the chunk planners — the audits,
prohibitions, edge lift and artifact list below must land in the plans they are assigned to.

---

## Plan Table

| Plan ID | Objective | Wave | Depends On | Requirements |
|---------|-----------|------|------------|--------------|
| 14-01 | **TRACER** — Super+D summons a `quickshell-dashboard` overlay drawer end-to-end: shortcuts manifest → Lua keybind → shell-root `LazyLoader` → `PanelWindow` with locked geometry (top drop-down, centered, flush, ~850×860, bottom corners only), family + per-surface layer rules (blur / ignore_alpha / slide), `OnDemand` + `HyprlandFocusGrab`, Esc + click-outside + focus-loss dismiss, destroy-on-dismiss, silent fullscreen refusal, one placeholder pane. Proven live via `hyprctl layers -j` (present when open, absent when dismissed, zero exclusive zone). | 1 | — | DASH-01, DASH-08 |
| 14-02 | **Foundations** (no QML-surface dependency) — Material Symbols Rounded AUR entry behind a blocking `[SUS]` package-legitimacy human checkpoint plus a live FILL-axis render proof; `motion.json` `semantic.stagger-offset` token wired through `Motion.qml`'s `_pairNames`; weather location/units state file seeded by `stow.sh` (flat top-level keys, city-level coords, metric) and both weather files registered in `contract.json` `engine_owned_files`. | 1 | — | DASH-06 |
| 14-03 | **Four-tab pager** — `TabBar` header (icon+label, indicator tracks swipe progress) one-way-synced to a `SwipeView`; drag-threshold commit with spring-back below threshold; arrow keys clamped at both ends; selected-tab memory at the shell root; the stock `highlightMoveDuration: 250` literal replaced by `Motion.*` token consumption; fixed frame height across all four panes; the four tab shell files + every `modules/dashboard/` type registered in one checked-in `qmldir`, each carrying the D-41 populated/pending/empty placeholder register. | 2 | 14-01 | DASH-02 |
| 14-04 | **Quick-toggle grid** — three swaync-mirrored chips (Gaming, DND, Dark) execing the exact same commands and watching the exact same state sources swaync uses, on D-22's truth-driven pending model (instant ripple, committed state only on confirmed backend change, disabled while pending, quiet timeout revert); the full-width `Off \| Reduced \| Normal \| Lively` motion-scale segmented row; swaync's theme-toggle boolean direction flipped with its icon/label together; mounted as the Dashboard tab's footer. Resolves the `swaync-client --subscribe` research item with a documented polling fallback. | 3 | 14-03, 14-02 | DASH-07 |
| 14-05 | **Media tab** — one shared `MediaBackend` `Process` streaming `media-status.sh watch`'s existing JSON-per-line payload (no payload extension, no second `Process`), all transport routed through `media-players.sh`; MD3 full player: large cover art, type stack, seek slider, Material Symbols transport, volume, player-switcher chips; per-field partial-metadata fallbacks and the "Nothing playing" empty state. Carries the `<assumption_delta_decision>` block. | 3 | 14-03, 14-02 | DASH-04 |
| 14-06 | **Performance tab** — the custom `Dial` arc component (no built-in gauge exists), a `/proc`+`/sys` resource reader polling only while the drawer is open (~1-2s CPU/mem/net, ~30s storage/battery) with light CPU smoothing, `Quickshell.Services.UPower` for battery with exact property names read from the installed qmltypes, four dials plus an honest network up/down rate row. The no-battery-hardware populated path is proven by fault injection, not assumed. | 3 | 14-03, 14-02 | DASH-05 |
| 14-07 | **Weather tab** — `WeatherBackend` isolating every Open-Meteo call in one file (one request feeds all three bands), ~15-min TTL, fetch-on-summon-only-when-stale, refresh timer alive only while open, last-good response persisted to disk; WMO→Material Symbol map written once; unit-aware formatting; current hero + fixed non-scrollable 8-column hour strip + 5-day row; calm stale-as-normal degradation with the "updated Nh ago" badge, proven able to fail by backdating the cache. | 3 | 14-03, 14-02 | DASH-06 |
| 14-08 | **Dashboard tab composition** — identity-first single column: clock/date hero → display-only calendar month grid (today highlighted, chevron + scroll-wheel month navigation, never bare arrows) → compact media widget (art + title/artist + play-pause only, rest of the widget deep-links to the Media tab) → resources strip (CPU/Memory/Battery mini-dials deep-linking to the Performance tab) → the toggle block already footing the tab. Establishes the compact-widget → its-full-tab deep-link convention. | 4 | 14-04, 14-05, 14-06 | DASH-03 |
| 14-09 | **Cascade + phase close** — the summon-only staggered entrance cascade consuming the new stagger token, fenced off tab switches and collapsing under reduced/off motion scale; the D-05 no-scroll / ~10-15% slack judgment across themes and fonts; full gate sweep (`motion-lint`, `keybind-doctor`, `quickshell-doctor`, `theme-doctor`, `theme-parity`); the three-reader MPRIS simultaneity proof, the DASH-07 side-by-side against swaync's grid, and the blocking human render-and-look gate across all four tabs. | 5 | 14-08, 14-07 | DASH-01, DASH-02, DASH-03, DASH-04, DASH-05, DASH-06, DASH-07, DASH-08 |

**Wave shape:** W1 `14-01` ‖ `14-02` → W2 `14-03` → W3 `14-04` ‖ `14-05` ‖ `14-06` ‖ `14-07` → W4 `14-08` → W5 `14-09`.

**Wave-3 parallelism is real** — the four plans share zero `files_modified` because 14-03 creates
every `modules/dashboard/` stub and owns the subdirectory `qmldir` outright. No wave-3 plan may
edit `qmldir`; if a chunk planner finds it needs a type 14-03 did not declare, that is a 14-03
scope correction, not a wave-3 edit.

---

## Requirement Coverage

| Requirement | Plans |
|---|---|
| DASH-01 | 14-01, 14-09 |
| DASH-02 | 14-03, 14-09 |
| DASH-03 | 14-08, 14-09 |
| DASH-04 | 14-05, 14-09 |
| DASH-05 | 14-06, 14-09 |
| DASH-06 | 14-02, 14-07, 14-09 |
| DASH-07 | 14-04, 14-09 |
| DASH-08 | 14-01, 14-09 |

All 8 phase requirement IDs covered. No plan carries an empty `requirements` field.

---

## Multi-Source Coverage Audit

Every item below is COVERED. No gaps, no deferrals, no scope reductions.

### GOAL — ROADMAP Phase 14 success criteria

| Item | Plan |
|---|---|
| G1 keybind opens / click-outside dismisses / desktop stays interactive / zero exclusive zone on any waybar edge | 14-01 |
| G2 four tabs reachable by drag-with-threshold-commit **and** direct header tap | 14-03 |
| G3a Dashboard tab: calendar, date/time, compact media, resources at a glance | 14-08 |
| G3b Media tab: full player with cover art | 14-05 |
| G3c Performance tab: CPU, memory, network, storage, battery | 14-06 |
| G3d Weather tab: current + forecast, readable rather than blank/broken when unreachable | 14-07 |
| G4 AGS card + waybar + dashboard show the same track simultaneously; no second media backend | 14-05, 14-09 |
| G5a dashboard quick-toggle ⇄ swaync grid agree, no second source of truth | 14-04, 14-09 |
| G5b neither dashboard nor panel opens over a fullscreen client | 14-01 |
| Owns: "overlay by default, zero exclusive zone" layer convention Phases 15/16 inherit | 14-01 |
| Owns: shared-state pattern for anything the desktop already tracks | 14-04, 14-05 |

### RESEARCH — features, constraints, pitfalls

| Item | Plan |
|---|---|
| `LazyLoader` + `GlobalShortcut` summon/dismiss reused verbatim from the probe | 14-01 |
| `OnDemand` + `HyprlandFocusGrab` reused verbatim (closes D-12's research item) | 14-01 |
| GlobalShortcut needs a Quickshell process restart to register (Pitfall 6) | 14-01 |
| Regex namespace matching unverified on this build — ship regex, keep exact-match fallback in the same commit (A2) | 14-01 |
| `SwipeView` + `TabBar` one-way sync; `PathView` rejected; Caelestia's `Flickable` pager deliberately not copied | 14-03 |
| `SwipeView`'s hardcoded `highlightMoveDuration: 250` overridden (Pitfall 1) | 14-03 |
| Lazy per-tab `Loader` so off-screen tabs run no timers/fetches (Pattern 4) | 14-03 |
| Stock drag-threshold feel judged at a render gate before any custom override (A5, OQ5) | 14-03, 14-09 |
| `motion.json` `semantic` bucket only — `indicators` is invisible to motion-lint (Pitfall 4) | 14-02 |
| `Motion.qml` `_pairNames` does not auto-discover new semantic keys | 14-02 |
| `[SUS]` AUR package → blocking human-verify before install; vendor-the-TTF fallback | 14-02 |
| `font.variableAxes` FILL axis unverified with this font on this Qt build (A3) | 14-02 |
| `JsonAdapter` maps top-level keys only → flat weather state schema (Pitfall 5) | 14-02, 14-07 |
| `Quickshell.Services.Mpris` is installed, importable and forbidden (Pitfall 2) | 14-05 |
| One shared media `Process`, never one per tab | 14-05, 14-08 |
| Command injection: every transport action through `media-players.sh`, never raw interpolated `playerctl` | 14-05 |
| `Quickshell.Services.UPower` over hand-parsed sysfs | 14-06 |
| `UPowerDevice` property names read from the installed qmltypes, not assumed (A4, OQ3) | 14-06 |
| No battery hardware → populated path proven by fault injection, decision recorded not silently skipped (Pitfall 3, OQ4) | 14-06 |
| No built-in circular gauge exists — budget the dial as real custom work | 14-06 |
| Caelestia's `ip-api.com` GeoIP fallback must not be reintroduced (Pitfall 7) | 14-07 |
| WMO code → symbol map written once, reused across all three bands | 14-07 |
| Weather cache shape/location/TTL/badge thresholds resolved (OQ6) | 14-02, 14-07 |
| `swaync-client --subscribe` unverified on 0.12.6 → attempt, fall back to polling `-D` while open (OQ1) | 14-04 |
| Security V5: try/catch every `JSON.parse`, default-safe fallback, numeric validation of hand-editable lat/lon | 14-05, 14-07 |

### CONTEXT — locked decisions D-01..D-43

| Decisions | Plan |
|---|---|
| D-01, D-02, D-03, D-04, D-07, D-08, D-42, D-43 (geometry, surface treatment, namespace, layer posture) | 14-01 |
| D-09, D-10, D-11, D-12, D-13, D-14, D-20 (summon, dismiss, focus, coexistence, lifecycle, slide rule) | 14-01 |
| D-28 (Material Symbols icon system), D-30, D-31 (location + units state axis) | 14-02 |
| D-21 stagger token definition (consumption in 14-09) | 14-02 |
| D-05, D-06, D-15, D-16, D-17, D-18, D-41 (no-scroll, spacing, tab order/header/physics/clamp, empty-state vocabulary) | 14-03 |
| D-22, D-23, D-24, D-25, D-26, D-27 (pending model, grid composition, segmented row, chip styling, swaync flip, backend truth table) | 14-04 |
| D-35 (Media tab + its two hard fences) | 14-05 |
| D-36 (Performance tab, poll cadences, boundary against trend views) | 14-06 |
| D-29, D-32, D-33, D-37 (provider, refresh, degradation, weather tab layout) | 14-07 |
| D-34, D-38, D-39, D-40 (calendar, tab order, resources strip, compact media + deep-link convention) | 14-08 |
| D-21 cascade implementation and its fences | 14-09 |
| D-19 (number keys 1-4 NOT bound) | *deliberate non-implementation — correctly absent from every plan* |

---

## Assumption-Delta Checkpoint

Detector: `assumption-delta scan 14 --json` → `detected: true`, one `pluralization` signal on the
term "second" in *"…and no second media backend exists."*

Chunk planner for **14-05** must emit this block verbatim into `14-05-PLAN.md`:

```
<assumption_delta_decision>
Noun now primary: media backend (singular, and required to stay singular).
Decision: no-change.
Rationale: the detector fired on a prohibition, not a pluralization pressure. DASH-04 and
D-35 make singularity a hard requirement — the drawer becomes a third *reader* of the one
`media-status.sh` backend, never a second backend. `Quickshell.Services.Mpris` is installed
and importable on this machine, which is exactly why the fence is written as a prohibition
rather than left to judgement. Nothing is promoted and nothing is added alongside.
Suggested invariant test: a repo-wide grep asserting zero `Quickshell.Services.Mpris`
imports under `quickshell/`, run as part of the phase gate sweep.
</assumption_delta_decision>
```

---

## Spec-less Probe Fallback

This phase has no SPEC.md (`EDGE_ABSENT`, `PROHIB_ABSENT`). Lifts below are binding.

### Edge coverage lift → `must_haves.truths`

| Requirement | Category | Disposition | Lands in |
|---|---|---|---|
| DASH-02 | boundary | **covered** — "A drag released just past the commit threshold advances exactly one tab; a drag released just below it springs back to the current tab; `Left` at index 0 and `Right` at index 3 are no-ops that do not wrap." | 14-03 |
| DASH-02 | precision | **backstop** — `{ statement: "Swipe progress driving the tab indicator neither overshoots past the final tab's indicator position nor leaves a sub-pixel gap at rest at any of the four indices", verification: backstop }` | 14-03 |
| DASH-05 | concurrency | **covered** — "Dismissing the drawer mid-poll stops every resource timer; no poll callback runs against a destroyed tab, and reopening restarts polling from a clean read rather than a stale partial sample." | 14-06 |
| DASH-07 | idempotency | **covered** — "Pressing an already-pending chip a second time is a no-op: the chip is disabled while pending, so a double press issues exactly one backend command and the grid converges to one committed state." | 14-04 |
| DASH-07 | concurrency | **backstop** — `{ statement: "When the drawer chip and swaync's own grid button are actuated in quick succession, both grids settle on the single backing state value rather than diverging", verification: backstop }` | 14-04 |

**Unresolved edges — flagged planner assumptions, carried into the plans, not dropped.**
The probe classified these five rows `unclassified`; per the fallback rules an `unclassified`
row is never auto-backstopped and never auto-dismissed. Each owning plan records it as an
explicit assumption in its `must_haves`:

- **DASH-01** (14-01) — no edge category derived; the summon/dismiss path's edge behaviour is
  covered by the tracer's live `hyprctl layers -j` assertions but has no probe-derived predicate.
- **DASH-03** (14-08) — no edge category derived for the composition tab.
- **DASH-04** (14-05) — no edge category derived; the three-reader simultaneity proof in 14-09 is
  the nearest evidence but is not a probe predicate.
- **DASH-06** (14-07) — no edge category derived; D-33's stale/never-cached thresholds are
  decision-sourced, not probe-sourced.
- **DASH-08** (14-01) — no edge category derived for the fullscreen-refusal guard.

### UI-SPEC `## UI Considerations` lift

27 covered / 4 backstop / 15 dismissed / 0 unresolved. Every covered consideration becomes a
plain `must_haves.truths` string in its owning plan; the four backstops become flat-scalar
markers with `verification: backstop`:

| Backstop | Lands in |
|---|---|
| Long real-world track title/artist elides single-line without breaking the fixed frame | 14-05 |
| Weather condition strings and forecast day labels do not overflow their fixed hour/day cells | 14-07 |
| Network rate row holds width at worst-case values (fixed-width formatting, no reflow) | 14-06 |
| Compact media widget title elides correctly at compact width | 14-08 |

Covered-consideration ownership: drawer chrome/tab-bar and overflow rows → 14-03; media
empty/partial/loading rows → 14-05 and 14-08; weather empty/stale/partial rows → 14-07;
performance partial/battery-absent rows → 14-06; toggle pending/error/zero-one-many rows → 14-04.

### Prohibitions → `must_haves.prohibitions` (descriptor-less, `status: flagged-unverified`)

Recalled per the two-stage prohibition protocol; none may be auto-dismissed. Each lands in the
plan named, and 14-09 re-asserts the repo-wide ones at the gate sweep.

| Prohibition | Plan |
|---|---|
| No `import Quickshell.Services.Mpris` anywhere in drawer QML | 14-05, 14-09 |
| No second media backend; no MPRIS state re-derived in QML | 14-05 |
| No raw `playerctl` invocation constructed in QML with an interpolated player id | 14-05 |
| No `media-status.sh` payload extensions this phase | 14-05 |
| No hex colour literal in any repo-authored drawer QML | all QML plans, 14-09 |
| No raw duration or easing literal in any repo-authored drawer QML | all QML plans, 14-09 |
| No second source of truth for toggle state — no new state file for gaming/DND/dark | 14-04 |
| No vertical scrolling in any of the four tabs | 14-03, 14-09 |
| No `PathView` pager and no tab wraparound | 14-03 |
| No GeoIP / `ip-api.com`-class location lookup | 14-07 |
| No API key and no precise home coordinates committed to the repo | 14-02, 14-07 |
| No background scrim behind the drawer | 14-01 |
| No exclusive zone on any edge waybar reserves | 14-01 |
| No notification or visible feedback on fullscreen refusal | 14-01 |
| No edits to walker or wleave; no swaync edit beyond D-26's one-line flip | 14-04 |
| No quickshell step added to the theme reload fan-out | 14-09 |
| No sparkline or trend-history view on the Performance tab | 14-06 |
| No hand-parsed `/sys/class/power_supply` battery path while UPower is available | 14-06 |
| No install of the `[SUS]`-flagged font package before its human legitimacy checkpoint passes | 14-02 |

---

## Artifacts this phase produces

Symbols created by Phase 14 — the source-grounding pass must exclude these from drift verification.

**New QML types** (each declared in a checked-in `qmldir` in the same commit that creates it):
`Dashboard`, `DashboardTab`, `MediaTab`, `PerformanceTab`, `WeatherTab`, `MediaBackend`,
`WeatherBackend`, `QuickToggles`, `Dial`, `SystemResources`

**New file paths:**
- `quickshell/.config/quickshell/modules/Dashboard.qml`
- `quickshell/.config/quickshell/modules/dashboard/qmldir`
- `quickshell/.config/quickshell/modules/dashboard/{DashboardTab,MediaTab,PerformanceTab,WeatherTab}.qml`
- `quickshell/.config/quickshell/modules/dashboard/{MediaBackend,WeatherBackend,QuickToggles,Dial,SystemResources}.qml`
- `.planning/phases/14-dashboard-drawer/COVERAGE.md` (already written)

**New identifiers / config keys:**
- `shortcuts.json` entry `{ appid: "quickshell", name: "dashboard" }`
- Hyprland global shortcut id `quickshell:dashboard`; keybind `SUPER + D`
- Layer-shell namespace `quickshell-dashboard`; family regex `^quickshell-.*`
- `motion.json` semantic key `stagger-offset`; resulting `Motion.staggerOffsetDuration` /
  `Motion.staggerOffsetEasing`; new `_pairNames` entry in `Motion.qml`
- State file `~/.local/state/theme/weather.json` — flat top-level keys `lat`, `lon`,
  `units_temp`, `units_wind`, `units_precip` (JsonAdapter maps top-level keys only)
- Cache file `~/.local/state/theme/weather-cache.json` — `fetched_at`, `lat`, `lon`, `units`, `payload`
- Two new `contract.json` `engine_owned_files` entries for the files above
- `install.sh` `AUR_PKGS` entry `ttf-material-symbols-variable-git`
- Typography constants introduced on the drawer root per the UI-SPEC type scale

**Modified existing files:** `shell.qml`, `modules/qmldir`, `modules/Motion.qml`,
`shortcuts.json`, `keybinds.lua`, `windowrules.lua`, `motion.json`, `contract.json`,
`stow.sh`, `install.sh`, `swaync/config.json`

---

## Standing Notes for Chunk Planners

**Human gates.** `config.json` sets `human_verify_mode: end-of-phase`, but ROADMAP standing
constraint 1 ("every visual surface needs a blocking human sign-off before its plan closes")
is a roadmap-level rule and wins, exactly as Phase 13's D-17 did. Plans 14-03..14-09 each carry
a `checkpoint:human-verify` render gate. 14-02's package-legitimacy checkpoint is
`gate="blocking-human"` and is never auto-approvable regardless of `auto_advance`.

**Reversibility.** No decision in this phase rates `one-way`, so no `checkpoint:decision` is
required. Two rate **costly** and their plans must say so in a `<reversibility>` block:
D-28 Material Symbols (14-02 — threads through every widget of every QML surface from here on)
and D-42 the namespace scheme (14-01 — threads through layerrules, doctor checks and DASH-01's
`hyprctl layers` verification).

**Security.** `security_enforcement` is on at ASVS level 1, blocking on `high`. Every plan
carries a `<threat_model>`. The load-bearing entries: `T-14-01` Tampering — command injection
via an interpolated player id (mitigate: route through `media-players.sh`'s `_valid_id`);
`T-14-02` DoS — malformed third-party JSON from Open-Meteo or a corrupted cache crashing the QML
engine (mitigate: try/catch every parse, default-safe empty state); `T-14-03` Tampering — a
hand-edited weather state file with non-numeric coordinates (mitigate: numeric validation before
the coordinates reach a fetch URL); `T-14-SC` Tampering — the `[SUS]` AUR font package (mitigate:
blocking human checkpoint before install, vendor-the-TTF fallback).

**Schema push gate:** no ORM schema files (Payload/Prisma/Drizzle/Supabase/TypeORM) exist in this
repo or this phase's scope. Gate skipped, correctly.

**Fenced out — must not appear in any plan.** Todo widget; calendar events integration; weather
chip on the Dashboard tab; number keys 1-4 direct jump; the concave inverse-corner melt; the
floating-waybar corner patch; `swaync-client -cp` close-on-summon; `media-status.sh` payload
extensions; Performance sparklines/trends; the graphical weather-location picker.

**User lens.** Where a design call is genuinely open, follow the end-4 (dots-hyprland) /
Caelestia convention — Material You idioms, lit tonal tiles, Material Symbols, staggered
entrances. This user asked for deep pros/cons plus a recommendation at every decision point and
overrode one recommendation; present trade-offs with that depth at any checkpoint.

## OUTLINE COMPLETE
