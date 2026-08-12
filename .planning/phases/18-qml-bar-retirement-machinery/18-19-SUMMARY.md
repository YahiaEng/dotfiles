---
phase: 18-qml-bar-retirement-machinery
plan: 19
subsystem: ui
tags: [quickshell, qml, hyprland, gate, human-verification, waybar-retirement]

# Dependency graph
requires:
  - phase: 18-qml-bar-retirement-machinery
    provides: "18-02's GATE-02 Criterion B Index and Dead Definitions baseline; 18-17's structural gate; 18-18's soak proof; every build plan's own delivered surface"
provides:
  - "18-GATE-02-RECORD.md — GATE-02's closed blocking final pass: fifteen criterion rows judged live against athena and config-full/config-floating/config-vertical, RETIRE-02 AUTHORISED against sha 2644ae0"
affects: ["18-20 (RETIRE-02, waybar/config deletion)"]

# Actuals (#2632)
actuals:
  tokens: 17630
  tasks: 3
  commits: 8

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Human render-gate as an appended-iteration record: each sitting binds to a machine-captured build fingerprint, writes verdicts into shared master tables, and a suspended sitting's partial findings are preserved as their own numbered iteration rather than overwritten."
    - "Sha-bound deletion authorisation: the authorising line names the exact sha the fifteen gestures were performed against, and the consuming plan (18-20) re-asserts `git diff --quiet <sha> -- <path>` rather than trusting the record's prose alone."

key-files:
  created: []
  modified:
    - .planning/phases/18-qml-bar-retirement-machinery/18-GATE-02-RECORD.md

key-decisions:
  - "GATE-02 closed on Iteration 3, bound to sha 2644ae0563f2d330b8d615d355f523a44047da02 — 14 rows PASS, 1 (B.3, brightness half) NOT-DEMONSTRABLE per D-18-39, 0 FAIL, 0 OVERRIDDEN. RETIRE-02 AUTHORISED."
  - "Four measured-and-named residuals from the immediately-preceding vertical-orientation pass (clock pill ~6px, workspace numeral ~3px, percent-readout overhang ~3px, slider track ~10px — two reverted for QML binding loops) were judged accepted cosmetic debt, not gate blockers: the operator judged each criterion sentence met on a known, disclosed state rather than an unexamined one, and none was written as a Developer Override because no row failed."
  - "B.6-WS (scroll-to-switch-workspaces cut) judged PASS — the operator accepted the loss, since keybinds.lua's existing Super+wheel binding already covers the identical dispatch; the pre-specified WheelHandler remedy was not applied."
  - "B.6-WSCOUNT judged PASS — the live persistentSlotCount (6) already matches config-floating's own six, closing the 5-vs-6 delta the routing plans (18-09, 18-12) had named before Phase 18.1 moved the value."
  - "B.4-DRAWER judged PASS — 18-11's Option B (BarDrawer.qml, LazyLoader-gated) remained taken and unchanged from 8c5d280 through the authorising sha; this iteration's live gesture was the behaviour's first actual observation, superseding two prior iterations' unproven claim-by-construction."

requirements-completed: [GATE-02]

coverage:
  - id: D1
    description: "GATE-02's blocking human render-gate performed live against the shipped Quickshell bar: fifteen criterion rows (five aesthetic against athena, six capability against config-full/config-floating/config-vertical, three named sub-judgments, one lifted UI-SPEC row) each carrying a verdict from the closed four-token vocabulary and a concrete observation."
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/18-qml-bar-retirement-machinery/18-GATE-02-RECORD.md — Iteration 3, Block A/B/Named Sub-Judgments/Lifted rows"
        status: pass
    human_judgment: true
    rationale: "D-18-31's own precedent — this repo shipped visibly broken surfaces through fully green automated gates three times — is why this gate exists at all; a criterion is only 'passed' when confirmed live on the running bar, and 'looks right in the source' never counts. No automated check can substitute for the human sitting."
  - id: D2
    description: "The deletion authorisation for 18-20 (RETIRE-02): a sha-bound, machine-reverifiable close condition."
    verification:
      - kind: manual_procedural
        ref: "git diff --quiet 2644ae0563f2d330b8d615d355f523a44047da02 -- quickshell/.config/quickshell/ — exit 0, verified live at close"
        status: pass
    human_judgment: false

duration: multi-session (3 iterations across ~18h, 2026-08-12 04:11 to 22:45)
completed: 2026-08-12
status: complete
---

# Phase 18 Plan 19: GATE-02 Blocking Render Gate Summary

