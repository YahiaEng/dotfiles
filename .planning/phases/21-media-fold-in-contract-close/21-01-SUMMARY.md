---
phase: 21-media-fold-in-contract-close
plan: 01
subsystem: ui
tags: [quickshell, qml, cava, audio-visualiser, process-lifecycle, singleton]

# Dependency graph
requires:
  - phase: 14-dashboard-drawer
    provides: MediaTab.qml's existing art-ring Shape/ShapePath/PathAngleArc block and Dashboard.qml's per-tab LazyLoader (mediaTabLoader) this plan's claim/release trigger relies on
provides:
  - "CavaService.qml: a pragma-Singleton owning a shared, reference-counted cava subprocess (Process + SplitParser), reachable from both modules/dashboard/ and modules/bar/"
  - "cava/ stow package (cava/.config/cava/config): 60-bar raw-ascii cava config, registered in stow.sh"
  - "Design.cavaLingerMs (5000ms) — the named linger constant later plans must reuse, not reinvent"
  - "Proven claim()/release()/alwaysOn API contract other media surfaces (MediaPopout, in a later plan) will call"
affects: [21-06 (D-21-01 full radial-bar expansion — MUST normalize the verification-only oversized arc this plan ships), 21-plans touching modules/bar/MediaPopout.qml (will call CavaService.claim()/release() using this same pattern)]

# Actuals (#2632)
actuals:
  tokens: 3826
  tasks: 2
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Process + SplitParser for continuous line-buffered subprocess streams (first use of SplitParser in this repo; every prior Process used StdioCollector for one-shot reads)"
    - "Reference-counted singleton ownership (claim()/release()/counter/non-repeating linger Timer that re-reads live state inside onTriggered) — first use of this shape in this repo; built from modules/bar/PopoutController.qml's graceTimer STRUCTURE, not its constant"
    - "Component.onCompleted/onDestruction on a LazyLoader-mounted root Item as a visibility trigger — reuses D-14's existing loader-destroys-on-dismiss architecture instead of adding a separate visibility computation"

key-files:
  created:
    - cava/.config/cava/config
    - quickshell/.config/quickshell/modules/CavaService.qml
  modified:
    - stow.sh
    - quickshell/.config/quickshell/modules/qmldir
    - quickshell/.config/quickshell/modules/dashboard/MediaTab.qml
    - quickshell/.config/quickshell/modules/dashboard/Design.qml

key-decisions:
  - "CavaService registered in the TOP-LEVEL modules/qmldir (not modules/dashboard/qmldir) so modules/bar/MediaPopout.qml can resolve the same singleton instance in a later plan — Colours/Motion are the existing precedent for this cross-directory reach."
  - "Claim/release trigger is MediaTab.qml's own Component.onCompleted/onDestruction, not a separate visibility computation — Dashboard.qml's mediaTabLoader is already active only while the Media tab is current and is destroyed whenever the drawer closes (D-14), so this component's construction/destruction IS the exact 'Media tab genuinely visible' condition the UI-SPEC appendix specifies."
  - "The tracer's initial verification segment (a 3-14px 'clock hand') was rebuilt mid-plan at an oversized, high-contrast form after the human checkpoint reported it unjudgeable ('too small to tell'). This is VERIFICATION-ONLY scaffolding, explicitly marked in-source, and MUST be normalized to real proportions by 21-06 (the full D-21-01 expansion). See 'Known Stubs' below."

patterns-established:
  - "Pattern: Process + SplitParser for continuous streams — mirror ags/lib/cava.ts's exact contract (split on delimiter, drop empty fields, normalise, publish only on a non-empty parse) rather than inventing a new line-handling convention."
  - "Pattern: reference-counted singleton ownership — counter floors at 0; a non-repeating Timer re-reads live state (claim count + any escape-valve flag) INSIDE onTriggered, never trusting state captured at arm time; a single boolean property is the sanctioned reversal knob for 'always keep this resource alive'."

requirements-completed: [QMEDIA-02]

