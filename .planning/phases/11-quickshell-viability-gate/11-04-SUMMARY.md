---
phase: 11-quickshell-viability-gate
plan: 04
subsystem: infra
tags: [quickshell, qml, hyprland, layer-shell, hotplug, hot-reload, gate-script]

requires:
  - phase: 11-quickshell-viability-gate (plan 03)
    provides: quickshell-doctor rerunnable gate script, QS-05/QS-06 mechanical checks
provides:
  - quickshell-doctor headless-output hotplug check group (add/per-screen/reserved/remove), --no-headless-output flag
  - Verified, mechanically-honest QS-03 finding: current probe design does not fan out per-screen (open gap, D-10 non-blocking)
  - QS-04 answered in the affirmative: FileView/JsonAdapter needs zero reload.sh involvement; lib/reload.sh untouched
  - Suspend/resume (D-08) proven: same PID, all input tests re-pass, reserved-space and GlobalShortcut registration both survive
affects: [11-05-PLAN, phase-12-token-pipeline, phase-14-dashboard-drawer]

tech-stack:
  added: []
  patterns:
    - "Hotplug gate check group in a rerunnable *-doctor script: removal trap armed before the mutating create call, name read back from the monitor list (never assumed), pre-existing-named-resource guard, SIGINT-safe"
    - "Record-the-limitation-and-revert: attempted QML fix for a real defect, found it introduced two independent reliability regressions on the live daemon, reverted to the known-good state and documented the attempt in the evidence artifact rather than shipping instability"

key-files:
  created: []
  modified:
    - hypr/.config/hypr/scripts/quickshell-doctor
    - .planning/phases/11-quickshell-viability-gate/11-QUICKSHELL-EVIDENCE.md
    - .planning/STATE.md

key-decisions:
  - "QS-03 per-screen mounting fix (Variants-based) attempted and reverted after finding two independent live-daemon reliability regressions; recorded as an open, non-blocking gap per D-10 rather than shipped unstable"
  - "QS-04 open question #1 answered in the affirmative: FileView/JsonAdapter propagates with zero reload.sh involvement; lib/reload.sh is NOT modified (D-13 negative branch)"

patterns-established:
  - "quickshell-doctor's headless-output group is the template for any future Quickshell hotplug-adjacent check: baseline capture, name-diffed add, address-compared per-surface assertion, diffed (not literal) reserved-space check, and a remove step that also re-validates the untouched screen and PID continuity"

requirements-completed: [QS-04]

coverage:
  - id: D1
    description: "quickshell-doctor gains a headless-output hotplug check group (add/per-screen surface creation/reserved-unchanged/remove), gated behind --no-headless-output, with a removal trap and a pre-existing-HEADLESS guard"
    requirement: "QS-03"
    verification:
      - kind: other
        ref: "hypr/.config/hypr/scripts/quickshell-doctor — live run, mechanics (add/reserved/remove) PASS, per-screen surface creation FAILS (real defect, not a harness artifact)"
        status: fail
    human_judgment: true
    rationale: "QS-03's own success criterion (surfaces render correctly on every connected monitor) is not met by the current single-instance probe design — a real, mechanically-verified gap, not something a human sign-off can wave through. Left open for a future plan; not a stop-trigger (D-10)."
  - id: D2
    description: "QML source hot-reload verified: editing a live QML property propagates with no restart and no theme-apply involvement, and the revert propagates the same way"
    requirement: "QS-04"
    verification:
      - kind: other
        ref: "hyprctl layers -j width/height diff before and after an implicitWidth edit, same PID throughout"
        status: pass
    human_judgment: false
  - id: D3
    description: "FileView/JsonAdapter hand-edit propagation answers roadmap open question #1 in the affirmative (zero reload.sh involvement); absent-file case degrades gracefully to the JsonAdapter default"
    requirement: "QS-04"
    verification:
      - kind: manual_procedural
        ref: "Human operator: hand-edited probe.json in a text editor while the probe was on screen, watched the label update live; deleted the file and confirmed the default + shell aliveness"
        status: pass
    human_judgment: true
    rationale: "The whole point of this check is a human watching actual rendered pixel content — the plan's own <human-check> tag, not mechanically inferable."
  - id: D4
    description: "Suspend/resume cycle (D-08): same PID before and after, all three input tests re-pass, reserved-space and GlobalShortcut registration both survive"
    requirement: "QS-03"
    verification:
      - kind: manual_procedural
        ref: "Human operator: systemctl suspend + wake, pgrep -x quickshell PID comparison, click/type/click-outside-dismiss re-test, hyprctl monitors/globalshortcuts checks"
        status: pass
    human_judgment: true
    rationale: "Requires physically suspending and waking the machine and re-testing pointer/keyboard input by hand — cannot be scripted without ending the session, per D-08."

duration: multi-session (checkpoint pause for human observation)
completed: 2026-07-26
status: complete
---

