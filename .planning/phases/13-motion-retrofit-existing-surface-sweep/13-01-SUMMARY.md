---
phase: 13-motion-retrofit-existing-surface-sweep
plan: 01
subsystem: theming
tags: [hyprland, motion, md3, matugen, theme-engine, motion.json, motion-switch]

# Dependency graph
requires:
  - phase: 12-unified-design-token-pipeline
    provides: "motion.json base MD3 easings, lib/motion.sh's three-target renderer, motion-lint, the Probe.qml token inspector"
provides:
  - "Full MD3 easing scale in motion.json (six new single-bezier easings) plus D-11's marked non-MD3 x-* extension"
  - "D-21 A/B curve-set axis (curve_sets.md3 / curve_sets.legacy) with motion-switch.sh --curves"
  - "Fully tokenized hypr/config/animations.conf — zero hand-authored beziers, zero raw durations, layersIn/layersOut split"
  - "D-06 boundary correction: layer-surface entrance is compositor-owned (proven); exit is client-owned on every tested surface (proven)"
  - "D-19 soak clock started at 2026-07-27T03:40:53Z"
affects: [13-02, 13-03, 13-04, 13-05, 13-06, 13-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "8x lively-multiplier scratch instrument for render-gate perceptual checks (see Render-Gate Method Lesson below) — reusable by 13-02 and 13-05"
    - "Animation-disabled control (hyprctl keyword animation \"<slot>,0,1,default\") to distinguish compositor-owned motion from client-owned motion before trusting a visual gate"

key-files:
  created: []
  modified:
    - theme-engine/.config/theme-engine/motion.json
    - theme-engine/.config/theme-engine/lib/motion.sh
    - hypr/.config/hypr/scripts/motion-switch.sh
    - hypr/.config/hypr/scripts/motion-lint
    - hypr/.config/hypr/config/animations.conf
    - hypr/.config/hypr/config/windowrules.conf

key-decisions:
  - "Task 1: proceed-md3-pure — MD3 default vocabulary confirmed at the one-way-door gate; x-* character curves retained only as the A/B legacy set and D-22 retune landing spot"
  - "Task 2 (D-13): Hyprland's animation speed unit is deciseconds — speed 500 timed at ~50s wall-clock; divisor 100 confirmed before any duration conversion was written"
  - "D-06 revised: entrance is compositor-owned (Check 2 proof), exit is client-owned on every layer-shell surface tested (walker, swaync, wleave) — see D-06 Boundary Correction section"
  - "D-17 render gate APPROVED — checks 1,2,4,5 passed by direct visual judgment (2 and 4 judged under the 8x lively instrument); check 3 closed by mechanical proof plus documented instrument-absence, explicitly accepted as weaker-than-normal evidence for a stated reason"

patterns-established:
  - "Render-gate perceptual checks that fail under normal-speed cross-surface memory comparison should be re-staged at an exaggerated motion-scale (lively multiplier raised as a scratch, uncommitted motion.json edit) applied through the real motion-switch.sh pipeline, with the exaggeration verified to reach both Hyprland's hyprctl animations -j readback and the QML-consumed ~/.local/state/theme/motion.json identically before trusting the human's answer"
  - "Before trusting a compositor-side gate on a client surface, disable the animation slot entirely (hyprctl keyword animation \"<slot>,0,1,default\", runtime-only) and confirm the observed duration actually changes — if it doesn't, the surface is client-owned and the gate needs a different instrument"

requirements-completed: [MOTION-01]

coverage:
  - id: D1
    description: "Every animation = line in hypr/config/animations.conf resolves speed and curve from motion.json-sourced $motion_speed_*/$motion_curve_* variables; zero hand-authored beziers remain"
    requirement: "MOTION-01"
    verification:
      - kind: other
        ref: "Hyprland --verify-config (clean); hyprctl animations -j readback (15 slots, layersIn/layersOut hold distinct speeds); motion-lint (exit 0, animations.conf unexempted); theme-doctor/theme-parity"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-17 render gate: Hyprland-rendered motion tokens visually match the QML inspector's replay rows, and the md3/legacy A/B toggle is a perceptible instrument"
    requirement: "MOTION-03"
    verification: []
    human_judgment: true
    rationale: "Fidelity-to-QML-replay and curve-character distinguishability are perceptual judgments only the operator can make; approved 2026-07-27 (checks 1/2/4/5 direct visual pass, check 3 closed on revised mechanical evidence — see D-06 Boundary Correction)."

duration: multi-session (continuation agent; transcript of the original session was lost, state reconstructed and verified against live system before resuming)
completed: 2026-07-27
status: complete
---

# Phase 13 Plan 01: Hyprland Motion Retrofit + A/B Curve-Set Toggle Summary

**Every Hyprland window/workspace/layer/fade animation now resolves its duration and curve from `motion.json` through emitted `$motion_speed_*`/`$motion_curve_*` variables — zero hand-authored beziers, zero raw durations remain in `animations.conf` — and the D-19 soak clock has started.**

## Performance

- **Duration:** multi-session (continuation agent — see note below)
- **Started:** unknown (original session transcript lost; Tasks 3-4 were already committed when this continuation began)
- **Completed:** 2026-07-27T03:41:04Z
- **Tasks:** 5/5 complete
- **Files modified:** 6 (`motion.json`, `lib/motion.sh`, `motion-switch.sh`, `motion-lint`, `animations.conf`, `windowrules.conf`)

**Continuation note:** This plan was originally executed across two agent sessions. The first session's transcript was lost after Tasks 1-4 completed and committed; a fresh continuation agent reconstructed and independently re-verified all prior state (commit hashes, live compositor config, motion.json contents) against the live system before resuming, per the orchestrator's reconstructed handoff. All claims below for Tasks 1-4 were re-verified live by the continuation agent, not merely assumed from the handoff.

## Accomplishments

- `motion.json` grown to the full MD3 easing scale (6 new single-bezier easings, primary-sourced), D-11's marked `x-*` non-MD3 extension (5 character curves, single-sourced for the A/B `legacy` set), 2 new semantic pairs, a new `indicators` category, and the `curve_sets` A/B axis (`md3`/`legacy`)
- `lib/motion.sh` emits three new families of Hyprland variables (`$motion_speed_<token>`, `$motion_speed_indicator_<name>`, `$motion_curve_<slot>`) and a closed-set `motion-curves` reader
- `motion-switch.sh --curves md3|legacy` flips the six feel-changing slots through exactly one `theme-apply` re-render (D-36's one-entrypoint contract intact)
- `hypr/config/animations.conf` fully retrofitted: all 12 hand-authored curve declarations deleted, all 15 `animation =` lines (including the new `layersIn`/`layersOut` split) resolve from emitted tokens, `motion-lint` verifies the file with zero exemption
- Two dead `wofi` layerrules deleted from `windowrules.conf`; the wleave namespace-scoped precedent left untouched
- D-17 render gate approved: Hyprland's rendered motion matches the QML token inspector's replay rows on every checkable surface; the `md3`/`legacy` A/B toggle proven a real, perceptible instrument
- **D-06 boundary correction** discovered and recorded (see below): layer-surface exits are client-owned repo-wide, not compositor-owned as originally assumed
- D-19 soak clock started: **2026-07-27T03:40:53Z**, running at curve-set `md3` / motion-scale `normal`, with the A/B toggle available for ongoing comparison

## Task Commits

1. **Task 1: One-way door — MD3 purity** — decision only, no commit (operator selected `proceed-md3-pure`)
2. **Task 2: D-13 speed-unit checkpoint** — observation only, no commit (recorded in Task 3's commit message context; deciseconds/divisor 100 confirmed)
3. **Task 3: Grow token source + A/B curve-set axis** — `b48f7b9` (feat)
4. **Task 4: Tracer — retrofit animations.conf** — `35bba51` (feat)
5. **Task 5: D-17 render gate** — no code artifact (checkpoint-only task); gate outcome recorded in this SUMMARY and in STATE.md's decision log

**Plan metadata:** committed alongside this SUMMARY (see final commit hash in orchestrator output)

## Files Created/Modified

- `theme-engine/.config/theme-engine/motion.json` — full MD3 easing scale, `x-*` extension, `indicators`, `curve_sets`
- `theme-engine/.config/theme-engine/lib/motion.sh` — Hyprland speed/curve variable emitters, `theme_engine_read_motion_curves`
- `hypr/.config/hypr/scripts/motion-switch.sh` — `--curves md3|legacy` flag
- `hypr/.config/hypr/scripts/motion-lint` — learned `$motion_*` reference resolution, `animations.conf` removed from `EXEMPTIONS`
- `hypr/.config/hypr/config/animations.conf` — fully tokenized, `layersIn`/`layersOut` split added
- `hypr/.config/hypr/config/windowrules.conf` — two dead `wofi` layerrules removed

## Decisions Made

- **Task 1 (D-09/D-12 one-way door):** `proceed-md3-pure` — the five hand-authored character curves (`wind`, `winIn`, `winOut`, `smoothIn`, `smoothOut`) leave the default vocabulary permanently; they survive only as D-11's marked `x-*` extension (the A/B `legacy` set and the sole sanctioned D-22 retune landing spot).
- **Task 2 (D-13):** Hyprland's animation `speed` unit is **deciseconds** (1 unit = 100ms). Confirmed by setting `layers` to speed 500 and timing the observed entrance at ~50 seconds wall-clock with a stopwatch — ruling out centiseconds (~5s) and raw milliseconds (~0.5s). Task 4's speed values are computed with divisor 100.
- **Task 5 (D-17):** Render gate **APPROVED**. Checks 1, 2, 4 and 5 passed by direct visual judgment (2 and 4 were re-judged under the 8x `lively`-multiplier instrument, see Render-Gate Method Lesson). Check 3 closed on **revised evidence** rather than its originally-specified method — see D-06 Boundary Correction below for the full finding and why it was accepted.

## D-06 Boundary Correction

D-06 originally claimed: *"walker, SwayOSD and the AGS media card need no client-side motion; their motion is compositor-owned via `animation = layers`."* This plan's Check 3 investigation **splits that claim**:

- **Entrance is compositor-owned — proven, unchanged.** Check 2 confirmed walker's entrance visually matches the QML inspector's `emphasized-in` replay row, and the `hyprctl animations -j` readback shows `layersIn` holding its own speed/curve distinct from the parent `layers` slot.
- **Exit is client-owned on every surface tested — new finding, this plan.** Using the animation-disabled control (`hyprctl keyword animation "layersOut,0,1,default"`, runtime-only) against three layer-shell surfaces, disabling `layersOut` entirely produced **no measurable change** in dismissal duration on any of them:

  | Surface | Method | Production `layersOut` (150ms) close | `layersOut` disabled | Verdict |
  |---|---|---|---|---|
  | walker | burst screenshots + pixel-diff vs. static background (prior session) | ~680-990ms across multiple configured speeds | ~700-840ms | client-owned |
  | swaync control-center | `swaync-client --open-panel`/`--close-panel`, isolated on empty workspace, top-right region cropped, burst + AE pixel-diff | ~780-830ms | ~800-830ms | client-owned |
  | wleave | `wleave.sh` + native Escape dismissal, button-row region cropped, burst + AE pixel-diff | ~780-830ms | ~850-880ms | client-owned |

  Each surface's own configuration/CSS corroborates the finding directly:
  - **swaync**: `config.json` carries an explicit `"transition-time": 130` — swaync owns its own reveal/hide timing independently of the compositor.
  - **wleave**: `style.css`'s exit rule uses `transition-property: opacity, transform; transition-duration: var(--motion-duration-emphasized-out), var(--motion-duration-emphasized-out); transition-timing-function: var(--motion-easing-emphasized-accelerate), var(--motion-easing-emphasized-accelerate);` — its own GTK4 CSS transition, driven by the **same-named tokens** `layersOut` also consumes, but through a client-CSS path rather than the compositor's animation tree. This is evidence the token pipeline *is* reaching and correctly driving that exit — just not through Hyprland.
  - **walker**: internal teardown (walker/elephant split or GTK4 transition) with no corresponding config knob found; treated as client-owned by elimination (the animation-disabled control showed the same ~700-900ms regardless of Hyprland's configured `layersOut`).

  **Likely mechanism:** each client plays its own fade/scale transition before actually requesting surface unmap, so by the time Hyprland's `popin`-shrink animation would run on the outgoing surface, the content is already visually gone — the compositor's contribution is masked, not absent.

**Why Check 3 was closed on this evidence instead of its original method.** Check 3 as written asks to verify the 300ms:150ms (`layersIn`:`layersOut`) ratio by watching a layer surface's dismissal. That method requires a surface whose visible close is compositor-driven; **no such surface exists in this repository as currently built** — all three tested surfaces are client-owned on exit. This is **weaker evidence than D-17 normally requires** (a direct visual match against the QML replay row), and is recorded as such rather than papered over. It was accepted anyway because the investigation didn't fail to prove `layersOut` — it proved something more consequential: **layer-surface exits are client-owned repo-wide**, a real architectural fact future phases need, not an unresolved gap in this one. `layersOut`'s Hyprland-side correctness itself remains mechanically proven: `hyprctl animations -j` shows it holding 150ms / `motion-emphasized-accelerate`, distinct from `layersIn`'s 300ms / `motion-emphasized-decelerate` (Task 3/4's acceptance criteria, unaffected by this finding).

**Follow-up scoped outside this plan.** The walker/swaync/wleave client-side exit-teardown timing (and any future desire to shorten/tune it) is client-toolkit work, not a Hyprland config concern, and is explicitly **not** taken up here. Phase 14 already owns walker's in-surface motion vocabulary per D-06's original deferral — that is the natural home for revisiting these three surfaces' exit timing, should it ever become a design priority.

## Render-Gate Method Lesson (for 13-02 and 13-05 to reuse directly)

Checks 2 and 4 were first asked as **cross-surface memory comparisons** — replay the token in the QML inspector, then trigger the real surface seconds later and ask "did it match?" The operator answered "not sure" to both, twice. Human perceptual memory for a ~150-300ms animation does not survive even a few seconds' gap reliably.

**The fix:** temporarily raise the `lively` motion-scale preset's multiplier in `motion.json` from its normal `1.25` to **`8`**, as a scratch (uncommitted) edit, and apply it through the real `motion-switch.sh lively` pipeline — never a manual state-file edit. This slows every motion token by 8x, turning a 300ms decision into a human-paced 2400ms one, while preserving the exact same relative shapes and the exact same curve identities under test.

**Before trusting the exaggerated instrument, verify it reaches every consumer identically** — this plan verified both:
- `hyprctl animations -j`: `windowsIn` speed 24.00 (2400ms), `windowsOut` speed 12.00 (1200ms), `windowsMove` speed 16.00 (1600ms)
- `~/.local/state/theme/motion.json` (the QML-consumed file): `emphasized-in` 2400ms, `emphasized-out` 1200ms, `standard` 1600ms

Both checks then passed cleanly at 8x. Check 5's `md3` vs `legacy` curve-character comparison was staged and judged the same way: `legacy` read as "clearly overshoot, springy, visibly settling back"; `md3` (this session, same 8x instrument, curve-set switched to `md3`) read as "clearly different" — confirming the toggle is a real, perceptible instrument rather than a placebo, which is exactly what the D-19 soak verdict needs to lean on.

**13-02 and 13-05 each have their own D-17 render gate on their own surfaces (waybar/swaync stylesheets).** If either hits the same "not sure" cross-surface-memory failure, reuse this exact instrument: scratch-edit `lively`'s multiplier to 8x, apply via the real preset pipeline (never hand-edit state files), verify the exaggeration reaches every consumer of that surface's motion (the compiled CSS and whatever inspector/replay tool is available) before trusting the human's answer, then revert the scratch edit afterward.

## Deviations from Plan

### Auto-fixed Issues

None — no Rule 1-3 auto-fixes were required in this session. All work was investigation (Check 3), staging (Check 5), and closeout.

### Recorded Finding (not a Rule 1-3 fix, not scope creep)

**1. [Finding] D-06's exit-ownership claim was incomplete — corrected, not fixed**
- **Found during:** Task 5, Check 3
- **Issue:** D-06 (Phase 13 context) claimed walker/SwayOSD/AGS media card motion is entirely compositor-owned. Investigation (this plan and the prior session's walker probe) proved the *exit* half of that claim false for every layer-shell surface actually tested.
- **Resolution:** Documented as the D-06 Boundary Correction above; no code change required (the Hyprland-side tokens are already mechanically correct — Task 3/4's readback proves it). Filed as context for Phase 14, which owns any future client-side motion work on these surfaces.
- **Files modified:** none (documentation-only correction, recorded in this SUMMARY and STATE.md)
- **Verification:** Animation-disabled control on all three surfaces (walker, swaync, wleave), each showing no measurable duration change
- **Committed in:** this SUMMARY's commit (no separate code commit — no files changed)

---

**Total deviations:** 0 auto-fixed; 1 recorded finding (context correction, no code impact)
**Impact on plan:** None on scope or schedule. The finding strengthens rather than weakens the plan's evidence base — it explains *why* Check 3's original method couldn't succeed on any surface, rather than leaving that as an unexplained gap.

## Issues Encountered

- **Continuation from lost transcript:** the original executing session's transcript was lost after Tasks 1-4 completed. The orchestrator reconstructed the full state (commit hashes, decisions, live compositor readback, D-17 gate progress) and handed it to this continuation agent, which independently re-verified every claim against the live system (git log, `hyprctl animations -j`, `motion.json` contents, `motion-curves` state file) before proceeding. No discrepancies found between the reconstructed handoff and live-verified state.
- **Contaminated capture, discarded (Check 3 investigation):** during the swaync control-center burst-capture test, the empty-workspace static-background isolation broke mid-run — active workspace reverted to one showing a paused YouTube video — contaminating that capture. Discarded per the discard-contaminated-captures-rather-than-analyze-them discipline; the test was re-run with workspace isolation re-verified before and after, producing the clean result reported above.
- **No `bc` binary available** for burst-capture timing math; substituted Python 3 (`time.monotonic()`) for the elapsed-time calculations in the scratch measurement scripts (scratchpad-only, not part of the repo).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 13-02, 13-03 and 13-04 can proceed immediately on files this plan does not touch (waybar/swaync sass conversion, MAINT items).
- The D-19 soak clock is running (started 2026-07-27T03:40:53Z) at curve-set `md3` / motion-scale `normal`; the A/B toggle (`motion-switch.sh --curves md3|legacy`) remains available for ongoing comparison throughout the soak window.
- **MOTION-01** is satisfied for the Hyprland surface and marked complete in REQUIREMENTS.md.
- **MOTION-03** ("every retrofitted surface passes a blocking render gate before its plan closes") is a multi-plan requirement — this plan satisfies its first instance (Hyprland). It is intentionally **left open** in REQUIREMENTS.md until the waybar/swaync plans (13-03/13-04) each pass their own gate; marking it complete now would misrepresent the two surfaces not yet retrofitted.
- 13-02/13-05's own render gates should reuse the 8x `lively`-multiplier instrument documented above if they hit the same cross-surface-memory "not sure" failure mode.

---
*Phase: 13-motion-retrofit-existing-surface-sweep*
*Completed: 2026-07-27*

## Self-Check: PASSED

- FOUND: `.planning/phases/13-motion-retrofit-existing-surface-sweep/13-01-SUMMARY.md`
- FOUND: commit `b48f7b9` (Task 3)
- FOUND: commit `35bba51` (Task 4)
- FOUND: `theme-engine/.config/theme-engine/motion.json`
- FOUND: `hypr/.config/hypr/config/animations.conf`
- FOUND: `hypr/.config/hypr/scripts/motion-lint`
