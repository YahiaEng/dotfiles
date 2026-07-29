---
phase: 14-dashboard-drawer
plan: 06
subsystem: ui
tags: [quickshell, qml, procfs, upower, performance-tab, dials, material-design-3, caelestia]

# Dependency graph
requires:
  - phase: 14-03
    provides: "Dashboard.qml pager, per-tab dynamic sizing convention, PerformanceTab.qml/SystemResources.qml/Dial.qml stubs"
  - phase: 14-02
    provides: "Material Symbols Rounded font, motion tokens (Colours/Motion singletons)"
  - phase: 14-05
    provides: "Standing Caelestia-look directive; warm-state/optimistic house patterns"
provides:
  - "SystemResources.qml — shared /proc + /sys + UPower reader (CPU/memory/network/storage/battery), drawerOpen-gated cadenced sampling (~2s core, ~30s storage), primed first sample with short first CPU delta, warm values retained across drawer dismissals"
  - "Dial.qml — reusable QtQuick.Shapes circular dial (accentColor theme-role property, icon, detail line, motion-token arc animation), consumed at full size here and mini size by 14-08"
  - "PerformanceTab.qml — Caelestia-look performance pane: four per-role-colored 224px dials (CPU=primary, Memory=secondary, Storage=tertiary, Battery=error) in a centered 2x2 grid, CPU freq/temp detail line, fixed-width network rate row"
affects: [14-08, 14-09, 15]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Warm-instance-outside-LazyLoader: any backend whose values must survive drawer dismissal is instantiated in shell.qml as a sibling of dashboardLoader and threaded in as a property — third instance of the pattern (MediaBackend, WeatherBackend, now SystemResources)"
    - "FileView procfs reads require blockAllReads:true on this Quickshell build — the documented preload:false + blockLoading:true combination returns stale one-tick-lagged values"
    - "QML innermost-scope-wins hazard: a binding `foo: foo` where the component declares `property var foo` silently self-references — shared instance ids must never collide with property names (id renamed to sharedSystemResources, then superseded by the shell.qml move)"
    - "Delta-based gauges prime on open: first sample fires immediately with a short (~400ms) first delta window, then settles to the normal cadence — first paint lands under a second instead of one full poll interval"

key-files:
  created: []
  modified:
    - quickshell/.config/quickshell/modules/dashboard/SystemResources.qml
    - quickshell/.config/quickshell/modules/dashboard/Dial.qml
    - quickshell/.config/quickshell/modules/dashboard/PerformanceTab.qml
    - quickshell/.config/quickshell/modules/Dashboard.qml
    - quickshell/.config/quickshell/shell.qml

key-decisions:
  - "Render-gate round 1: 176px monochrome 2x2 dials — legibility/shape/battery-placeholder approved; fit rejected (half-empty panel) and Caelestia-style per-ring color + richer detail requested."
  - "Round 2 (b5e7c65): distinct theme roles per ring (CPU=primary, Memory=secondary, Storage=tertiary, Battery=error — the four non-neutral roles), 224px dials, caption icons, CPU '4.1 GHz · 62°C' detail from cpufreq sysfs + k10temp hwmon (fixed-argv bounded discovery, cached forever, silent per-half degradation). Root-caused a width echo: the rate row bound to contentColumn.width inherited whatever width the previous tab left the shared frame at — rebound to dialGrid.width. Human: colors/detail/motion/rate-row approved; layout still crammed left, and first-paint latency rejected ('takes a few seconds for readings, CPU last — clunky')."
  - "Round 3 (c53ba1f): content centered within the 760 drawerMinWidth floor frame; readings warm-started. SystemResources moved OUT of the LazyLoader-destroyed drawer window into shell.qml (deviation — shell.qml was frozen for this plan, but the move follows the identical MediaBackend/WeatherBackend precedent stated in that file; values now survive dismissal while drawerOpen still gates every timer and process, leaving D-36's zero-idle doctrine intact). Human verified live: rings centered, readings fast — APPROVED."
  - "Battery-as-error role confirmed acceptable by the human ('no battery reads as error' — placeholder does not read as alarming)."
  - "Backward-navigation pager width bug (Left arrow from a wider to a narrower tab leaves width stuck) found here, deliberately NOT fixed — Dashboard.qml pager mechanism is 14-03/14-08/14-09 territory; logged in deferred-items.md."

patterns-established:
  - "Warm-instance-outside-LazyLoader is now the standing rule for drawer backends whose state must survive dismissal."
  - "Executor verification restarts of quickshell MUST relaunch detached (`setsid uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh`) — a round-2 executor restarted it as a child of its own shell, quickshell died when the agent exited, and Super+D silently stopped working until the orchestrator relaunched it."

requirements-completed: [DASH-05]

