---
phase: 20-indicators-power-menu
plan: 02
subsystem: infra
tags: [windows-ledger, debt-triage, gsd-tools]

requires:
  - phase: 19-notification-server-centre
    provides: WINDOWS.md open rows this triage reads and closes/re-defers
provides:
  - "20-LEDGER-05-TRIAGE.md: the individual-verdict rationale and batch-remainder rationale for every open WINDOWS.md row"
  - "WINDOWS.md with 6 rows individually verdicted (2 waived, 4 re-deferred onto named owners) and 45 rows in one owned batch re-defer block"
affects: [20-04, 20-05, 20-06, 20-07, 20-08, 21-media-fold-in]

actuals:
  tokens: 12112
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "WINDOWS.md ledger is JSON-block-authoritative: gsd-tools' broken-windows.cjs parses the trailing \\`\\`\\`\\`json fence, not the markdown table — a re-deferred row's reason must be hand-edited in BOTH the table and the JSON entry to survive the next `gsd-tools windows` write, or the table edit is silently discarded on the next tool-driven mutation."
    - "Markdown-table cells containing a literal `|` (even backslash-escaped, e.g. `\\|\\|` or `show\\|hideIdle`) break any naive `line.split('|')` column parse — this ledger already carried two such landmine rows (16, 45) from earlier phases; fixed by rewording to avoid the pipe character entirely rather than relying on escaping."

key-files:
  created:
    - .planning/phases/20-indicators-power-menu/20-LEDGER-05-TRIAGE.md
  modified:
    - .planning/WINDOWS.md

key-decisions:
  - "Individual-verdict set is exactly {3, 4, 5, 6, 10, 74} — confirmed by an independent re-scan against the live ledger, matching RESEARCH.md's floor with no additions found."
  - "Batch remainder's named owning phase is Phase 21 (Media Fold-In & Contract Close), which already carries LEDGER-06's cross-phase paperwork-debt mandate — not Phase 22, whose own notes explicitly disclaim carrying any debt."
  - "Rows 6 and 10 waived rather than re-deferred: row 6's subject (wleave.sh) is deleted outright in plan 20-10 with no successor failure mode to defer onto; row 10 records a confirmed-correct architectural fact (D-06, proven mechanically in 13-01), not a pending defect."

requirements-completed: [LEDGER-05]

coverage:
  - id: D1
    description: "20-LEDGER-05-TRIAGE.md records the live open_count (51, not the stale 16) with individual verdicts for rows 3/4/5/6/10/74 and one owned batch entry for the remaining 45 rows"
    requirement: LEDGER-05
    verification:
      - kind: automated_ui
        ref: "grep -q D-20-39 + per-row grep for ids 3,4,5,6,10,74 + batch heading grep, per plan's Task 1 <automated> verify"
        status: pass
    human_judgment: false
  - id: D2
    description: "WINDOWS.md's applied verdicts and reconciled frontmatter counters (open 51->49, waived 0->2, fixed unchanged at 24, total unchanged at 75) agree with the table's own rows"
    requirement: LEDGER-05
    verification:
      - kind: other
        ref: "python3 frontmatter-vs-table reconciliation script from plan's Task 2 <automated> verify, re-run after fixing two pre-existing pipe-escaping landmines (rows 16, 45)"
        status: pass
    human_judgment: false

duration: ~12min
completed: 2026-08-15
status: complete
---

# Phase 20 Plan 02: WINDOWS.md Ledger Triage Summary