**GATE-02 closed on Iteration 3 (sha `2644ae0`): fourteen criteria PASS, B.3's brightness half NOT-DEMONSTRABLE per D-18-39, zero failures — RETIRE-02 AUTHORISED, four disclosed cosmetic residuals accepted as known-state debt rather than blockers.**

## Performance

- **Duration:** multi-session — three iterations spanning 2026-08-12 04:11 (Iteration 1 opened) to 22:45 (Iteration 3 closed), roughly 18.5 hours of elapsed wall-clock across the whole phase, with the human sitting itself performed in one continuous session at the end.
- **Tasks:** 3 (all complete)
- **Files modified:** 1 (`18-GATE-02-RECORD.md`, iteratively — same file across all three iterations, never a second artifact)

## Iteration history

**Iteration 1** (bound `8c5d280`) — suspended after the operator reported four defects before reaching eleven of the fifteen rows; zero rows verdicted.

| # | Finding | Owning file | Fixed in |
|---|---|---|---|
| F1 | Clock pill vertical alignment | `ClockActionsCapsule.qml` | `6285f5d` |
| F2 | Tooltips landing on the glyph | six sites incl. `AudioPopout.qml`, `SectionPopout.qml` | `6721977` |
| F3 | Idle-bulb click feedback | `IdleInhibitorCapsule.qml` | `6285f5d` |
| F4 | Media transport row not centred | `MediaPopout.qml` | `6721977` |

**Iteration 2** (bound `13de40f`) — suspended after the operator reported one defect (F5: popout cards sat ~52px low, a double-counted bar extent in `SectionPopout.qml`/`BarDrawer.qml`) before any row was verdicted.

| # | Finding | Owning files | Fixed in |
|---|---|---|---|
| F5 | Popout cards ~52px low, bar extent double-counted | `SectionPopout.qml`, `BarDrawer.qml` | `cefcf20`, `7aa2cfd`, `d1acef4`, `23c7d21` |

**Regression check on the re-close:** Iteration 3 re-observed all fifteen rows, not only the ones F5's fix touched — per the plan's own re-check contract, since the workspace capsule, entry list, popout frame and drawer host are all shared surfaces. A.2 (floating clear of every edge), B.5 (tray menu anchoring below/leftward) and B.4-DRAWER (drawer growth direction) — the three rows F5's fix most directly affected — were each re-observed and passed, with no regression found on any row.

**Iteration 3** (bound `2644ae0563f2d330b8d615d355f523a44047da02`) — the operator performed the full sitting: all fifteen rows observed live in fixed order, fourteen `PASS`, one `NOT-DEMONSTRABLE` (B.3), zero `FAIL`, zero `OVERRIDDEN`. This is the closing iteration.

## Authorising sha and the deletion interlock

`## Deletion Authorisation` reads `RETIRE-02 AUTHORISED — sha 2644ae0563f2d330b8d615d355f523a44047da02, Iteration 3, 2026-08-12`, plus the two conditions 18-20 re-asserts (the token, and `git diff --quiet <sha> -- quickshell/.config/quickshell/`).

**Verified live at close, not merely asserted:** `git diff --quiet 2644ae0563f2d330b8d615d355f523a44047da02 -- quickshell/.config/quickshell/` — **exit 0, no output**. HEAD had by that point advanced past the authorising sha by three docs-only commits (`caec5b9`, `22a3d6b`, `58db118`), none of which touches `quickshell/.config/quickshell/`; the authorisation binds to `2644ae0`, the sha the operator actually observed, and this record documents both the authorising sha and the write-time HEAD explicitly so 18-20's own re-assertion has a demonstrated, not merely claimed, precondition to check.

## B.4-DRAWER — the D-18-11 vertical drawer question

**Branch: Option B taken.** `test -f quickshell/.config/quickshell/modules/bar/BarDrawer.qml` → exists; registered in `qmldir`; `LazyLoader`-gated; mounted by both `LauncherCapsule.qml` and `ClockActionsCapsule.qml`. Unchanged from `8c5d280` through the authorising sha `2644ae0`, re-verified by the same four commands at each of the three iterations.

**Verdict: PASS**, and this was the row's first actual live observation — the `8c5d280` landing commit itself stated the leftward-growth behaviour was "claimed by construction and unproven by observation" because the authoring agent could not move the pointer on this host. Iteration 3's gesture (opening the launcher drawer, then the clock/settings drawer, in vertical orientation) confirmed both strips grow leftward over the desktop, satisfying D-18-11's own stated reason for choosing leftward over along-the-column. A known-state residual — the expanded strip's volume-slider track sits ~10px offset from its own handle, a fix attempted and reverted for a QML binding loop — was disclosed in the observation but did not change the verdict, since the criterion (growth direction) was met independent of that internal-control positioning issue.

