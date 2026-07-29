---
phase: 14-dashboard-drawer
plan: 07
subsystem: ui
tags: [quickshell, qml, open-meteo, weather-tab, material-design-3, degradation, fault-injection]

# Dependency graph
requires:
  - phase: 14-03
    provides: "Dashboard.qml pager, per-tab dynamic sizing convention, WeatherTab.qml/WeatherBackend.qml stubs"
  - phase: 14-02
    provides: "Weather location/units state axis (D-30/D-31), Material Symbols Rounded font, motion tokens (Colours/Motion singletons)"
provides:
  - "WeatherBackend.qml — the single Open-Meteo call site (D-29 one-file fence): one request feeds all three rendered bands; ~15-min TTL (cacheTtlMs); fetch-on-summon only when stale; refresh + clock timers exist only while drawerOpen (D-32/D-36 zero-idle); requestInFlight guard + no-retry-inside-TTL (T-14-25 rate-limit brakes); last good payload persisted via atomicWrites FileView and revalidated against location AND unit system (mismatch = absent, not stale); coordsValid type/finiteness/range gate before any URL exists; WMO code → Material Symbols map with day/night variants, every ligature name verified against the installed MaterialSymbolsRounded font; unrecognised unit strings degrade to metric"
  - "WeatherTab.qml — D-37 Material stack: current-conditions hero (56px symbol, temp, feels-like, humidity/wind, sunrise/sunset), fixed non-scrollable 8-column hour strip starting from the current hour, date-keyed 5-day row that drops elapsed days; single never-cached/invalid-coords/null-backend placeholder (D-41) instead of per-band emptiness; two-tone staleness badge — absent below staleBadgeMs (1h), calm onSurfaceVariant between thresholds, Colours.tertiary at/past staleWarnMs (6h), byte-identical copy in both tones (D-33)"
affects: [14-08, 14-09, 15]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cache revalidation keys on fetch context, not just age: a payload fetched for a different location or unit system is treated as absent rather than stale — prevents rendering plausible-but-wrong data after a settings change"
    - "Degraded surface = daily surface plus one label, never a different screen: the stale path renders exactly like fresh plus one quiet badge (D-33)"
    - "Warm-instance-outside-LazyLoader (established 14-05/14-06) carried: WeatherBackend lives at shell root, drawerOpen gates every timer and request"

key-files:
  created: []
  modified:
    - quickshell/.config/quickshell/modules/dashboard/WeatherBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/WeatherTab.qml

key-decisions:
  - "TTL 15 min / badge threshold 1 h / warning threshold 6 h declared as named constants (cacheTtlMs, staleBadgeMs, staleWarnMs) — D-33/D-32 starting points, retunable as a one-number edit judged at a render gate, not measured optima"
  - "Warning tone reuses Colours.tertiary per 14-UI-SPEC.md recommendation — no new warning role added to the Phase 12 palette pipeline"
  - "Unrecognised unit strings degrade to metric rather than erroring — the imperial branch is the explicit case, metric the fallback"

patterns-established:
  - "One-file API fence: every request to an external service originates in exactly one QML file; consumers see properties, never URLs"

requirements-completed: [DASH-06]

coverage:
  - id: D1
    description: "WeatherBackend — one-request data path, TTL/summon-gated fetch, disk persistence, WMO symbol map, unit-aware formatting, request-amplification brakes"
    requirement: "DASH-06"
    verification:
      - kind: code_inspection
        ref: "Orchestrator close-out inspection 2026-07-30: cacheTtlMs/staleBadgeMs/staleWarnMs constants, requestInFlight guard, drawerOpen-bound timers (running: root.drawerOpen), atomicWrites cache FileView with location+units revalidation, coordsValid gate, symbolForWeatherCode map with font-verified ligatures — all present at the committed SHAs"
        status: pass
    human_judgment: false
  - id: D2
    description: "WeatherTab — hero + fixed 8-hour strip + 5-day row, single placeholder, two-tone stale badge, degraded surface identical to fresh plus one label"
    requirement: "DASH-06"
    verification:
      - kind: human_visual
        ref: "Operator confirmed the rendered Weather tab complete in the live drawer (2026-07-30) — accepted as the Task 3 render-gate answer"
        status: pass
    human_judgment: true
---

# 14-07 Summary — Weather backend + Weather tab

## What was built

The two weather stubs from 14-03 are now the drawer's real fourth tab. `WeatherBackend.qml`
(648 lines, commit `a683620`) is the single place any Open-Meteo request may originate:
one URL built from the 14-02 state axis (coordinates + three unit parameters), one request
feeding the hero, hour strip and day row; a 15-minute TTL with fetch-on-summon only when
stale; refresh and clock timers that exist only while the drawer is open; the last good
response persisted to disk with atomic writes and revalidated against both location and
unit system on reload; and a WMO weather-code vocabulary mapped once to Material Symbols
ligature names verified against the installed font. `WeatherTab.qml` (commit `368214b`)
renders D-37's full Material stack — current hero, fixed non-scrollable eight-column hour
strip starting from the current hour, date-keyed five-day row — and D-33's degradation
story: stale renders exactly like fresh plus one quiet badge that shifts to
`Colours.tertiary` past six hours with byte-identical copy.

## Execution note (orchestrator close-out)

Tasks 1 and 2 were implemented and committed by a concurrent operator session
(2026-07-30 00:31, commits `a683620`, `368214b`); that session ended without writing this
SUMMARY, so the orchestrator closed the plan out afterward. The plan's scripted
fault-injection recordings (request counts across summon cycles, two-hour/seven-hour
backdate observations, hyprctl frame-height readings) were not captured from the executing
session and are therefore NOT on record here. Closure evidence is: (1) line-level code
inspection confirming every must-have mechanism exists at the committed SHAs, and (2) the
operator's visual confirmation of the rendered tab in the live drawer, accepted as the
blocking Task 3 render-gate answer. If DASH-06's degradation path ever needs re-proving,
the backdate procedure remains verbatim in 14-07-PLAN.md Task 1 step and Task 3 gate.

## Deviations

- No code deviations recorded. The scope matches the plan exactly: two files touched,
  no other file modified.
- Process deviation: fault-injection evidence unrecorded (see execution note above).
