---
phase: 20-indicators-power-menu
plan: 01
subsystem: infra
tags: [swayosd, wleave, wlogout, eww, retirement-check, motion-lint, quickshell-doctor, theme-engine, gate-01, hyprlock, sddm]

# Dependency graph
requires:
  - phase: 18-qml-bar-retirement-machinery
    provides: "GATE-01 Recurrence Protocol (six-step behaviour-baseline discipline), retirement-check script, motion-lint checker-internals discipline"
provides:
  - "20-BEHAVIOUR-BASELINE.md — swayosd's and wleave's live behaviour transcribed off the running implementations, including the six wleave action strings before their source file is deleted"
  - "20-RETIREMENT-BASELINE.md — pre-deletion retirement-check output for all four surfaces (swayosd, wleave, wlogout, eww) plus a per-site disposition table for reference classes CONTEXT.md's canonical_refs did not enumerate"
  - "20-GATE-01-MEASUREMENTS.md — three live operator-verified observations (SDDM greeter, hyprlock, sysfs Caps Lock watch) with their D-20-17/D-20-19/RESEARCH-Open-Question-1 consequences"
  - "COVERAGE.md — reasoned 'No external API integration' declaration for the seal-time api-coverage gate"
affects: [20-05, 20-09, 20-10]

# Actuals (#2632)
actuals:
  tokens: 12229
  tasks: 4
  commits: 3

tech-stack:
  added: []
  patterns:
    - "GATE-01 Recurrence Protocol (six steps, surface-agnostic) reused unchanged from 18-BEHAVIOUR-BASELINE.md for a second phase"
    - "Pre-deletion retirement-check baseline capture, mirrored post-deletion in plans 20-09/20-10 for a before/after zero-hit diff"

key-files:
  created:
    - .planning/phases/20-indicators-power-menu/20-BEHAVIOUR-BASELINE.md
    - .planning/phases/20-indicators-power-menu/20-RETIREMENT-BASELINE.md
    - .planning/phases/20-indicators-power-menu/20-GATE-01-MEASUREMENTS.md
    - .planning/phases/20-indicators-power-menu/COVERAGE.md
  modified: []

key-decisions:
  - "D-20-17 measured: no on-screen indicator at the SDDM greeter (hardware LED lit separately, recorded as a distinct fact) -> RETIRE-04 proceeds, including swayosd-libinput-backend.service, with pre-session reach confirmed dead by measurement rather than assumed dead"
  - "D-20-19 measured: SwayOSD pill did not appear over hyprlock -> QOSD-01 amended to its already-true 'locked=true keys keep working' content (keybinds.lua:297-308), not chased as a render-over-lock-surface requirement; D-20-20 not reopened"
  - "RESEARCH Open Question 1 / Assumption A1 measured: sysfs FileView-class watcher did not fire on either Caps Lock edge -> recorded as a SCOPE CONVERSATION for plan 20-05 Task 2 (polling Timer fallback costs the zero-idle claim for this one indicator); substitution not pre-authorised here"
  - "Resolved sysfs node path for the Observation 3 test run recorded as NOT CAPTURED rather than re-resolved after the fact, per the plan's explicit instruction not to substitute a freshly re-globbed path for what was actually observed"

patterns-established: []

requirements-completed: [RETIRE-04, RETIRE-05, RETIRE-07, QOSD-01, QOSD-02]