# Phase 11 Plan 04: Durability — Hotplug, Hot-Reload, Suspend/Resume Summary

**quickshell-doctor gains a headless-output hotplug gate that honestly fails on a real, previously-unproven per-screen mounting defect; QS-04's open question #1 is answered in the affirmative (zero reload.sh involvement needed); suspend/resume proven clean.**

## Performance

- **Duration:** multi-session — paused at a checkpoint for human observation (FileView label watch, suspend/resume + click/type/dismiss re-test), resumed and completed after the human reported results
- **Completed:** 2026-07-26
- **Tasks:** 3 (all executed; Task 1's mechanical check honestly reports a real, open finding rather than a synthetic pass)
- **Files modified:** 3 (`quickshell-doctor`, `11-QUICKSHELL-EVIDENCE.md`, `STATE.md`)

## Accomplishments

- `quickshell-doctor` gained a fourth check group: the full `hyprctl output create/remove headless` cycle, with a removal trap armed before the mutating create call, a name-diffed (never-hardcoded) new-output detection, a per-screen surface-address comparison, a diffed (never-literal) reserved-space check, and PID/log-health verification on removal. Verified SIGINT-safe at two different points mid-cycle and correctly `[SKIP]`s around a pre-existing `HEADLESS*` monitor without touching it.
- Discovered and honestly recorded a real QS-03 defect: the current single-`PanelWindow` probe design only ever mounts on whichever screen existed at shell startup — a headless output added afterward gets zero surfaces, not its own. This is a genuine gap in the toolkit-facing QML, not a virtual-output test-harness artifact.
- Attempted a `Variants`-based per-screen fix in several arrangements; found two independent reliability regressions on this quickshell 0.3.0 build (an intermittent hard config-load failure, and a case where the summon shortcut stopped working entirely on every screen after a hotplug) — both discovered live against the always-on autostart daemon. Reverted rather than ship instability against a process later phases depend on; the live daemon is confirmed restored to its known-good state.
- Verified QML source hot-reload mechanically (no human required): a live property edit propagates within ~0.4s with no restart and no `theme-apply` involvement, and the revert propagates identically.
- Verified `FileView`/`JsonAdapter` hand-edit propagation via human observation: roadmap open question #1 is answered in the affirmative — zero `reload.sh` involvement needed. `lib/reload.sh` is untouched (D-13's negative branch).
- Verified suspend/resume (D-08) via human operator: same PID before and after, all three input tests (click/type/click-outside-dismiss) re-pass, `reserved` unchanged, and the `quickshell:probe` GlobalShortcut registration survives the cycle.

## Task Commits

1. **Task 1: Exercise monitor hotplug with a Hyprland headless output (QS-03)** — `9b15171` (feat)
2. **Task 1 (docs): record QS-03 hotplug + QS-04(a) findings** — `31692d4` (docs)
3. **Checkpoint continuity note** — `584394c` (docs)
4. **Task 2(b)/Task 3: complete evidence with human-observed checkpoint results** — `6f84bed` (docs)

**Plan metadata:** (this commit)

_Note: Task 1's own commit intentionally lands a check group that FAILs on a real, honestly-recorded finding — this is correct execution, not an incomplete task; see Deviations below._

## Files Created/Modified

- `hypr/.config/hypr/scripts/quickshell-doctor` — headless-output hotplug check group, `--no-headless-output` flag, extended cleanup trap
- `.planning/phases/11-quickshell-viability-gate/11-QUICKSHELL-EVIDENCE.md` — QS-03/QS-04 gate table rows, full Task 1/2/3 write-ups, dated gate log entry
- `.planning/STATE.md` — checkpoint continuity note, QS-03 gap recorded in Blockers/Concerns

## Decisions Made

- **QS-03 per-screen mounting fix reverted, not shipped.** A `Variants { model: Quickshell.screens }` fan-out is the standard, correctly-typed (verified against this build's own installed `.qmltypes` files) Quickshell pattern for per-monitor surfaces, and was implemented in several arrangements (direct, through a `LazyLoader`/`Loader` layer, in both nesting orders, and with the fan-out moved inside `Probe.qml` itself). All were reverted after finding two independent, reproducible reliability regressions against the live, always-on autostart daemon: an intermittent hard "Probe is not a type" config-load failure (byte-identical file content loaded cleanly on some restarts and failed on others — pointing at a startup race in quickshell 0.3.0's own directory-based local-type scanner, not a QML syntax defect) and a separate case where the summon shortcut stopped toggling visibility on any screen at all after a monitor was hotplugged. Given standing constraint 5 (do not casually kill the running daemon; if a test requires restarting it, restore it and say so) and this phase's own house rule (record the limitation, take the workable path, don't chase an open-ended workaround), the fix was reverted. The live daemon is confirmed restored to its known-good, single-instance, reliably-loading state. This is not a QS-02 failure and does not stop the milestone (D-10) — it is an open, disclosed gap for a future plan.
- **QS-04 open question #1 closes in the affirmative.** `FileView`/`JsonAdapter` propagation needs zero `reload.sh` involvement — confirmed by direct human observation, not merely by trusting the documentation (which the plan explicitly required). `theme-engine/.config/theme-engine/lib/reload.sh` is untouched; adding a quickshell reload step now would be dead config per D-13.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug, attempted and reverted] QS-03 per-screen mounting**
- **Found during:** Task 1
- **Issue:** The single-`PanelWindow` probe design (unchanged since 11-01) only mounts on whichever screen existed at shell startup; a headless output added afterward gets zero surfaces.
- **Fix attempted:** `Variants { model: Quickshell.screens }` fan-out, tried in several arrangements (direct; through `LazyLoader`/`Loader`; fan-out moved inside `Probe.qml`).
- **Outcome:** Reverted. Found two independent, reproducible reliability regressions on the live daemon (intermittent config-load race; post-hotplug visibility break) that risked leaving the production autostart daemon in a broken state. `modules/Probe.qml` and `shell.qml` are confirmed byte-identical to their pre-11-04 state (`git status --porcelain quickshell/` empty); the live daemon was restarted and reconfirmed working before the plan continued.
- **Files touched during the attempt, all reverted:** `quickshell/.config/quickshell/shell.qml`, `quickshell/.config/quickshell/modules/Probe.qml` (git history shows no net diff for this plan on these files).
- **Verification:** `quickshell-doctor`'s new per-screen surface creation check honestly FAILs (13 passed, 1 failed, exit 1), correctly reflecting ground truth rather than a synthetic PASS.
- **Committed in:** N/A (reverted before commit; the working, honest FAIL state is what commit `9b15171` captures)

