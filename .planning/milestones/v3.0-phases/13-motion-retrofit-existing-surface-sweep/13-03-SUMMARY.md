---
phase: 13-motion-retrofit-existing-surface-sweep
plan: 03
subsystem: infra
tags: [fish, zsh, fisher, nvm, uv, wleave, hyprshutdown, fault-injection]

# Dependency graph
requires:
  - phase: 04-reliability-fixes-tech-debt
    provides: "04-REVIEW.md WR-01..WR-04 advisory findings (fisher bootstrap, nvm guard, uv env guard, logout teardown hazard)"
provides:
  - "WR-01/02/03 fixed and fault-injection proven (fisher bootstrap fail-fast, nvm activation guard, uv env source guard)"
  - "WR-04 explicitly left OPEN/UNRESOLVED under an operator waiver — no measurement taken, no code change made"
affects: [maint-02-followup, wleave, logout-teardown]

tech-stack:
  added: []
  patterns: ["fish $pipestatus[1] gating instead of ambient $status after a pipe"]

key-files:
  created: []
  modified:
    - "fish/.config/fish/config.fish (committed in baae579, Task 1 — no further change this session)"
    - "zshell/.zshrc (committed in baae579, Task 1 — no further change this session)"
    - ".planning/PROJECT.md (Key Decisions row added, recording the WR-04 waiver)"

key-decisions:
  - "WR-04's blocking teardown-hazard measurement (D-29) was NOT PERFORMED. It was waived by explicit operator decision on 2026-07-28 to close Phase 13, not skipped by the executor's own choice."
  - "Logout's action string in wleave/.config/wleave/layout.json is left BYTE-UNCHANGED. This is a conservative no-change default taken under the waiver — it is NOT Branch B from the plan, because Branch B requires an evidence-backed falsification of the hazard, and no evidence exists."
  - "WR-04 is recorded as OPEN/UNRESOLVED in PROJECT.md's Key Decisions table, not as closed, not as deliberately-exempt-by-finding. The hazard is neither confirmed nor falsified."
  - "MAINT-02 is NOT marked complete in REQUIREMENTS.md. WR-01/02/03 are closed; WR-04 is not. REQUIREMENTS.md's MAINT-02 checkbox stays unchecked pending a future plan that actually runs the D-29 measurement."

requirements-completed: []  # Deliberately empty — MAINT-02 as a whole is NOT complete; see Deviations. WR-01/02/03 are done but the requirement is defined as covering all four WR items.

coverage:
  - id: D1
    description: "WR-01 fisher bootstrap curl fails loudly on non-200 (adds -f); secondary fish $pipestatus[1] defect found live and fixed"
    requirement: "MAINT-02"
    verification:
      - kind: manual_procedural
        ref: "Fault injection: bad URL BEFORE fix showed HTML parse errors and a secondary 'Unknown command: fisher' error; AFTER fix (curl -f + $pipestatus[1] gate) was silent; real URL still installs fisher + plugins end-to-end. Recorded in commit baae579 and 13-03-CONTINUE-HERE.md (now folded into this SUMMARY)."
        status: pass
    human_judgment: false
  - id: D2
    description: "WR-02 nvm activation guarded on version directory existing under nvm_data"
    requirement: "MAINT-02"
    verification:
      - kind: manual_procedural
        ref: "Fault injection: version dir moved aside BEFORE fix showed 'Can't use Node' line; AFTER fix, clean start. Restored. Recorded in commit baae579."
        status: pass
    human_judgment: false
  - id: D3
    description: "WR-03 uv env source in .zshrc existence-guarded and de-obfuscated to the real .local/bin path"
    requirement: "MAINT-02"
    verification:
      - kind: manual_procedural
        ref: "Fault injection: env file absent BEFORE fix showed missing-file error + non-zero exit; AFTER fix, clean exit 0. Recorded in commit baae579."
        status: pass
    human_judgment: false
  - id: D4
    description: "WR-04 logout teardown-hazard measurement (D-29) — NOT PERFORMED, waived by operator; layout.json left byte-unchanged, PROJECT.md records the waiver as open debt"
    requirement: "MAINT-02"
    verification: []
    human_judgment: true
    rationale: "No measurement was taken and none can be synthesized. This deliverable is explicitly NOT proven — it is an open item recorded for a future plan to actually run. A human (the operator) is the only party who can confirm this waiver is what they intended and that WR-04 remaining open is acceptable to ship Phase 13 without."