coverage:
  - id: D1
    description: "A cava process spawned and owned by the Quickshell shell publishes live per-band amplitude values into QML, and an on-screen segment on the Media tab visibly changes with real audio (the tracer)"
    requirement: "QMEDIA-02"
    verification:
      - kind: manual_procedural
        ref: "Human checkpoint, this session: 'the pink arc visibly grows and shrinks' with audio playing, and 'settles to a small visible cap rather than vanishing' at silence — VERIFIED against the rebuilt, oversized verification-only overlay (see Known Stubs)."
        status: pass
    human_judgment: true
    rationale: "Visual motion/legibility of an audio-reactive element is a judgment call automation cannot make on its own — the plan's own <human-check> requires it, and the first attempt (a 3-14px segment) was rejected as unjudgeable before this pass rebuilt it at a legible size and got explicit human confirmation."
  - id: D2
    description: "cava is owned by a reference count with a short linger: starts on first claim, survives a claim handover inside the linger window, dies after the linger with zero claimants, and is pinned permanently on by flipping one boolean (alwaysOn)"
    requirement: "QMEDIA-02"
    verification:
      - kind: manual_procedural
        ref: "Live process-table observation this session: cava spawned on first dashboard-open-to-Media-tab; SAME PID observed before/after a close-then-reopen inside the 5s linger window (no respawn); process confirmed gone (pgrep -fc = 0) 7s after dashboard close with no claimants."
        status: pass
      - kind: other
        ref: "Source assertion: OWNERSHIP_API_OK check (claim()/release()/alwaysOn all present); alwaysOn's early-return guard reads root.alwaysOn and root._claimCount inside Timer.onTriggered, not before the Timer declaration; release() floors via Math.max(0, ...)."
        status: pass
    human_judgment: false

# Metrics
duration: ~20min active execution (2 human checkpoint pauses for tracer verification)
completed: 2026-08-16
status: complete
---

# Phase 21 Plan 01: Cava-to-QML Streaming Contract Tracer + Reference-Counted Ownership Summary

**A shell-owned `cava` subprocess streams live per-band amplitude into a QML singleton via `Process`+`SplitParser` (first use of `SplitParser` in this repo), reference-counted by a claim/release/linger model (first use of that ownership shape in this repo) that starts on first claim, survives a claim handover inside a 5s linger, and dies with zero claimants.**

## Performance

- **Duration:** ~20min active execution across 2 human checkpoint pauses
- **Started:** 2026-08-16T04:31:06Z (commit `35affd5`)
- **Completed:** 2026-08-16T04:49:28Z (commit `1425b23`)
- **Tasks:** 2/2 completed
- **Files modified:** 6 (2 created, 4 modified)

## Accomplishments

