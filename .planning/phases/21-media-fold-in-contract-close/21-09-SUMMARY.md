---
phase: 21-media-fold-in-contract-close
plan: 09
subsystem: theming
tags: [theme-engine, quickshell-doctor, retirement-check, media-art-resolve, hardening-tests, bash]

requires:
  - phase: 21-media-fold-in-contract-close
    provides: "21-08's deletion commit (theme contract 18->17), the pre-deletion sweep, and 21-GATE-02-RECORD.md's explicit naming of the two quickshell-doctor failures and the run-to-run instability as this plan's own business"
provides:
  - "Check 12 (T-21-26) in test-media-hardening.sh — the album-art bare-path handoff contract, covered for the first time, proven able to fail before being wired against the real resolver"
  - "quickshell-doctor bar-reserved-zone-stability and permissions-allowlist-paths-resolve — both root-caused as checker bugs (not real desktop defects) and fixed; 5 consecutive live runs now identical (rc=0, 20 passed, 0 failed)"
  - "21-CONTRACT-CLOSE-EVIDENCE.md — every affected gate run after the deletion, raw output committed, before/after retirement-check sweep pair cross-referenced"
  - "RETIRE-08 closed: theme contract confirmed at 17 file entries with the removed entry's format family still represented"
affects: [22-fresh-install-proof]

actuals:
  tokens: 11327
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "quickshell-doctor's `_qsd_reservation_equal` helper — every 'did the bar's reservation change' comparison in a check now goes through the same name-keyed reserved-only diff, never a raw whole-blob `hyprctl monitors -j` string equality (which is sensitive to unrelated live fields like focused workspace)"
    - "Lua binary-grant extraction is line-aware: skip any line whose trimmed text starts with `--` before regex-matching a field out of it, matching `_qsd_windowrules_candidates`'s existing precedent in the same file — a bare `grep -oP` over a whole file matches inside comments exactly as readily as inside live code"

key-files:
  created:
    - .planning/phases/21-media-fold-in-contract-close/21-CONTRACT-CLOSE-EVIDENCE.md
  modified:
    - hypr/.config/hypr/scripts/tests/test-media-hardening.sh
    - hypr/.config/hypr/scripts/quickshell-doctor

key-decisions:
  - "theme-stress-test was NOT run, despite the plan's own Task 2 <verify> block asking for it — this executor's standing session rules unconditionally prohibit live-theme-mutating commands (a prior session accidentally re-themed the operator's live desktop running this exact command, 21-08-SUMMARY.md Deviations #2). Verified statically instead (REPRESENTATIVE_FILES does not name the removed ags.scss entry) and recorded as an explicit operator action rather than silently marked green."
  - "Investigated the run-to-run quickshell-doctor instability named in 21-GATE-02-RECORD.md rather than treating it as unavoidable live-state flakiness. Both open failures (bar-reserved-zone-stability, permissions-allowlist-paths-resolve) turned out to be checker bugs, root-caused by reading the check's own source and measuring, then fixed with real code changes — not narrowed, not skipped, not waved through."
  - "theme-doctor's 3 pre-existing failures (hypr-equivalence-check binds.json baseline, waybar/keybinds, waybar/cross-package-refs) and retirement-check --all's one failing surface (waybar) were left unfixed, honestly disclosed as out of this plan's scope (Phase 18/21-07 debt), per the deviation rules' scope boundary and 21-08-SUMMARY.md's own prior flagging of these exact items."

requirements-completed: [RETIRE-08, QMEDIA-03, RETIRE-06]

