---
phase: 08-waybar-evolution
plan: 10
subsystem: infra
tags: [waybar, gtk3-css, hyprland-ipc, oled, grim, python3-pillow-numpy, bash]

# Dependency graph
requires:
  - phase: 08-waybar-evolution
    provides: "08-03's waybar-visibility.sh (the single visibility owner) and bar-common.jsonc's fixed on-sigusr1:hide/on-sigusr2:reload signal contract; 08-04's 120s idle timeout (D-05)"
provides:
  - "BAR-02 CLOSED as DESCOPED, with a written, reproducible evidence artifact (D-10) — no silent drop"
  - "A load-bearing, mechanism-independent finding: waybar's ONLY owner-driven CSS actuation path (SIGUSR2/reload, fixed by bar-common.jsonc) produces a real, measured, reproducible visual flash AND a real transient window reflow on every single invocation — this is a more fundamental blocker for any future OLED pixel-shift attempt than the specific displacement mechanism (CSS margin/padding) chosen"
  - "A real, measured luminance delta for D-06's OLED trim (dark mean -39.27%, dark peak +1.36%, light mean -3.16%, light peak -9.18%) — the first empirical number behind what was previously an asserted claim"
  - "An honestly UNMEASURED exposure-ratio finding (187 real samples, 15.53 min, 100% visible) with the exact reason recorded, rather than a fabricated or extrapolated ratio"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Actuation-cost-first spike ordering: measure whether the ONLY available signal path itself twitches/reflows BEFORE spending timebox on the specific displacement mechanism it would carry — this pre-gate (K0-a) is reusable methodology for any future waybar CSS-mutation feature, not just pixel-shift"
    - "Surgical two-rule CSS swap (diffed against the pre-trim commit to confirm scope) for a temporary BEFORE-state photometric measurement, rather than a whole-file historical restore — avoids silently reintroducing unrelated drift from later plans (08-04/08-05's gaming-mode block, the visibility-owner CSS import) into a measurement meant to isolate one trim"

key-files:
  created:
    - .planning/phases/08-waybar-evolution/08-BAR-02-EVIDENCE.md
    - .planning/phases/08-waybar-evolution/.bar-02-spike-log.md
    - .planning/phases/08-waybar-evolution/.bar-02-samples.tsv
  modified: []

key-decisions:
  - "K0-a (actuation-cost pre-gate) correctly ended the spike in ~4 minutes of real measurement against a 90-minute hard budget — the plan's own explicit 'honest fast path,' not a shortcut around measuring: once the owner's only signal path (SIGUSR2/reload) was shown to flash and transiently reflow on every invocation, testing whether CSS margin/padding also moves 2px of content became moot, since neither mechanism has any other way to reach the running bar"
  - "Reported the exposure ratio as UNMEASURED rather than as a ratio of 1.0 or an extrapolated number, on two independent grounds stated in the plan itself: the session (187 samples, 15.53 min) fell short of the required >=60-min/>=720-sample floor, AND it was degenerate (100% visible, zero idle stretches) — exactly the kind of unrepresentative window the plan's own text warns against treating as evidence in either direction"
  - "Chose PARTIALLY SUPPORTED (of the plan's exactly three permitted hypothesis labels) rather than inventing additional labels — the dark-preset mean luminance reduction is real and substantial, but the dark-preset peak increase and the unmeasured exposure ratio mean an unqualified SUPPORTED would overclaim, and dismissing the mean result would equally overclaim in the other direction"
  - "Used the `full` layout (not the session's actual `floating` layout) for the luminance BEFORE/AFTER measurement specifically because floating's pre-trim window#waybar was fully transparent with no border at all (per 08-03-SUMMARY.md) and has no comparable BEFORE state for this trim; switched back to floating immediately after, confirmed via live hyprctl layers geometry matching the pre-test baseline"

patterns-established:
  - "Actuation-cost-first spike ordering (see tech-stack.patterns) — any future plan proposing a periodic owner-driven CSS mutation on this bar should measure the owner's signal-path cost BEFORE the mutation's own content, since the signal path itself is now known to have a real, reproducible visual/layout cost"