**Triaged all 51 live-open WINDOWS.md rows at Phase 20 start: 6 individual verdicts (2 waived, 4 re-deferred onto this phase's own gates/plans) plus one Phase-21-owned batch entry for the remaining 45, closing LEDGER-05.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-08-15T19:04:51+03:00 (immediately after plan 20-01's commit)
- **Completed:** 2026-08-15T19:12:24+03:00
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Re-read `.planning/WINDOWS.md`'s live frontmatter (open_count 51, not the requirement's stale 16 — D-20-39) and confirmed it by independently counting the table's own `status` column.
- Wrote `20-LEDGER-05-TRIAGE.md`: individual verdicts for rows 3, 4, 5, 6, 10, 74 (each naming a plan-20-owned surface — wleave, wleave.sh, windowrules.lua, Toast.qml) with reasons and named owners, plus a single batch re-defer entry for the other 45 rows naming Phase 21 as owner.
- Applied the verdicts to `.planning/WINDOWS.md`: waived rows 6 and 10 via `gsd-tools windows waive`, hand-edited the `reason` column (both the markdown table cell and its underlying JSON-block entry — see Deviations) for the four re-deferred rows, and added a `## Batch re-defer (LEDGER-05, D-20-40)` block beneath the table.
- Reconciled the frontmatter counters (`open_count` 51→49, `waived_count` 0→2, `fixed_count`/`total_count` unchanged at 24/75) by re-deriving them from the table, not by hand-adjusting the prior numbers.

## Task Commits

Each task was committed atomically:

1. **Task 1: Enumerate the live ledger and write the individual verdicts** - `77ac4b4` (docs)
2. **Task 2: Apply the verdicts to WINDOWS.md and reconcile its frontmatter** - `622029c` (docs)

_No separate plan-metadata commit — this SUMMARY and STATE.md updates are committed as the final-commit step per the executor workflow._

## Files Created/Modified
- `.planning/phases/20-indicators-power-menu/20-LEDGER-05-TRIAGE.md` - the triage document: working figure, method, individual-verdict table, batch re-defer rationale, ledger-arithmetic reconciliation
- `.planning/WINDOWS.md` - 2 rows waived (6, 10), 4 rows re-deferred with new reasons (3, 4, 5, 74), one new batch block, reconciled frontmatter, plus two pre-existing pipe-escaping fixes (rows 16, 45)

## Decisions Made
- **Rows 6 and 10 waived, not re-deferred.** Row 6 (`wleave.sh`'s fault-injection gap) has no successor to defer onto — the wrapper script and the entire "external binary missing" failure class it guards against cease to exist once plan 20-10 deletes it, since an in-process QML surface has no missing-binary state. Row 10 (D-06's client-owned-exit-animation boundary correction) is a confirmed architectural fact proven mechanically in 13-01, not a pending defect — it stays correctly true for the two new namespaces this phase adds to `windowrules.lua`.
- **Rows 3, 4, 74 re-deferred onto plan 20-08's two Gates.** All three describe an unproven live-interaction gap (hover-during-entrance-cascade for 3/4; toast show/auto-hide/hover-pause for 74) that this phase's own render-gate plan (20-08) exercises for real on the replacement surfaces — Gate B for the entrance/hover pair, Gate A criteria 3-4 for the toast mechanism.
- **Row 5 re-deferred onto plan 20-06**, not marked `fixed`, even though the replacement pins an explicit icon size (`Design.sessionTileIconSize`) that would close it by construction — because plan 20-06 has not executed yet as of this wave-1 plan, and this plan's own prohibition forbids marking a row `fixed` on the strength of a plan that hasn't run.
- **Batch remainder's owning phase is Phase 21**, not Phase 22 — Phase 21 already carries LEDGER-06 (Phase 16 paperwork/VERIFICATION.md debt), making it the established precedent for "ledger triage lands in a migration phase, not the closing gate." Phase 22's own ROADMAP notes explicitly state it carries "no debt at all," which would make it a poor (arguably contradictory) home for a 45-row batch.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] WINDOWS.md's JSON block, not the markdown table, is the actual data source `gsd-tools windows` parses and re-renders from**
- **Found during:** Task 2, after applying the four re-deferred rows' reasons only to the markdown table cells
- **Issue:** `broken-windows.cjs`'s `parseLedger` reads the frontmatter + the trailing ` ```` json ` fence block, never the markdown table — the table is a pure rendered view, regenerated from the JSON block on every write (`renderLedger`). A markdown-only edit to a row's `reason` cell would be silently discarded the next time any `gsd-tools windows` command (e.g. a future `waive`/`fixed`/`append`) rewrites the file, since the tool would regenerate the table from the still-empty JSON `reason` field.
- **Fix:** Hand-edited the corresponding JSON entries (ids 3, 4, 5, 74) to carry the identical `reason` text as the markdown cells, keeping `status: "open"` in both places, and confirmed the JSON block still parses (`python3 -c "json.loads(...)"`, 75 entries, no duplicate ids) and that `gsd-tools windows status` reads the file back with matching counts.
- **Files modified:** `.planning/WINDOWS.md`
- **Verification:** JSON block re-parsed cleanly; `gsd-tools windows status --raw` reported `open_count: 49, waived_count: 2` matching the table-derived counts.
- **Committed in:** `622029c` (Task 2 commit)

