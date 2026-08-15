---
phase: 20-indicators-power-menu
plan: 08
subsystem: ui
tags: [quickshell, qml, hyprland, gate-02, render-gate, deletion-authorisation, retirement]

requires:
  - phase: 20-05
    provides: "The transient-toast OSD frame (Toast.qml/Osd.qml) Gate A judges against swayosd's recorded behaviour"
  - phase: 20-07
    provides: "The completed radial-ring power menu (warning chip, cascade entrance, OSD suppression, popup dismissal) Gate B judges against wleave's recorded behaviour, at the sha (8b6a111) both gates were prepared and judged against"
provides:
  - "20-GATE-02-A-RECORD.md: Gate A (OSD) live-judged, all seven criteria PASS or NOT-DEMONSTRABLE-with-reason, RETIRE-04 AUTHORISED at sha 8b6a111"
  - "20-GATE-02-B-RECORD.md: Gate B (power menu) live-judged, all thirteen criteria PASS or OVERRIDDEN, RETIRE-05 AUTHORISED at sha 8b6a111"
  - "The phase's one-way door decision taken: authorise-both — RETIRE-04 and RETIRE-05 both unlocked, RETIRE-07 riding whichever of plan 20-09/20-10 lands second"
  - "WINDOWS.md rows 76 and 77 closed by this live sitting; row 78 (brightness OSD, unverifiable on this desktop host) deliberately left open as an accepted, named risk"
affects: [20-09, 20-10]

actuals:
  tokens: 8655
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Continuation-agent gate closure: the live sitting happens out-of-band between task commits (operator runs both gates in their own time), and the continuation agent transcribes verdicts verbatim into the pre-prepared criteria table rather than re-deriving them — the same shape as this phase's own earlier continuation plans"

key-files:
  created: []
  modified:
    - .planning/phases/20-indicators-power-menu/20-GATE-02-A-RECORD.md
    - .planning/phases/20-indicators-power-menu/20-GATE-02-B-RECORD.md
    - .planning/WINDOWS.md

key-decisions:
  - "checkpoint:decision resolved authorise-both: Gate A and Gate B both passed live, so RETIRE-04 (swayosd + swayosd-libinput-backend.service) and RETIRE-05 (wleave) are both authorised at judged sha 8b6a111a5f896a4bb449ac5a2cb91bcf6680d205. RETIRE-07 (wlogout + eww) rides whichever of plan 20-09/20-10 executes second, per D-20-42/D-20-40."
  - "Gate A criterion 3's brightness half recorded NOT-DEMONSTRABLE (D-18-39 precedent, zero backlight-class devices on this host) and explicitly does NOT block RETIRE-04 authorisation — the operator approved proceeding despite it. Its verification debt stays open: `.planning/todos/pending/2026-08-15-brightness-osd-unverifiable-on-desktop.md` and WINDOWS row 78 are NOT closed by this gate, since the underlying laptop deliverable remains unproven."
  - "Gate A criterion 6 (Caps Lock) recorded PASS with an explicit note beyond the bare verdict: a real physical key press confirmed the 250ms sysfs-poll fallback (built after GATE-01 measured the specified event-driven watch dead) fires correctly on this host — closing WINDOWS row 77 and resolving 20-RESEARCH.md's Open Question 1."
  - "Gate B criterion 13 (Phase 15 'who owns the prompt' security carry-over) recorded OVERRIDDEN, not PASS/FAIL — the layer-shell overlay does occlude another app's confirm dialog by construction (no code fix exists for the general case), and the operator accepted the surface as shipped on the strength of its three residual mitigations (transient surface, Escape-always-works, HyprlandFocusGrab dismissal on focus loss), all confirmed to hold."
  - "No package deleted in this plan. Both gate records' Deletion Authorisation sections read AUTHORISED with the judged sha and the git diff --quiet <sha> -- quickshell/.config/quickshell/ interlock re-verified clean at HEAD; plans 20-09 and 20-10 each own their own deletion, gated behind their own re-assertion of that interlock and their own further checkpoint."

requirements-completed: [QOSD-01, QOSD-02, QOSD-03, QOSD-04, QPOWER-01, QPOWER-02, QPOWER-03, QPOWER-04, RETIRE-04, RETIRE-05, RETIRE-07]