requirements-completed: [BAR-02]

coverage: []  # descope-with-evidence outcome; prose Accomplishments below is the record.

# Metrics
duration: ~23min
completed: 2026-07-14
status: complete
---

# Phase 8 Plan 10: BAR-02 Pixel-Shift Spike — Descoped With Measured Evidence Summary

**D-09's timeboxed spike measured a real, reproducible flash and transient window reflow on waybar's only CSS-actuation signal path (SIGUSR2/reload) — mechanism-independent, so it kills any CSS-based jitter before the 2px displacement question is even reached — and closes BAR-02 as DESCOPED with a written, reproducible evidence artifact per D-10, plus a real (not asserted) luminance-delta measurement of the D-06 OLED trim.**

## Performance

- **Duration:** ~23 min
- **Started:** 2026-07-14T19:41:09Z (monitor re-confirmation, first command)
- **Completed:** 2026-07-14T20:04:30Z
- **Tasks:** 3 completed
- **Files modified:** 3 (all created; 0 modified — descope branch touches no code)

## Accomplishments

- **Re-confirmed the monitor before any measurement**, per the orchestrator's explicit gate: `hyprctl -j monitors` showed exactly 1 monitor (`DP-1`, 2560x1440@165Hz, connected, focused) before the spike began.
- **Gate K0-a (actuation-cost pre-gate) fired on BOTH measured sub-costs, ending the spike in ~4 minutes against a 90-minute hard budget.** Fired the owner's own `reassert` (a bare SIGUSR2/`reload` — the ONLY signal any owner-driven CSS change has to reach the running bar, per `bar-common.jsonc`) while the bar's computed state was unchanged, and measured, confirmed reproducibly:
  - **Flash cost:** a real, visible flash on every actuation — `grim` burst captures + inline Python/PIL/numpy mean-RGB diff showed a peak delta of ~65-80 (against a stable ~0.03 baseline noise floor), decaying over ~400-500ms, reproduced 2/2 independent runs with matching peak magnitude and decay shape. Visually confirmed by reading the actual pre/peak-diff frames as images, not just trusting the numbers.
  - **Reflow cost:** a real, transient window reflow — `hyprctl clients -j` polled at 30-50ms across the signal showed both tiled test windows' `at`/`size` shift by exactly the bar's own reserved height (Δ37px) for one sample, then snap back on the very next sample, reproduced 3/3 independent runs with an identical delta each time. A zero-signal control burst (10 samples, no reload fired) confirmed zero polling noise, ruling out measurement artifact.