## B.6-WS and B.6-WSCOUNT

- **B.6-WS: PASS.** Scrolling the workspace capsule without Super did nothing; holding Super and scrolling switched workspaces. The operator judged losing scroll-over-the-bar-without-Super not a loss, because `keybinds.lua` already binds the identical Super+wheel dispatch expressions globally — the pre-specified `WorkspaceCapsule.qml` `WheelHandler` remedy was therefore not applied.
- **B.6-WSCOUNT: PASS.** The live persistent slot count (6) matches `config-floating`'s own six, closing the 5-vs-6 delta 18-09/18-12 had originally routed here — Phase 18.1 had already moved the value past the delta before this sitting.

## Developer overrides

None written. No row failed, so no override was needed.

## What was harder to observe than the sheet assumed

Nothing structurally — all fifteen gestures were performable as specified. The genuine friction across the phase was temporal, not mechanical: two full sittings (Iterations 1 and 2) were opened and suspended on real defects found mid-pass rather than at the sheet-authoring stage, which is exactly the class of finding a live human gate exists to catch that a source read or an automated check would have missed. Both suspensions were handled per the plan's own re-check contract — full re-observation of all fifteen rows on the next iteration, never a partial resume of only the failed ones — and neither is itself a criticism of the sheet; it is the gate working as designed. The one place the record required active judgment rather than a binary pass/fail was the four vertical-pass residuals disclosed just before Iteration 3's sitting: the operator's actual practice was to weigh "is the criterion sentence met" against "is there a known, disclosed defect nearby" as two separate questions, answering PASS to the first while the residual's existence is preserved in the observation rather than silently absorbed. Future gate sheets inherit that pattern: a residual disclosed in the build fingerprint before the sitting is not automatically a FAIL, but it must appear in the row's own observation text, not just the fingerprint block, so the record stays self-contained.

## Files Created/Modified

- `.planning/phases/18-qml-bar-retirement-machinery/18-GATE-02-RECORD.md` — the gate sheet, built in task 1 (`8766918`) and iteratively completed across three iterations to close in this session.

## Decisions Made

See `key-decisions` in frontmatter. All decisions are the operator's live judgments recorded verbatim into the master tables — this plan judges, it does not decide on the developer's behalf.

## Deviations from Plan

**None requiring a Rule 1-4 classification.** Two adaptations were made to the plan's own literal `<verify><automated>` bash for task 3, both documented in-place as they were applied, because the plan's checks were written assuming a single-iteration close and this record legitimately accumulated three iterations of historical prose before closing:

1. **Authorisation-state check scoped to the `## Deletion Authorisation` section body**, rather than an unscoped file-wide `grep -c "RETIRE-02 BLOCKED"` — Iterations 1 and 2's own suspended-sitting narrative legitimately mentions "RETIRE-02 BLOCKED" in past-tense prose, which a file-wide count would double-count as ambiguity. This mirrors the same region-scoping task 1's own acceptance criteria already documented as necessary for the identical literal-token hazard.
2. **FAIL-verdict check restricted to the Verdict table column**, rather than a row-wide substring match — B.3's observation legitimately contains the phrase "not a `FAIL`" and B.4-DRAWER's gesture cell carries historical prose mentioning "The `FAIL`/observation this cell previously carried," neither of which is an actual FAIL verdict.

Both adaptations were verified against the literal intent stated in task 3's own acceptance-criteria prose (not against a looser reading), and the adapted checks were run to completion with a clean PASS before the authorisation line was written. No row's actual PASS/FAIL/NOT-DEMONSTRABLE/OVERRIDDEN state was affected by either adaptation.

## Issues Encountered

None beyond the two suspended sittings already documented under "Iteration history" above, both handled per the plan's own design (suspend, fix outside the record, re-open a fresh iteration, re-observe all fifteen rows).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

`18-20-PLAN.md` (RETIRE-02, the waybar/config deletion commit) is unblocked: its own precondition — greeping `## Deletion Authorisation` for `RETIRE-02 AUTHORISED` and re-running `git diff --quiet <sha> -- quickshell/.config/quickshell/`  — is satisfiable against this record as written. The four disclosed residuals (clock pill, workspace numeral, percent-readout overhang, slider track) are accepted cosmetic debt with one shared root cause (implicit-size inference in `PopoutTrigger`/`Readout`-family components); closing them is a follow-up architectural task, not a blocker for 18-20 or any later phase.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-12*