coverage:
  - id: D1
    description: "Gate A (OSD) run and recorded live: all seven criteria carry PASS or NOT-DEMONSTRABLE-with-reason; RETIRE-04 authorised at judged sha 8b6a111"
    requirement: "RETIRE-04"
    verification:
      - kind: manual_procedural
        ref: "20-GATE-02-A-RECORD.md § Gate A Criteria and § Deletion Authorisation — operator-run live sitting, 2026-08-16, verdicts transcribed verbatim into this plan's continuation"
        status: pass
    human_judgment: true
    rationale: "A render-gate verdict is by definition a human judgment against the running shell (this plan's own must_haves prohibit recording a criterion as passing on source inspection alone) — the operator performed the live sitting and reported the verdicts this continuation transcribed."
  - id: D2
    description: "Gate B (power menu) run and recorded live: all thirteen criteria carry PASS or OVERRIDDEN (criterion 13's accepted security residual); RETIRE-05 authorised at judged sha 8b6a111"
    requirement: "RETIRE-05"
    verification:
      - kind: manual_procedural
        ref: "20-GATE-02-B-RECORD.md § Gate B Criteria and § Deletion Authorisation — operator-run live sitting, 2026-08-16, verdicts transcribed verbatim into this plan's continuation"
        status: pass
    human_judgment: true
    rationale: "Same as D1 — a render-gate verdict requires a human judging the running shell; the operator's sitting covered both non-destructive routes and the destructive Shutdown/Reboot criterion, run last per the record's own setup instructions."
  - id: D3
    description: "The phase's one-way-door checkpoint:decision resolved: authorise-both, with no package deleted by this plan and the interlock (git diff --quiet 8b6a111 -- quickshell/.config/quickshell/) re-verified clean at HEAD before recording either authorisation"
    requirement: "RETIRE-07"
    verification:
      - kind: other
        ref: "git diff --quiet 8b6a111 -- quickshell/.config/quickshell/ (exit 0, confirmed clean at commit 9d04feb); colour-lint 142/142, motion-lint 283/283, quickshell-doctor --self-test 55/55, all exit 0"
        status: pass
    human_judgment: false

duration: multi-session (Tasks 1-2 same session; live sitting between operator sessions; Task 3 continuation ~10min)
completed: 2026-08-16
status: complete
---

# Phase 20 Plan 08: GATE-02 Render Gates and Deletion Authorisation Summary

**Both independent GATE-02 render gates passed live — RETIRE-04 (swayosd) and RETIRE-05 (wleave) both authorised at sha 8b6a111, with brightness OSD accepted as an open risk and the Phase 15 prompt-occlusion carry-over recorded OVERRIDDEN.**

## Performance

- **Duration:** multi-session — Tasks 1-2 prepared both gate records in one session; the operator then ran the live sittings independently; this continuation agent (Task 3) recorded verdicts and closed the plan in roughly 10 minutes
- **Started:** 2026-08-16T00:18:46+03:00 (Task 1 commit)
- **Completed:** 2026-08-16T00:26:09+03:00 (final metadata commit pending)
- **Tasks:** 3/3
- **Files modified:** 3 (`20-GATE-02-A-RECORD.md`, `20-GATE-02-B-RECORD.md`, `WINDOWS.md`)