coverage:
  - id: D1
    description: "Album-art handoff (resolver stdout must be a bare local path, never a scheme-carrying value) covered by a new adversarial-suite check on both a remote-URL and a local file:// input, proven able to report red before being wired against the real resolver"
    requirement: "QMEDIA-03"
    verification:
      - kind: unit
        ref: "hypr/.config/hypr/scripts/tests/test-media-hardening.sh (Check 12, T-21-26) — 24/24 passed"
        status: pass
    human_judgment: false
  - id: D2
    description: "quickshell-doctor's bar-reserved-zone-stability and permissions-allowlist-paths-resolve false failures root-caused and fixed; live run stability proven across 5 consecutive invocations"
    requirement: "RETIRE-08"
    verification:
      - kind: unit
        ref: "hypr/.config/hypr/scripts/quickshell-doctor --self-test — 59/59 passed"
        status: pass
      - kind: other
        ref: "5 consecutive live invocations of quickshell-doctor --no-summon --no-headless-output --no-panel-checks — all rc=0, 20 passed, 0 failed, identical"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every gate this phase's changes could affect run after the deletion with raw output committed to 21-CONTRACT-CLOSE-EVIDENCE.md; theme contract confirmed at 17 entries; before/after retirement-check ags sweep pair cross-referenced and re-confirmed fresh"
    requirement: "RETIRE-08"
    verification:
      - kind: other
        ref: ".planning/phases/21-media-fold-in-contract-close/21-CONTRACT-CLOSE-EVIDENCE.md"
        status: pass
    human_judgment: false
  - id: D4
    description: "theme-stress-test NOT run per standing session safety rule (live-theme-mutation prohibition) — deferred to operator with exact command and expected result"
    verification: []
    human_judgment: true
    rationale: "Requires a live theme-mutating command this executor's session rules unconditionally prohibit running; only the operator can perform it safely."

duration: 25min
completed: 2026-08-16
status: complete
---

# Phase 21 Plan 09: Contract Close and Album-Art Handoff Hardening Summary

**Added the first-ever test for the album-art bare-path handoff, root-caused and fixed two quickshell-doctor checker bugs that were producing false failures (not real desktop defects), and committed a full gate-by-gate evidence document closing RETIRE-08 with the theme contract confirmed at 17 entries.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-08-16T16:21:00Z (approx)
- **Completed:** 2026-08-16T16:46:00Z (approx)
- **Tasks:** 2
- **Files modified:** 3 (2 modified, 1 created)

## Accomplishments