coverage:
  - id: D1
    description: "SystemResources.qml — five metrics (CPU/memory/storage/battery percent-species + network rate species), drawerOpen-gated cadenced sampling, 3-sample CPU smoothing, UPower typed battery, parse-failure quiet degradation, zero-idle when closed"
    requirement: "DASH-05"
    verification:
      - kind: manual_procedural
        ref: "Task 1 acceptance — 15s dismiss-window zero-log proof (sampler stops dead), FileView blockAllReads freshness fix instrumented and verified, battery populated path proven via injected stub at batterySource seam then reverted"
        status: pass
    human_judgment: false
  - id: D2
    description: "Dial.qml + PerformanceTab.qml — reusable theme-role-colored circular dial, centered 2x2 grid + fixed-width rate row filling the tab's declared frame, motion-token arc animation stopping at motion-scale off"
    requirement: "DASH-05"
    verification:
      - kind: manual_procedural
        ref: "Task 3 blocking human render-gate — three rounds, final verdict 2026-07-29: legibility/shape/colors/detail/motion/rate-row explicitly approved across rounds; centered layout and warm-start readings live-verified ('I checked both points and they seem fixed')"
        status: pass
    human_judgment: true
    rationale: "Visual fit, color life, and perceived responsiveness are aesthetic judgments requiring human sign-off per ROADMAP standing constraint — performed across the three render-gate rounds."

# Metrics
duration: multi-session (3 render-gate rounds)
completed: 2026-07-29
status: complete
---

# Phase 14 Plan 06: Performance Tab + SystemResources Summary

**Filled the Performance tab with a Caelestia-look pane — four theme-role-colored 224px dials with CPU freq/temp detail and a fixed-width network rate row over a shared, zero-idle /proc+/sys+UPower reader — closing three render-gate rounds, the last moving SystemResources out of the LazyLoader so warm readings survive dismissal and first paint lands instantly.**

## Performance

- **Duration:** multi-session, three render-gate rounds across one day
- **Started:** 2026-07-29 (commit `7a6577e`)
- **Completed:** 2026-07-29 (commit `c53ba1f`; human live-verification same day)
- **Tasks:** 3 (Task 1 reader, Task 2 dial grid + tab, Task 3 blocking render gate — re-entered twice on feedback)
- **Files modified:** 5 (`SystemResources.qml`, `Dial.qml`, `PerformanceTab.qml`, `Dashboard.qml`, `shell.qml` — the last a recorded deviation)

## Accomplishments

- **SystemResources reader (7a6577e):** CPU/memory/network on ~2s cadence, storage on ~30s, battery via Quickshell's typed UPower service; every timer and subprocess gated on `drawerOpen` (proven: zero log lines across a 15s dismissal window); 3-sample CPU mean smoothing; parse failures degrade to the quiet placeholder, never NaN.
- **Dial + PerformanceTab (8b76878):** one reusable arc component for this tab's four full-size dials and 14-08's minis; battery-absent machine renders the D-41 "No battery" placeholder, populated path proven via a temporary stub then reverted.
- **Caelestia redesign (b5e7c65):** per-ring theme roles recoloring live on theme switch (verified nord ↔ gruvbox with the drawer open), icons, CPU frequency/temperature detail line from sysfs/hwmon with bounded fixed-argv discovery.
- **Round-3 fit + warm start (c53ba1f):** grid centered in the 760-floor frame; SystemResources relocated to shell.qml (MediaBackend/WeatherBackend precedent) so re-summon shows last-known values instantly while a primed short-delta first sample refreshes them under a second.

## Deviations

- **shell.qml modified despite being frozen for this plan** (Rule: user-approved render-gate feedback overrides file ownership): warm values cannot survive inside a LazyLoader-destroyed window; the fix is the file's own documented pattern for the two existing backends. Recorded, not silent.
- **Dashboard.qml 1-line shared-instance fix in Task 2** (innermost-scope-wins self-reference bug), later superseded by the property-threading in round 3.

## Issues Encountered

- **Stale procfs reads:** FileView's documented `preload:false + blockLoading:true` returned one-tick-lagged values on this build; `blockAllReads:true` is the working fix.
- **Executor killed quickshell:** a verification restart as a shell child died with the agent session, silently breaking Super+D for the user; the detached `uwsm app` relaunch is now a standing executor rule (also recorded in STATE.md).
- **Backward-nav pager width bug** (pre-existing, 14-03's mechanism): Left-arrow from a wider to a narrower tab leaves the frame width stuck; deferred to 14-08/14-09 via deferred-items.md.

## Next Phase Readiness

- 14-08's DashboardTab mini-dials consume the same Dial component and the shell-root `systemResources` instance already threaded through Dashboard.qml — no new wiring needed.
- The deferred backward-nav width bug should be resolved by 14-08/14-09 before the phase closes.