## Accomplishments
- Gate A (OSD): all seven criteria judged live and recorded PASS or NOT-DEMONSTRABLE-with-reason; RETIRE-04 authorised
- Gate B (power menu): all thirteen criteria judged live and recorded PASS or OVERRIDDEN; RETIRE-05 authorised
- The phase's one-way-door `checkpoint:decision` resolved `authorise-both` — no package deleted, both deletions unlocked for plans 20-09/20-10
- WINDOWS.md rows 76 (ring's own live human-check) and 77 (Caps Lock poll fallback) closed; row 78 (brightness OSD) deliberately left open

## Task Commits

Each task was committed atomically:

1. **Task 1: Run and record GATE-02 Gate A — the OSD (unlocks RETIRE-04)** — `a5d19f2` (docs) — prepared criteria table, pre-checks, awaiting live sitting
2. **Task 2: Run and record GATE-02 Gate B — the power menu (unlocks RETIRE-05)** — `4aa2f20` (docs) — prepared criteria table, pre-checks, awaiting live sitting
3. **Task 3: checkpoint:decision — authorise-both** — `60306c0` (docs, verdicts recorded and both records' Deletion Authorisation sections rewritten `AUTHORISED`) + `9d04feb` (docs, WINDOWS rows 76/77 closed)

_Tasks 1 and 2 were prepared by a prior executor session; this continuation agent recorded the operator's live-sitting verdicts and completed Task 3._

## Files Created/Modified
- `.planning/phases/20-indicators-power-menu/20-GATE-02-A-RECORD.md` — all seven Gate A criteria filled with live verdicts; Deletion Authorisation rewritten `RETIRE-04 AUTHORISED`
- `.planning/phases/20-indicators-power-menu/20-GATE-02-B-RECORD.md` — all thirteen Gate B criteria filled with live verdicts; Deletion Authorisation rewritten `RETIRE-05 AUTHORISED`
- `.planning/WINDOWS.md` — rows 76 and 77 marked `fixed`; row 78 left `open`

## Decisions Made
- **authorise-both** selected for the phase's one-way-door checkpoint: both gates passed, so both deletions are unlocked. RETIRE-07 (`wlogout` + `eww`) rides whichever of plan 20-09/20-10 lands second, per D-20-42/D-20-40.
- Gate A criterion 3's brightness half stays NOT-DEMONSTRABLE and does not block RETIRE-04 — recorded as an accepted, named risk, not a pass. The todo and WINDOWS row 78 remain open.
- Gate A criterion 6 (Caps Lock) recorded as live-confirmed via a real physical key press, closing WINDOWS row 77 and resolving 20-RESEARCH.md's Open Question 1 about whether the poll-based fallback actually fires.
- Gate B criterion 13 (Phase 15 "who owns the prompt") recorded OVERRIDDEN — the known, accepted residual, not a fix-required failure; all three residual mitigations confirmed to hold.
- No package deletion performed in this plan. The interlock `git diff --quiet 8b6a111 -- quickshell/.config/quickshell/` was re-verified clean at HEAD before either authorisation was recorded, and plans 20-09/20-10 must each re-assert it themselves before deleting.

## Deviations from Plan

None — plan executed exactly as written. The continuation agent's job (record operator verdicts, take the decision, complete Task 3) matched the plan's own `checkpoint:decision` structure precisely; no auto-fixes, no architectural changes, no scope additions.

## Issues Encountered

None. Automated pre-checks (`colour-lint` 142/142, `motion-lint` 283/283, `quickshell-doctor --self-test` 55/55, and the `git diff --quiet 8b6a111 -- quickshell/.config/quickshell/` interlock) were all re-run and confirmed clean before recording either authorisation, per the mandatory_verification instruction. No QML changed since the gates were prepared. No shell restart, no key presses performed by this agent — both verdicts came from the operator's own live sitting, reported after the fact.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 20-09 may proceed: `RETIRE-04 AUTHORISED` recorded at sha `8b6a111a5f896a4bb449ac5a2cb91bcf6680d205`, interlock confirmed clean. It must re-assert `git diff --quiet 8b6a111 -- quickshell/.config/quickshell/` itself before deleting `swayosd` + `swayosd-libinput-backend.service`.
- Plan 20-10 may proceed: `RETIRE-05 AUTHORISED` recorded at the same sha, same interlock requirement, before deleting `wleave`. Whichever of 20-09/20-10 runs second also carries RETIRE-07 (`wlogout` + `eww`).
- Open, deliberately-unclosed debt carried forward: WINDOWS row 78 (brightness OSD unverifiable on this desktop host — real laptop hardware needed) and `.planning/todos/pending/2026-08-15-brightness-osd-unverifiable-on-desktop.md`. Neither blocks RETIRE-04's authorisation; both remain open for future verification.

---
*Phase: 20-indicators-power-menu*
*Completed: 2026-08-16*

## Self-Check: PASSED

- FOUND: `.planning/phases/20-indicators-power-menu/20-08-SUMMARY.md`
- FOUND: `a5d19f2` (Task 1 commit)
- FOUND: `4aa2f20` (Task 2 commit)
- FOUND: `60306c0` (Task 3 verdicts + authorisation commit)
- FOUND: `9d04feb` (WINDOWS rows 76/77 closure commit)