- Proved the cava-to-QML streaming contract end-to-end on real audio: a new `cava/` stow package (60 bars, raw ascii stdout, delimiter byte-identical to the retiring `ags/cava/config`) feeds a new `CavaService.qml` singleton whose `Process`+`SplitParser` reader mirrors `ags/lib/cava.ts`'s proven line-handling contract exactly (split on `;`, drop empty fields, `/100` normalise, publish only on a non-empty parse, length-capped at 60 bars).
- Registered `CavaService` as a top-level `modules/qmldir` singleton (not `modules/dashboard/qmldir`) so `modules/bar/MediaPopout.qml` can resolve the same instance in a later plan — the same cross-directory pattern `Colours`/`Motion` already establish.
- Built the reference-counted ownership model D-21-06 requires: `claim()`/`release()` with a counter that floors at 0, a non-repeating linger `Timer` (`Design.cavaLingerMs`, 5000ms) that re-reads the live claim count and the `alwaysOn` escape-valve flag INSIDE `onTriggered` (mirroring `PopoutController.qml`'s `graceTimer` structure, not its constant), and a single-property `alwaysOn` reversal the operator can flip without restructuring anything.
- Wired the claim trigger to `MediaTab.qml`'s own `Component.onCompleted`/`Component.onDestruction` — no separate visibility computation was needed because `Dashboard.qml`'s `mediaTabLoader` is already `active` only while the Media tab is current and is destroyed whenever the drawer closes (D-14), so this component's construction/destruction IS the "genuinely visible" condition. No playback-state term anywhere in the trigger (pausing never releases, per the UI-SPEC appendix).
- Live-verified the full lifecycle on this host: process spawns on first claim; the SAME PID survives a close-then-reopen inside the 5s linger window (no respawn, no re-paid ~350ms cold start); the process is confirmed dead 7s after the dashboard closes with zero claimants.

## Task Commits

Each task was committed atomically, plus one mid-plan fix commit driven by human checkpoint feedback:

1. **Task 1: End-to-end "one bar moves to real audio" — one path only** — `35affd5` (feat)
2. **Fix: rebuild tracer at a human-judgeable verification size** — `2aa267e` (fix) — see Deviations below; not a planned task, a checkpoint-driven correction to Task 1's own deliverable.
3. **Task 2: Reference-counted ownership with a short linger and a one-knob always-on** — `1425b23` (feat)

## Files Created/Modified

- `cava/.config/cava/config` — new stow package config: 60 bars, `framerate = 60`, raw ascii stdout, `bar_delimiter = 59` (byte-identical to `ags/cava/config`'s delimiter).
- `stow.sh` — registers `cava` in the packages array, alphabetically after `ags`.
- `quickshell/.config/quickshell/modules/CavaService.qml` — new `pragma Singleton`: `Process`+`SplitParser` reader, `claim()`/`release()`/`alwaysOn`, linger `Timer`.
- `quickshell/.config/quickshell/modules/qmldir` — adds `singleton CavaService 1.0 CavaService.qml`.
- `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml` — adds the verification-only overlay Shape (see Known Stubs) and the `Component.onCompleted`/`onDestruction` claim/release wiring on the root `Item`.
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — adds `readonly property int cavaLingerMs: 5000`.

## Decisions Made

- **CavaService lives at the top level of `modules/`, not `modules/dashboard/`.** `MediaPopout.qml` (a later plan) must resolve the same singleton instance, and `Colours`/`Motion` are the established precedent for a singleton reached from both `dashboard/` and `bar/`.
- **The claim/release trigger reuses `Dashboard.qml`'s existing per-tab `LazyLoader` lifecycle rather than adding a new visibility computation.** `mediaTabLoader` is `active` only while the Media tab is current and is torn down whenever the drawer closes (D-14) — `MediaTab.qml`'s own `Component.onCompleted`/`onDestruction` is therefore already exactly "Media tab genuinely visible" / "stopped being visible", with zero extra state to maintain or drift.
- **The tracer's verification segment was rebuilt mid-plan, not merely restyled**, after the human checkpoint reported the original 3-14px "clock hand" as unjudgeable ("too small to tell", confused with the progress bar). See Deviations and Known Stubs.
- **The verification overlay reads `Math.max(...CavaService.bars)` (peak across all 60 bands), not `bars[0]` alone**, specifically to make the human gate reliable — a single low-index band can sit near-silent for dialogue-heavy content even while the underlying stream is genuinely live, which would read as a false negative on the gate. This is a verification-only choice and does not reflect how the real per-band mapping will work in 21-06.

## Deviations from Plan

### Auto-fixed / Checkpoint-driven Issues

**1. [Checkpoint feedback — verification-affordance defect, not a logic defect] Tracer segment rebuilt at a human-judgeable size**
- **Found during:** Task 1's checkpoint (first presentation)
- **Issue:** The plan's own acceptance criteria specified a subtle "clock hand" segment (3px sliver to 14px at full amplitude, 3px stroke width) alongside the existing dashed ring. This was functionally correct (verified via live process spawn, real non-zero cava output, and a measurable frame-to-frame pixel diff) but the human operator could not distinguish it from the track progress bar and reported "too small to tell" / "the visualizer does not work".
- **Fix:** Replaced the small radial segment with a thick (16px), high-contrast (`Colours.error`) partial ring painted directly on top of the cover art, sweeping from a 20° floor (silence never vanishes) to a near-complete 300° ring at full amplitude, driven by the peak across all 60 bands rather than `bars[0]` alone. Explicitly marked in-source as verification-only scaffolding.
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml`
- **Verification:** `colour-lint` 144/0; live screenshot comparison showed a 5410/90000-pixel (6%) frame-to-frame AE diff in the ring's crop region during a loud passage, versus 0.36-0.61 pixels for the original design; human checkpoint explicitly confirmed both the growth/shrink motion and the silence-floor behaviour on the rebuilt form.
- **Committed in:** `2aa267e`

---

**Total deviations:** 1 checkpoint-driven correction (not a Rule 1-4 auto-fix in the strict sense — it was a human-flagged verification-affordance defect in the plan's own specified geometry, corrected in-session and re-verified before the gate was allowed to pass).
**Impact on plan:** No scope creep. The underlying architecture (CavaService, the streaming contract, the ownership model) is unchanged; only Task 1's on-screen verification geometry was resized. This oversized form is temporary by design (see Known Stubs) and does not affect Task 2 or any later plan's contract with `CavaService`.

## Issues Encountered

None beyond the checkpoint-driven correction above. No auth gates. No blocking issues.

## Known Stubs

**The Media tab's cava-verification overlay (`MediaTab.qml`'s `cavaVerifyOverlay`/`cavaVerifyPath`) is deliberately oversized, verification-only scaffolding — NOT the phase's final visual design.**

- **File:** `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml`
- **What it is today:** a single thick (16px), `Colours.error`-coloured arc painted on top of the cover art, sweeping 20°-300° driven by the peak across all 60 published bands.
- **Why it exists at this size:** the plan's originally-specified geometry (a 3-14px segment) proved unjudgeable by the human verification gate. This oversized form exists solely so a human could confirm the underlying cava-to-QML pipe actually works — it is explicitly commented in-source as verification-only.
- **What must happen next:** **21-06 (the D-21-01 full radial-bar expansion) owns normalizing this to real proportions** — replacing this whole block with a properly-scaled `Repeater` of 60 individually-mapped bars per 21-UI-SPEC.md's "Visualiser Geometry" table (inner radius = `ringRadius`, max outer radius = `ringRadius + 14`, minimum sliver = 3px, stroke width = 2px, `Colours.outline`→`Colours.primary` transition). **This must not silently ship at its current oversized proportions** — if 21-06 is skipped or delayed, this stub is the visible evidence that the phase's real visualiser was never built.
- **Human gate status:** the human checkpoint PASSED against this oversized form specifically — both "grows/shrinks with audio" and "settles to a visible cap at silence" were confirmed against the verification-only arc, not against 21-06's eventual real geometry. A later reader should not mistake this pass as validating the final visual design.

## User Setup Required

None — no external service configuration required. The `cava` stow package was stowed live on this host during verification (`stow cava`); a fresh install already includes `cava` in `stow.sh`'s packages array, so no manual step is needed there either.

## Next Phase Readiness

- `CavaService.qml`'s `claim()`/`release()`/`alwaysOn`/`bars`/`streaming` API is proven and ready for `modules/bar/MediaPopout.qml` to consume in a later plan (D-21-05's second visualiser host) — the singleton is already reachable from `modules/bar/` via the top-level `modules/qmldir` registration.
- `Design.cavaLingerMs` is the named constant later plans must reuse for anything cava-lifecycle-related; do not reintroduce a second linger value.
- **Blocker for 21-06 specifically:** 21-06 must replace `MediaTab.qml`'s current verification-only overlay with the real 60-bar `Repeater` per 21-UI-SPEC.md's Visualiser Geometry table — this is not optional cleanup, it is the phase's actual QMEDIA-02 deliverable. See Known Stubs above.

---
*Phase: 21-media-fold-in-contract-close*
*Completed: 2026-08-16*

## Self-Check: PASSED

All 6 created/modified files confirmed present on disk; all 3 task/fix commit hashes (`35affd5`, `2aa267e`, `1425b23`) confirmed in git history.