duration: N/A (closeout of a previously-paused plan; Task 1's own duration was recorded at the time of commit baae579)
completed: 2026-07-28
status: complete
---

# Phase 13 Plan 03: Fresh-Install Shell Startup Fixes + Logout Teardown Waiver Summary

**Three shell-startup advisory items (WR-01/02/03) fixed and fault-injection proven; the fourth (WR-04, logout teardown hazard) is explicitly left UNMEASURED and OPEN under an operator waiver — no code change, no finding, just a recorded waiver.**

## Performance

- **Tasks:** 3 of 3 defined in `13-03-PLAN.md`, but only Task 1 was actually executed with real work. Task 2 (blocking human-verify checkpoint) was **NOT PERFORMED**. Task 3 (branch selection) is resolved to the conservative no-change default under the waiver, not by measurement.
- **Files modified this session:** 1 (`.planning/PROJECT.md`) plus deletion of `13-03-CONTINUE-HERE.md`. `fish/.config/fish/config.fish` and `zshell/.zshrc` were already correctly fixed and committed in `baae579` prior to this session — not re-touched.

## Accomplishments

- WR-01, WR-02, WR-03 fixed and each individually proven by a fault injection that reproduced the defect before the fix and did not after (D-30). Committed as `baae579`.
- A second, previously-unknown defect was found live during WR-01's own fault-injection proof and fixed in the same commit (see below) — this is the most important technical finding of this plan and must not be lost.
- WR-04's blocking measurement gate was explicitly waived by the operator to close Phase 13. This is recorded honestly as **NOT PERFORMED**, not as a finding, not as "deemed acceptable" — those words are deliberately avoided here per the operator's own integrity requirement for this closeout.

## Task Commits

1. **Task 1: WR-01/02/03 — fix each, and prove each individually by fault injection** — `baae579` (fix)
2. **Task 2: D-29 measurement (`checkpoint:human-verify`, `gate="blocking"`)** — **NOT PERFORMED.** No commit. The operator explicitly declined to run the session-ending TTY test (`uwsm stop` measured from outside the session) and waived the gate to close Phase 13 instead of deferring the whole plan further.
3. **Task 3: WR-04 resolution** — resolved to the no-change default (see Deviations below), not to either of the plan's two evidence-based branches. Committed as part of this SUMMARY's metadata commit (`.planning/PROJECT.md` Key Decisions row).

**Plan metadata:** (this SUMMARY's own commit, recorded after write)

## Files Created/Modified

- `fish/.config/fish/config.fish` — WR-01 (`-f` on the fisher bootstrap curl, `$pipestatus[1]` gate) and WR-02 (nvm activation guard). Committed in `baae579`, prior session — not touched this session.
- `zshell/.zshrc` — WR-03 (existence-guarded, de-obfuscated uv env source). Committed in `baae579`, prior session — not touched this session.
- `.planning/PROJECT.md` — new Key Decisions row recording the WR-04 waiver (this session).
- `wleave/.config/wleave/layout.json` — **NOT modified.** Byte-unchanged. This is a deliberate no-change default under the waiver, not Branch B of the plan (Branch B requires a measurement that falsifies the hazard; none was taken).
- `.planning/phases/13-motion-retrofit-existing-surface-sweep/13-03-CONTINUE-HERE.md` — **deleted.** Its content (Task 1's findings, the pause-state record) is folded into this SUMMARY per its own step 6 instructions.

## Decisions Made

- **WR-04's hazard measurement was waived, not performed.** The operator made this decision explicitly on 2026-07-28 to close Phase 13, fully aware that Task 2 is a blocking gate designed to settle the question by evidence. This is a scheduling/scope decision by the human who owns the tradeoff, not an executor shortcut.
- **The no-change path was taken for `layout.json`, and it is explicitly NOT Branch B.** The plan's Branch B is "hazard falsified on this build" — an evidence-backed finding requiring the three measured numbers from Task 2. Since Task 2 never ran, there are no numbers to cite, and Branch B's conditions are unmet. What was actually done is a conservative default: leave the file alone because there is nothing to act on, and record that plainly.
- **PROJECT.md's Key Decisions table gained one row** documenting all of the following in one place: the measurement was not performed; logout remains on the bare path by default rather than by finding; the hazard is unresolved (neither confirmed nor falsified); the waiver was an explicit operator decision on 2026-07-28; the reproduction steps remain verbatim in `13-03-PLAN.md` Task 2 for whoever picks this up next.
- **MAINT-02 is not marked complete.** REQUIREMENTS.md defines MAINT-02 as covering all four WR items. Three of four (WR-01/02/03) are closed and fault-injection proven; WR-04 is not. The requirement stays unchecked/Pending until a future plan actually runs the D-29 measurement and Task 3's real branch selection.

## Deviations from Plan

**This is not a normal deviation set — the plan's checkpoint gate itself was waived by explicit operator instruction, not auto-resolved by any of the standard Rule 1-4 deviation logic.** Documenting it here for completeness, but it is categorically different from an auto-fix:

**1. [Operator waiver, not a deviation rule] Task 2's blocking measurement gate was never run**
- **Found during:** Resuming this plan from its paused state (see the now-deleted `13-03-CONTINUE-HERE.md`)
- **Issue:** Task 2 requires physically switching to a TTY, running `uwsm stop` with a stopwatch, and observing whether a deliberately-unkillable client survives — an irreducibly human, session-ending action that cannot be automated or inferred
- **Resolution:** The operator explicitly waived this gate to close Phase 13, accepting that WR-04 remains open debt. No code change was made under this waiver — `layout.json` is untouched. The waiver and its consequences are recorded plainly in `.planning/PROJECT.md`'s Key Decisions table and in this SUMMARY
- **Files affected:** none touched as a result of the waiver itself (the `.planning/PROJECT.md` edit records the waiver, it does not implement a fix)
- **Verification:** N/A — there is nothing to verify because nothing was measured. This is the point: the record must not claim otherwise.

---

**Total deviations:** 1 (operator waiver of a blocking human-verify gate, not an auto-fix)
**Impact on plan:** WR-01/02/03 are genuinely done and proven. WR-04 is genuinely NOT done — it is open debt carried forward, explicitly and traceably, not silently dropped.

## Issues Encountered

**A previously-unknown secondary defect was found live during WR-01's own fault-injection proof, and must not be lost from the record (carried forward from the now-deleted `13-03-CONTINUE-HERE.md`):**

Fish's pipeline `$status` reflects the exit code of the **last** command in a pipe (`source`), not the first (`curl`). So `curl -f <url> | source` on a failed fetch sources empty input, which trivially succeeds — meaning a plain `and fisher update` immediately after the pipeline **still fired even though curl itself had failed**, producing a secondary `Unknown command: fisher` error. This was fixed by gating on `$pipestatus[1]` (curl's own exit code) instead of the pipeline's ambient `$status`. Both halves were fault-injection proven: BEFORE (bad URL + the naive fix) showed the secondary "Unknown command: fisher" error; AFTER (bad URL + the `$pipestatus[1]` gate) was silent; the real URL end-to-end still installs fisher and its plugins correctly. This finding and its fix are both in commit `baae579`.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. No stub code was written. WR-04 is not a stub — it is an explicitly-recorded open measurement gap with no code path pretending it is resolved.

## Next Phase Readiness

- **WR-01/02/03 (MAINT-02 partial): closed.** Fresh-install shell startup is fixed and fault-injection proven.
- **WR-04 (MAINT-02 remainder): NOT closed.** The teardown-hazard measurement described in `13-03-PLAN.md` Task 2 has never been run. Whoever picks this up next should re-read that Task 2 verbatim (reproduced once already in the now-deleted `13-03-CONTINUE-HERE.md`, and preserved in `13-03-PLAN.md` itself) and actually perform the TTY measurement before touching `layout.json`.
- **MAINT-02 is NOT satisfied as a whole.** Do not treat this plan's close as MAINT-02's close. REQUIREMENTS.md correctly keeps MAINT-02 unchecked.
- This plan's close does **not** by itself close Phase 13 — 13-07 remains open and is owned by a separate agent/session.

---
*Phase: 13-motion-retrofit-existing-surface-sweep*
*Completed: 2026-07-28*

## Self-Check: PASSED

- FOUND: commit `baae579` (`git log --oneline --all | grep baae579`)
- FOUND: `fish/.config/fish/config.fish`
- FOUND: `zshell/.zshrc`
- FOUND: `13-03-SUMMARY.md` (this file)
- CONFIRMED DELETED: `13-03-CONTINUE-HERE.md`
- Gate re-check at closeout time: `theme-doctor` exit 0 (206 passed, 0 failed), `theme-parity` exit 0 (2697 passed, 0 failed), `motion-lint` exit 0 (53 passed, 0 checks failed) — no regression from this closeout