**2. [Rule 1 - Bug] Two pre-existing WINDOWS.md rows contained literal `|` characters that break table-column parsing**
- **Found during:** Task 2's frontmatter-reconciliation verify, which failed twice with a mismatched `open_count` before the cause was isolated
- **Issue:** Row 16's description used a backslash-escaped `\|\| true` (bash's logical-or-true idiom) and row 45's used `show\|hideIdle\|hideHard\|status` (an escaped-pipe regex alternation) — both predate this plan (rows 16 and 45 recorded 2026-07-28 and 2026-08-11 respectively, phases 13.1 and 18). A naive `line.split('|')` column parse (the exact approach the plan's own Task 2 `<automated>` verify script uses) splits on every literal `|`, escaped or not, silently shifting that row's `status`/`reason` columns and producing a false frontmatter mismatch that had nothing to do with this plan's edits.
- **Fix:** Reworded both cells to convey the same information without a literal `|` character (`\|\| true` → "guarded by a bash logical-or-true idiom"; `show\|hideIdle\|hideHard\|status` → "show / hideIdle / hideHard / status"), applied to both the markdown table cell and the matching JSON entry's `description` field for each row.
- **Files modified:** `.planning/WINDOWS.md`
- **Verification:** Re-ran the plan's exact Task 2 verify script; it now reports `rows 75 open 49` with the frontmatter matching, and a full-file scan confirms no remaining row status value falls outside `{open, fixed, waived}`.
- **Committed in:** `622029c` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking-issue, 1 bug)
**Impact on plan:** Both were necessary for Task 2's own acceptance criteria (frontmatter counters must equal table-derived counts) to be verifiably true rather than accidentally true. No scope creep — no row's `status` or substantive meaning was altered, only wording that collided with the ledger's own markdown-table format.

## Issues Encountered
None beyond the two deviations above, both resolved inline.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Plans 20-04 through 20-08 can now read `20-LEDGER-05-TRIAGE.md` to know which WINDOWS.md rows their own acceptance criteria are expected to close (row 5 on 20-06; rows 3/4/74 on 20-08's Gates A/B).
- Phase 21 planning should read the batch re-defer block in `.planning/WINDOWS.md` (45 ids) as an inherited triage obligation alongside its existing LEDGER-06 scope.
- No blockers for the remaining wave-1 plan (20-03) or wave-2 work.

## Self-Check: PASSED

- FOUND: `.planning/phases/20-indicators-power-menu/20-LEDGER-05-TRIAGE.md`
- FOUND: `.planning/WINDOWS.md`
- FOUND: `.planning/phases/20-indicators-power-menu/20-02-SUMMARY.md`
- FOUND commit: `77ac4b4` (Task 1)
- FOUND commit: `622029c` (Task 2)
- FOUND commit: `acf8d89` (SUMMARY)

---
*Phase: 20-indicators-power-menu*
*Completed: 2026-08-15*