coverage:
  - id: D1
    description: "swayosd's and wleave's live behaviour (layer-shell geometry, unit topology, all six wleave action strings/mnemonics) transcribed into 20-BEHAVIOUR-BASELINE.md before either package is deleted"
    requirement: "RETIRE-04"
    verification:
      - kind: other
        ref: "test -f 20-BEHAVIOUR-BASELINE.md && grep -qF wleave action strings + swayosd-libinput-backend.service + autostart.lua:192 + ## Unaccounted Keys / ## Not a Port Specification sections (plan Task 1 <verify> block)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pre-deletion retirement-check consumer sweep captured for all four retirement targets (swayosd, wleave, wlogout, eww) with per-site dispositions for reference classes outside CONTEXT.md's canonical_refs"
    requirement: "RETIRE-05"
    verification:
      - kind: other
        ref: "test -f 20-RETIREMENT-BASELINE.md && grep -qF retirement-check output blocks + panel-swayosd-key-ownership + REPRESENTATIVE_FILES + compliant-hyprctl-binds.txt + compliant-gtk4.css (plan Task 2 <verify> block)"
        status: pass
    human_judgment: false
  - id: D3
    description: "wlogout and eww host-package facts (pacman -Qi) recorded as their own retirement baseline, both confirmed live RETIRE-07 targets"
    requirement: "RETIRE-07"
    verification:
      - kind: other
        ref: "20-RETIREMENT-BASELINE.md § pacman -Qi table + retirement-check wlogout/eww output blocks"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-20-17 (SDDM greeter Caps Lock) and D-20-19 (SwayOSD over hyprlock) live observations taken by the operator on physical hardware and recorded verbatim with their scope consequences"
    requirement: "QOSD-01"
    verification:
      - kind: manual_procedural
        ref: "operator performed both observations at the physical machine; results recorded verbatim in 20-GATE-01-MEASUREMENTS.md § SDDM greeter Caps Lock and § SwayOSD over hyprlock"
        status: pass
    human_judgment: true
    rationale: "Both observations require physical hardware (SDDM greeter pre-session, hyprlock lock surface, a real key press) that no in-session agent can reach; the operator's report is the ground truth this document records, not something an executor can independently re-verify."
  - id: D5
    description: "RESEARCH Open Question 1 / Assumption A1 (sysfs Caps Lock FileView watch mechanism) exercised against a real physical key press and recorded as did-not-fire, with the resulting scope conversation flagged rather than silently resolved"
    requirement: "QOSD-02"
    verification:
      - kind: manual_procedural
        ref: "operator ran a select.poll() watcher against the resolved sysfs node and pressed the physical Caps Lock key twice; result recorded verbatim in 20-GATE-01-MEASUREMENTS.md § sysfs Caps Lock watch"
        status: pass
    human_judgment: true
    rationale: "The watch mechanism can only be proven live against a real physical Caps Lock press on this exact kernel/hardware build; a negative result changes plan 20-05's implementation path and must be judged by the developer, not auto-resolved by an executor."

duration: ~35min (across two sessions; this session ~12min for Tasks 3-4)
completed: 2026-08-15
status: complete
---

# Phase 20 Plan 01: GATE-01 Baseline, Consumer Sweep & Live Measurements Summary

**Captured swayosd's/wleave's live behaviour and a four-surface pre-deletion consumer sweep, then closed all three GATE-01 open questions (D-20-17, D-20-19, sysfs watch viability) from operator-verified physical-hardware observations rather than in-session inference.**

## Performance

- **Duration:** ~35 min total (Tasks 1-2 in a prior session, Tasks 3-4 in this continuation session ~12 min)
- **Started:** 2026-08-15 (prior session)
- **Completed:** 2026-08-15T19:XX:XXZ
- **Tasks:** 4
- **Files modified:** 4 (all new)

## Accomplishments
- Transcribed swayosd's and wleave's live behaviour — layer-shell geometry, two-unit topology (`swayosd-libinput-backend.service` vs. per-session `swayosd-server`), all six `swayosd-client` keybinds, and all six wleave `layout.json` action strings — into `20-BEHAVIOUR-BASELINE.md`, with a mechanically-verified empty "Unaccounted Keys" set and an explicit "Not a Port Specification" guardrail against reproducing the retiring hue-capsule/flat-pill aesthetics.
- Captured a raw pre-deletion `retirement-check` run for all four retirement targets (swayosd, wleave, wlogout, eww) and a disposition table for reference-site classes CONTEXT.md's own `canonical_refs` list did not enumerate — most notably the `quickshell-doctor` checker-internals class (`panel-swayosd-key-ownership`), `motion-lint`'s exemption/carve-out entries, and the `tests/quickshell-fixtures`/`tests/motion-fixtures` fixture trees — each with a `delete`/`edit`/`re-instrument`/`report-only` disposition plans 20-09/20-10 execute from.
- Resolved all three GATE-01 open questions from operator-reported physical-hardware observations: D-20-17 (SDDM greeter) measured NO indicator, clearing RETIRE-04 including the libinput backend; D-20-19 (hyprlock) measured NO pill, amending QOSD-01 to its already-satisfied locked-key clause; the sysfs Caps Lock `FileView`-class watch measured did-not-fire on either edge, flagged as a scope conversation for plan 20-05 rather than silently resolved.
- Wrote `COVERAGE.md`'s reasoned "No external API integration" declaration so the seal-time `api-coverage.verify-pre` gate passes without a fabricated capability matrix.

## Task Commits

Each task was committed atomically:

1. **Task 1: Enumerate swayosd's and wleave's live behaviour into 20-BEHAVIOUR-BASELINE.md** - `bb09c16` (docs)
2. **Task 2: Capture the pre-deletion consumer sweep for all four retirement targets** - `02fc058` (docs)
3. **Task 3: Take the three live observations no in-session agent can reach** - no separate commit (produces no artifact of its own; the operator's three physical-hardware observations were reported back and recorded directly by Task 4, per the plan's own instruction that Task 3's results are "recorded by Task 4")
4. **Task 4: Record the three measurements and their consequences; write COVERAGE.md** - `1e1d1fe` (docs)

**Plan metadata:** (this commit, following SUMMARY.md)

_Note: This plan carried no TDD tasks — all four are `type="auto"` prose/read-and-record work._

## Files Created/Modified
- `.planning/phases/20-indicators-power-menu/20-BEHAVIOUR-BASELINE.md` - swayosd/wleave live behaviour transcription, GATE-02's judging document
- `.planning/phases/20-indicators-power-menu/20-RETIREMENT-BASELINE.md` - pre-deletion retirement-check baseline + reference-site disposition table for all four surfaces
- `.planning/phases/20-indicators-power-menu/20-GATE-01-MEASUREMENTS.md` - the three GATE-01 live observations and their decision consequences
- `.planning/phases/20-indicators-power-menu/COVERAGE.md` - API-coverage seal-gate declaration

## Decisions Made
- **D-20-17 resolved (RETIRE-04 proceeds):** SDDM greeter showed no on-screen indicator on Caps Lock press; the keyboard's own hardware LED lighting was recorded as a separate, non-software fact per the plan's explicit instruction not to conflate the two. `swayosd-libinput-backend.service` is confirmed in scope for deletion in plan 20-09 with no scope escalation.
- **D-20-19 resolved (QOSD-01 amended):** SwayOSD's pill did not appear over hyprlock. Per D-20-19's negative branch, QOSD-01's real content — "the keys keep working while locked" — is already satisfied via the six `locked = true` binds at `keybinds.lua:297-308`; no lock-surface render work is needed. D-20-20 (readout inside hyprlock's own config, already rejected) was not reopened.
- **RESEARCH Open Question 1 resolved (scope conversation flagged, not resolved):** the sysfs `FileView{watchChanges:true}`-class watch did not fire on either Caps Lock transition in a real physical-key-press test. This is recorded as a measured negative, not silently substituted — plan 20-05 Task 2's implementation path (event-driven vs. polling `Timer` fallback, and its zero-idle-claim cost) is left as a decision for the developer with this evidence in hand.
- **Resolved sysfs node path recorded as NOT CAPTURED:** the operator did not report back which `/sys/class/leds/*::capslock/brightness` node the watcher was actually pointed at. Per the plan's explicit prohibition on inferring/reconstructing an untaken observation, this was recorded as NOT CAPTURED rather than re-resolved now and presented as evidence of what was watched — a re-resolved path would not be trustworthy given D-20-14's already-confirmed per-boot node-index instability (`input5` on 2026-08-14, `input33` on 2026-08-15).

## Deviations from Plan

None - plan executed exactly as written. Task 3 produced no separate commit because it has no file output of its own (`<files>none — live observation only`); its three observations were captured directly into Task 4's `20-GATE-01-MEASUREMENTS.md` commit, matching the plan's own framing that Task 4 "records the three measurements."

## Issues Encountered

The initial execution session halted at the Task 3 `human-check` checkpoint because the three observations (SDDM greeter, hyprlock, physical Caps Lock press) require physical hardware access no in-session agent has. A continuation session resumed after the operator performed all three observations at the machine and reported the results (`1: no`, `2: no`, `3: no`, plus the hardware-LED clarification and the NOT-CAPTURED node-path clarification) — resolved by direct operator report, not by any further automation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `20-BEHAVIOUR-BASELINE.md` is ready for plan 20-06's wleave-to-QML migration (the six action strings are the sole surviving source once wleave's `layout.json` is deleted) and for GATE-02's later side-by-side judgment.
- `20-RETIREMENT-BASELINE.md`'s disposition table is ready for plans 20-09 (swayosd/wlogout) and 20-10 (wleave/eww) to execute from directly — every listed reference site carries a non-empty disposition.
- `20-GATE-01-MEASUREMENTS.md` closes all three of this phase's opening measurement gates: plan 20-09 reads the `RETIRE-04 proceeds` verdict directly; plan 20-05 Task 2 reads the `did-not-fire` verdict as a scope conversation to resolve before implementing QOSD-02's mechanism, not a green light to proceed unmodified.
- No blockers. The one open item carried forward is genuinely open by design: plan 20-05 Task 2 must have a developer conversation about the sysfs watch's polling-fallback cost before implementing QOSD-02, per this plan's own instruction not to pre-authorise that substitution.

---
*Phase: 20-indicators-power-menu*
*Completed: 2026-08-15*

## Self-Check: PASSED

All 4 artifact files (`20-BEHAVIOUR-BASELINE.md`, `20-RETIREMENT-BASELINE.md`, `20-GATE-01-MEASUREMENTS.md`, `COVERAGE.md`) and this `20-01-SUMMARY.md` confirmed present on disk. All 3 task commit hashes (`bb09c16`, `02fc058`, `1e1d1fe`) confirmed present in `git log --oneline --all`.