- **Cross-checked the reflow finding against `08-03-SUMMARY.md`'s exclusive-zone claim, per the plan's explicit instruction, and found no contradiction — but new information.** 08-03's coarse before/after snapshot (its own methodology) is reproduced exactly here at the same granularity (no change). What's new is a transient reflow invisible to any snapshot spaced more than ~50ms apart — new evidence, not a disagreement with prior work.
- **K0-b (M1/M2 displacement-mechanism probing) was correctly skipped**, per the plan's own "honest fast path" instruction — testing whether CSS margin/padding moves 2px of content is moot once the only actuation path for that CSS change already, independently, flashes and reflows on every invocation. M3 (bar-config margin rewrite) was disqualified by design with its kill-#2 claim substantiated by reusing the K0-a measurement directly (an argument converted into a number). M4 (`reload_style_on_change`) was deliberately not enabled, to avoid re-snapshotting the `waybar-equivalence-check` baseline 08-08 was also touching in this same wave.
- **All three D-09 kill criteria were evaluated with a named method, instrument, and raw result** — K1 FAILS on two independent grounds (the measured flash, folded in per the plan's own instruction, and the FAIL-CLOSED default since no human perception pass is obtainable in an autonomous execution with no live interactive channel); K2 FAILS on the measured transient reflow; K3 is recorded N/A-moot (structurally satisfiable in principle, but never decisive since K1/K2 already end the spike).
- **Measured the standing hypothesis's luminance half for real**, BEFORE/AFTER the D-06 trim, using Rec.709 relative luminance on linearised sRGB (mean + 99th-percentile peak), under both the dark preset (catppuccin, the session's actual theme) and the light preset (catppuccin-latte): dark mean -39.27%, dark peak +1.36% (a real, reported anomaly — not smoothed over), light mean -3.16%, light peak -9.18%. Used a surgical two-rule CSS swap (verified via `git diff` against the pre-trim commit that only two rules had changed in either file) rather than a whole-file historical restore, avoiding contamination from later plans' unrelated CSS additions (gaming-mode indicator, the visibility-owner CSS import).
- **Measured the exposure-ratio half honestly, and reported it UNMEASURED rather than fabricated.** A real 5-second sampling loop against the owner's own `status` output ran for 187 samples over 15.53 minutes — short of the plan's required >=60-min/>=720-sample floor, and degenerate (100% `visible`, zero idle stretches observed, consistent with genuine ongoing human input on this shared machine resetting hypridle's real timer throughout the window, per `08-04-SUMMARY.md`'s own documented pattern of this exact interference). No synthetic input was injected to manufacture a transition either way.
- **Closed BAR-02 as DESCOPED with `08-BAR-02-EVIDENCE.md`** — the unconditional deliverable, written under a literal `## BAR-02` heading that pastes verbatim into `08-VERIFICATION.md`: verdict, what was attempted (M1-M4 with readbacks), the five-row gate table, which gate fired (explicitly NOT conflated with "mechanism unavailable" — a distinct, more fundamental finding), the standing-hypothesis evaluation (PARTIALLY SUPPORTED — one of the plan's exactly three permitted labels), residual risk, and reproduce commands.
- **Re-ran `waybar-equivalence-check` after all live testing: still PASS 4/4** (floating, full, minimal, vertical) — no layout regression from the live layout-switching this plan's measurements required. `keybind-doctor` stayed at 8/8. `theme-doctor` stayed at 96/97 (the one pre-existing failure is the git-clean check, already documented in `deferred-items.md` by earlier plans, unrelated to this plan).
- **Left the live session exactly as clean as it started**: waybar back on the `floating` layout (the session's actual layout before this plan), theme back to `catppuccin`/dark (the session's actual theme), `git status --porcelain waybar/` empty throughout and at the end, the owner's `waybar-visibility.sh` and `autostart.conf` untouched (`git diff HEAD` empty on both, confirming the descope branch shipped no code).

## Task Commits

1. **Task 1: The timeboxed spike — mechanism viability, then D-09's three kill criteria, each measured** - `78de0f6` (test)
2. **Task 2: Demonstrate the standing hypothesis — measured exposure ratio and measured luminance delta** - `051d13f` (test)
3. **Task 3: Close BAR-02 — write the evidence artifact (descope branch)** - `a8877ca` (docs)

## Files Created/Modified

- `.planning/phases/08-waybar-evolution/.bar-02-spike-log.md` - New. Raw, timestamped command/output log for every gate and both Task 2 measurements — every number in the evidence artifact traces back to a line here.
- `.planning/phases/08-waybar-evolution/.bar-02-samples.tsv` - New. Raw duty-cycle samples (187 rows) backing the honestly-UNMEASURED exposure ratio.
- `.planning/phases/08-waybar-evolution/08-BAR-02-EVIDENCE.md` - New. The unconditional BAR-02 closure artifact; its body pastes verbatim into `08-VERIFICATION.md` as a `## BAR-02` section.
- `hypr/.config/hypr/scripts/waybar-visibility.sh` - **Untouched** (descope branch; `git diff HEAD` confirmed empty).
- `hypr/.config/hypr/config/autostart.conf` - **Untouched** (descope branch; `git diff HEAD` confirmed empty).
- No `waybar/.config/waybar/*` file left modified — `git status --porcelain waybar/` confirmed empty at every checkpoint, including immediately after the two temporary BEFORE-state CSS swaps used for the luminance measurement.

## Decisions Made

See `key-decisions` in the frontmatter above — summarized: (1) K0-a's early, decisive fast-path exit was taken as the plan explicitly sanctions; (2) the exposure ratio was reported UNMEASURED rather than forced into a number; (3) the hypothesis verdict was pinned to exactly one of the plan's three permitted labels (PARTIALLY SUPPORTED); (4) the luminance measurement used the `full` layout rather than the session's actual `floating` layout, specifically because only `full`'s pre-trim stylesheet has a comparable non-transparent BEFORE state.

## Deviations from Plan

None — plan executed exactly as written, including its own explicitly-sanctioned "honest fast path" (ending K0-b/K1/K2/K3 code-writing once K0-a fired) and its explicit permission to report Part A as UNMEASURED when a valid session cannot be obtained. No Rule 1/2/3 auto-fixes were needed: this plan's descope branch ships no code, only measurement and a written artifact, so there was no implementation to have bugs, missing functionality, or blocking issues in.

## Issues Encountered

- **An early, unrelated interactive walker picker (`theme-switch.sh` with no argument) was accidentally launched while probing for a non-interactive theme-application entrypoint.** Recognized immediately as a stray interactive prompt on the live desktop, killed cleanly (`kill` on the `theme-switch.sh`/`walker --dmenu` PIDs), confirmed no orphaned process remained, and switched to the correct non-interactive `theme-apply <preset>` entrypoint for all subsequent theme switches. No user-visible impact beyond a momentarily-open picker that was never interacted with.
- **A whole-file historical restore of `style-full.css`/`waybar-modules.css` was attempted first for the luminance BEFORE measurement, then immediately recognized as wrong and reverted before any capture was taken** — the pre-trim commit predates several later plans' unrelated CSS additions (the gaming-mode indicator, the visibility-owner CSS import), so a whole-file restore risked contaminating the measurement with unrelated missing styling, not isolating the D-06 trim. Corrected to a surgical two-rule swap (confirmed via `git diff` against the pre-trim commit that only two rules had actually changed), verified byte-identical restoration afterward. No incorrect data was captured or reported — the correction happened before the first BEFORE capture.
- **The exposure-ratio sampling window could not reach the plan's own >=60-minute/>=720-sample validity floor within this single autonomous execution** — no blocking wait primitive is available for tens of real minutes without an impractical number of manual poll cycles, and the plan explicitly forbids padding a short window with synthetic data. Resolved by reporting the collected 187-sample/15.53-minute window honestly as UNMEASURED, with the exact reason stated in both the spike log and the evidence artifact, per the plan's own explicit permission for this situation.

## User Setup Required

None - no external service configuration required. This plan shipped no runtime code on either branch's actually-taken path (descope); the evidence artifact and raw logs are pure documentation/measurement.

## Next Phase Readiness

- **BAR-02 is CLOSED** (marked complete in `REQUIREMENTS.md` via this plan's state update) — descoped, not silently dropped, per D-10. `08-VERIFICATION.md` (when phase 8 is verified) should paste `08-BAR-02-EVIDENCE.md`'s body verbatim as its `## BAR-02` section.
- **A concrete, load-bearing lead for any future attempt at this requirement**: the blocker is not "does CSS margin/padding move 2px" — it's that waybar's only owner-driven CSS actuation path (`SIGUSR2`/`reload`) itself flashes and transiently reflows on every invocation. A future phase would need an actuation path with zero reflow/flash (candidate: `reload_style_on_change`, noted but deliberately not spiked here to avoid colliding with 08-08's equivalence-baseline re-snapshot in this same wave) before the displacement question is even worth re-asking.
- `waybar-equivalence-check` remains green (4/4) — this plan's live layout-switching (used only for the luminance measurement) caused no regression.
- No known stubs — the descope branch's only deliverables are measurement artifacts and a written evidence document; there is no runtime feature to have a stub in.

---
*Phase: 08-waybar-evolution*
*Completed: 2026-07-14*

## Self-Check: PASSED

All 4 claimed files verified present on disk (`.bar-02-spike-log.md`, `.bar-02-samples.tsv`, `08-BAR-02-EVIDENCE.md`, `08-10-SUMMARY.md`); all 3 commit hashes (`78de0f6`, `051d13f`, `a8877ca`) verified present in `git log --oneline --all`.