---

**Total deviations:** 1 attempted-and-reverted (Rule 1, architectural-risk territory). No scope creep — the revert restores the pre-existing, proven-stable behavior; nothing shipped in a worse state than before this plan started.
**Impact on plan:** `quickshell-doctor` now exits 1 (13 passed, 1 failed) instead of 0, honestly reflecting a real, previously-unproven QS-03 gap. This does not stop the milestone (D-10 — only QS-02 has stop authority) and is fully disclosed in the evidence artifact, `STATE.md`, and this summary.

## Known Stubs

None. No hardcoded empty values, placeholder text, or unwired data sources were introduced. The one open item — the empty-JSON-object case for `FileView`/`JsonAdapter` (Task 2's action text asked for it; the human operator did not test this specific sub-case during the checkpoint) — is recorded honestly as untested in the evidence artifact, not inferred or assumed.

## Threat Flags

None. This plan added a check group to an existing gate script (no new network endpoint, auth path, or trust boundary) and reverted the one QML change that was attempted; the threat model's existing T-11-15/T-11-16/T-11-17/T-11-18 entries already cover this plan's actual surface.

## Issues Encountered

- Extensive live debugging of an intermittent quickshell 0.3.0 config-load failure ("Probe is not a type") that reproduced with byte-identical file content across some but not all clean process restarts — root-caused (as far as available time allowed) to a likely startup race in Quickshell's own directory-based local-type scanner (`modules/qmldir` synthesis sometimes completing before, sometimes after, the `Variants` delegate's compile-time type resolution needs it). Not fixable from QML source alone within this plan's time budget; recorded as a limitation rather than chased further, per this phase's established house rule.
- A related, more subtle regression was found in the same exploration: once a second screen existed, the probe's summon `GlobalShortcut` stopped toggling visibility on ANY screen (including the previously-working one), with no error logged. Both findings are preserved in the evidence artifact for whoever next attempts this fix.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- QS-04 fully closed (both halves PASS); `lib/reload.sh` confirmed to need no quickshell step.
- QS-03 has an open, disclosed gap (per-screen mounting) that does not block Phase 12/13 (neither depends on multi-monitor Quickshell surfaces) but should be revisited before Phase 14's dashboard drawer, which will be the first surface where "does this render correctly if a monitor is added/removed" becomes a real user-facing question rather than a probe-only concern.
- `quickshell-doctor` currently exits 1 (13 passed, 1 failed) — this is expected and disclosed, not a regression to chase in the next plan; plan 11-05 (screencopy feasibility + phase verdict) should read this summary and the evidence artifact before writing the final phase verdict, since QS-03's gate-table row is "OPEN", not "PASS".
- `theme-doctor` reconfirmed green (136 passed / 0 failed, exit 0) — this plan touched zero `theme-engine/` files, so this is a no-incidental-breakage confirmation, not a targeted test.
- Live daemon confirmed healthy: same shell ID, single monitor, no stray layer surfaces, `git status --porcelain` clean.

---
*Phase: 11-quickshell-viability-gate*
*Completed: 2026-07-26*