- **Task 1:** Added Check 12 (T-21-26) to `test-media-hardening.sh` covering the album-art handoff MediaBackend.qml's own header calls "the breakable link" — the resolver's stdout must always be a bare local filesystem path with no scheme separator, on both a remote-URL input (through the suite's stubbed curl) and a local `file://` input. Proved the assertion logic could report red first (fed a standalone deliberately scheme-carrying value, observed `[FAIL]`), then wired it against the real resolver. 24/24 checks pass; suite still references the retained resolver 22 times and zero deleted-script references remain.
- **Task 2:** Ran every gate this phase's changes could affect, captured raw output, and root-caused the two quickshell-doctor failures 21-GATE-02-RECORD.md explicitly carried forward as this plan's own business — both turned out to be checker bugs, not real desktop defects:
  - `bar-reserved-zone-stability`'s hot-reload half AND its toggle-restore half both compared the entire `hyprctl monitors -j` blob for byte equality, which is sensitive to unrelated live fields (focused workspace, active window) changing during the up-to-10s polling window — exactly the instability 21-GATE-02-RECORD.md flagged (3 pass/fail counts observed across pre-fix runs this session: 17p/3f, then stabilizing differently run to run). Fixed with a new shared helper (`_qsd_reservation_equal`) narrowing every comparison in the check to the same name-keyed `reserved`-only diff the toggle half's own axis/delta measurement already used correctly.
  - `permissions-allowlist-paths-resolve`'s binary-path extraction was not line-aware — it matched `binary = "..."` inside Lua `--` comments exactly as readily as inside a live `hl.permission()` call. The real `permissions.lua` carries three deliberately-inert "STOP — DO NOT ENABLE" candidate grants (D-35, a documented decision record of a reproduced compositor SIGSEGV), which is the exact and only source of the reported `grants=9 missing=2 pattern=1`. Fixed to skip `--`-prefixed lines, matching the file's own existing `_qsd_windowrules_candidates` precedent.
  - Verified: `--self-test` still 59/59 after both fixes (including the 4 MPRIS reader-count fixtures, unaffected). 5 consecutive live invocations now report identical `rc=0, 20 passed, 0 failed` (previously oscillated between 1-3 failures per run).
  - Committed `.planning/phases/21-media-fold-in-contract-close/21-CONTRACT-CLOSE-EVIDENCE.md` (611 lines): summary table, full/representative raw output for every gate, the before/after retirement-check `ags` sweep pair cross-referenced and re-confirmed fresh against this plan's own commits (`failed_classes=0`), theme contract confirmed at 17 entries with the removed entry's `scss-vars` format family still represented (`_motion.scss`), and exactly one MPRIS reader confirmed live on every run this session.
  - `theme-stress-test` was explicitly **not** run — see Deviations.

## Task Commits

1. **Task 1: Cover the album-art handoff nothing tests today** - `ec23c4c` (test)
2. **Task 2: Run every affected gate after the deletion and commit the raw evidence** - `ca50e68` (fix, quickshell-doctor bug fixes), `4fa48f1` (docs, evidence document)

**Plan metadata:** this commit (`21-09-SUMMARY.md`, `STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md`) — see final commit below.

## Files Created/Modified

- `hypr/.config/hypr/scripts/tests/test-media-hardening.sh` - added Check 12 (T-21-26), the album-art bare-path handoff contract, on both remote-URL and local file:// inputs
- `hypr/.config/hypr/scripts/quickshell-doctor` - new `_qsd_reservation_equal` helper narrows `bar-reserved-zone-stability`'s comparisons to the reserved-space-only diff (fixes hot-reload and restore-verification false failures); `permissions-allowlist-paths-resolve`'s extraction made line-aware to skip Lua `--` comments (fixes the false `missing=2 pattern=1`)
- `.planning/phases/21-media-fold-in-contract-close/21-CONTRACT-CLOSE-EVIDENCE.md` - committed raw output of every affected gate, before/after sweep pair, theme contract state, MPRIS reader confirmation

## Decisions Made

- **theme-stress-test deliberately not run.** The plan's own Task 2 `<verify>` block includes a `theme-stress-test` invocation, but this executor's standing session rules unconditionally prohibit running it or any command that live-applies a theme — a prior session ran it by accident during Plan 08 and re-themed the operator's live desktop mid-session. This is a genuine conflict between the plan text and a higher-priority session-level safety rule; the safety rule was followed. Verified statically instead (`REPRESENTATIVE_FILES=(hyprland-tokens.lua gtk-4.0-colors.css kitty.conf)` does not name the removed `ags.scss` entry, matching 21-08-SUMMARY.md's own prior confirmation) and recorded as an explicit operator action.
- **Investigated rather than accepted the quickshell-doctor instability.** 21-GATE-02-RECORD.md flagged that the pass/fail count differed between two consecutive runs and explicitly asked this plan to investigate, not paper over it. Read the check's own source, measured the exact discrepancy (a raw whole-JSON-blob comparison vs. the check's own correctly-scoped toggle-half comparison two lines away in the same function), and fixed both root causes with real code changes plus explanatory comments — not a retry loop, not a scope narrowing, not a skip.
- **theme-doctor's 3 pre-existing failures left unfixed, honestly disclosed.** `hypr-equivalence-check: binds.json` (Super+M baseline acceptance gap, Plan 21-07), `retirement-check: waybar/keybinds` and `waybar/cross-package-refs` (Phase 18 Plan 20 debt) are all pre-existing and untouched by this plan's own commits — confirmed against 21-08-SUMMARY.md's own prior flagging of these exact three lines. Per the deviation rules' scope boundary ("only auto-fix issues DIRECTLY caused by the current task's changes"), fixing them would mean expanding this plan into unrelated Phase 18/21-07 debt it does not own.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `bar-reserved-zone-stability` comparison scope too broad, causing false failures**
- **Found during:** Task 2, while investigating the run-to-run instability 21-GATE-02-RECORD.md named as this plan's business
- **Issue:** The hot-reload half and the toggle-restore half of this check both compared the entire `hyprctl monitors -j` blob for string equality across a bounded polling window, which includes volatile fields (focused workspace, active window) unrelated to the bar's own reservation. Any of those changing during the window flipped the verdict to "drifted"/`restore-verified=0` with zero real reservation instability involved — reproduced directly this session (3 consecutive pre-fix live runs: 3 failures, then 1, then 1, matching the exact instability description).
- **Fix:** New shared helper `_qsd_reservation_equal` narrows every comparison in this check to the same name-keyed `reserved`-only diff the toggle half's own axis/delta measurement already used correctly, applied at all three call sites (hot-reload half, both restore-verification sites).
- **Files modified:** `hypr/.config/hypr/scripts/quickshell-doctor`
- **Verification:** `--self-test` 59/59 unchanged; 5 consecutive live runs post-fix all identical (rc=0, 20 passed, 0 failed).
- **Committed in:** `ca50e68`

