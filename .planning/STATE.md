---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 2
current_phase_name: Static ↔ Dynamic Parity & Switch Reliability
status: executing
stopped_at: Phase 2 context gathered
last_updated: "2026-07-07T21:59:34.494Z"
last_activity: 2026-07-07
last_activity_desc: Phase 01 complete, transitioned to Phase 2
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
  percent: 33
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-07)

**Core value:** One theme switch — static or dynamic — instantly and consistently re-themes the entire desktop, and the whole setup reproduces from scratch with one script.
**Current focus:** Phase 01 — root-cause-fix-consolidated-theme-engine

## Current Position

Phase: 2 — Static ↔ Dynamic Parity & Switch Reliability
Plan: Not started
Status: Ready to execute
Last activity: 2026-07-07 — Phase 01 complete, transitioned to Phase 2

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 3
- Average duration: - min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3 | - | - |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
| Phase 01 P01 | 25min | 2 tasks | 2 files |
| Phase 01 P02 | 40min | 3 tasks | 27 files |
| Phase 01 P03 | multi-session | 3 tasks | 9 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Roadmap: Fix theming pipeline root-cause-first before any v2 expansion — every v2 surface reads from the pipeline this milestone repairs.
- Roadmap: Full-repo bug audit (SCAN-01) placed in Phase 1 as foundational discovery to break the patch-without-diagnosing loop (8+ prior failed fix commits).
- [Phase 01]: elephant-runner/websearch/files added to install.sh AUR array — all three verified via paru -Si (RESEARCH A2 confirmed)
- [Phase 01]: elephant-providerlist silent install failure and menus-provider-inactive anomaly deferred to Phase 3 INST-01 verification loop
- [Phase 01]: 01-02: matugen 4.1.0 never populates colors.image in EITHER json or image render mode (correction to 01-RESEARCH.md) - hardcoded a blank $image in the hyprland template since hyprlock theming is out of scope this milestone
- [Phase 01]: 01-02: walker-restart.sh/walker-theme-gen.sh/gtk-reload.sh/vscodium-theme.sh left on disk unreferenced - Plan 01-03 explicitly owns their retirement
- [Phase 01]: 01-03: set -e + (( counter++ )) at counter=0 silently aborts theme-apply mid-reload before the walker relaunch line — rewritten to counter=$((counter+1)) everywhere in reload.sh/gtk.sh
- [Phase 01]: 01-03: walker-style.css selectors (#box/#search/row) matched no real widget in walker 2.16.2's class-based UI — rewritten against the actual widget tree
- [Phase 01]: 01-03: Thunar deferred-restart notify-and-skip branch never re-fired — replaced with a deduped bounded-poll watcher that restarts once the last window closes
- [Phase 01]: 01-03: RESEARCH Open Question 2 answered — GTK3 windows do not re-color live, D-15's stale-until-closed caveat stands unmodified
- [Phase 01]: 01-03: theme-doctor's one remaining gap (elephant listproviders missing files/menus/providerlist/runner/websearch) is accepted and deferred to Phase 3 INST-01 per user sign-off

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

None yet.

### Blockers/Concerns

[Issues that affect future work]

- Source discrepancy: REQUIREMENTS.md coverage note and the roadmapper brief state "18 total" v1 requirements, but there are actually 19 requirement IDs. Roadmap maps all 19; coverage note corrected to 19 in REQUIREMENTS.md traceability.
- Research flags (verify empirically during Phase 1 planning): does Walker `hotreload_theme=true` remove the restart need? does GTK3 gtk.css file-monitoring make the Thunar restart optional? does `dbus-update-activation-environment` truly eliminate relogin?

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Milestone 2 | OSD, Walker menus, media widget, polish, more themes | Deferred to v2 | 2026-07-07 |

## Session Continuity

Last session: 2026-07-07T21:23:03.405Z
Stopped at: Phase 2 context gathered
Resume file: .planning/phases/02-static-dynamic-parity-switch-reliability/02-CONTEXT.md