**2. [Rule 1 - Bug] `permissions-allowlist-paths-resolve` extraction matched inside Lua comments**
- **Found during:** Task 2, same investigation
- **Issue:** `grep -oP 'binary\s*=\s*"\K[^"]+'` over the raw file matched `binary = "..."` inside `--`-prefixed Lua comment lines exactly as readily as inside a live `hl.permission()` call. The real `permissions.lua` carries three deliberately-inert "STOP — DO NOT ENABLE" candidate grants (D-35) kept only as a documented decision record — the exact and only source of the reported `grants=9 missing=2 pattern=1`.
- **Fix:** Extraction made line-aware, skipping any line whose trimmed text starts with `--`, matching this same file's existing `_qsd_windowrules_candidates` precedent for the identical reason.
- **Files modified:** `hypr/.config/hypr/scripts/quickshell-doctor`
- **Verification:** `--self-test` 59/59 unchanged (all 3 permissions fixtures still correctly PASS/FAIL); live run now reports `grants=6 missing=0 non-executable=0 pattern=0` (down from `grants=9 missing=2 pattern=1`).
- **Committed in:** `ca50e68`

---

**Total deviations:** 2 auto-fixed (both Rule 1 — checker bugs producing false failures, root-caused by reading source and measuring rather than assumed).
**Impact on plan:** Both fixes were necessary to make the plan's own "green with committed evidence" success criterion honest rather than narrowed. No scope creep — both fixes are confined to the exact two checks 21-GATE-02-RECORD.md named as this plan's own business.

## Issues Encountered

**theme-stress-test could not be run from this session.** See Decisions Made above and User Setup Required below — this is a standing-rule conflict with the plan's own `<verify>` block, resolved in favor of the safety rule, with a static substitute verification performed instead.

**theme-doctor's 3 pre-existing failures and retirement-check --all's `waybar` failure remain.** Confirmed unrelated to media/AGS and not touched by this plan's own commits. Left for a future plan/phase that owns that debt (Phase 18 waybar retirement follow-through, Plan 21-07's Super+M baseline acceptance).

## Known Stubs

None.

## User Setup Required

**Manual host action required — cannot be automated from this session (standing rule 5, live-theme-mutation prohibition):**
```bash
bash theme-engine/.config/theme-engine/theme-stress-test
```
Expected result: exit 0, 10 consecutive alternating static↔dynamic theme switches complete without abort. This is the final live confirmation that removing the `ags.scss` contract entry did not repeat the prior retirement's "named representative file" breakage — static verification this session already confirmed `REPRESENTATIVE_FILES` does not name it, but the plan's own success criterion asks for the live run too.

## Next Phase Readiness

- RETIRE-08 is closed: theme contract confirmed at 17 file entries, format family (`scss-vars`) still represented, no orphaned entries, before/after retirement-check sweep pair committed and cross-referenced.
- QMEDIA-03 is closed: exactly one MPRIS reader confirmed live on every gate run this session, citing both the Plan 21-04 sweep and the now-repaired standing check.
- The two quickshell-doctor failures 21-GATE-02-RECORD.md carried forward are both closed with real fixes, not narrowed or waved through — 5 consecutive live runs prove the stability.
- `theme-stress-test`'s live run is the one remaining operator action before Phase 22 (fresh-install proof) should be considered to have inherited a fully-verified Phase 21.
- theme-doctor's 3 pre-existing failures (`hypr-equivalence-check: binds.json`, `waybar/keybinds`, `waybar/cross-package-refs`) and `retirement-check --all`'s `waybar` failure are unrelated debt this phase does not own — worth tracking before Phase 22's fresh-install verification, since a fresh install exercises the same baseline/retirement machinery.

---
*Phase: 21-media-fold-in-contract-close*
*Completed: 2026-08-16*

## Self-Check: PASSED

- FOUND: `hypr/.config/hypr/scripts/tests/test-media-hardening.sh`
- FOUND: `hypr/.config/hypr/scripts/quickshell-doctor`
- FOUND: `.planning/phases/21-media-fold-in-contract-close/21-CONTRACT-CLOSE-EVIDENCE.md`
- FOUND: commit `ec23c4c` in `git log --oneline --all`
- FOUND: commit `ca50e68` in `git log --oneline --all`
- FOUND: commit `4fa48f1` in `git log --oneline --all`
