---
phase: 18-qml-bar-retirement-machinery
plan: 04
subsystem: docs
tags: [ledger, bookkeeping, milestones, windows-ledger, debug-sessions]

# Dependency graph
requires: []
provides:
  - "PROJECT.md § Active no longer claims the panel-family rim is missing or that quickshell-doctor carries live legacy dispatch sites"
  - "MILESTONES.md v3.0 archive carries dated supersession annotations on both stale gap bullets, original wording preserved"
  - "WINDOWS.md row 14 closed (open_count 17 -> 16), table and JSON representations agree"
  - "panels-missing-animated-border debug session resolved and curated to .planning/debug/resolved/"
affects: [19-notification-server-and-centre]

actuals:
  tokens: 6602
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Archive supersession by append, not rewrite — a dated SUPERSEDED sentence appended to an as-of-close bullet, original wording left greppable, per the precedent PROJECT.md:144 already set with ~~struck~~ + REVERSED"

key-files:
  created: []
  modified:
    - .planning/PROJECT.md
    - .planning/MILESTONES.md
    - .planning/WINDOWS.md
    - .planning/debug/resolved/panels-missing-animated-border.md

key-decisions:
  - "Tracer feedback gate treated as satisfied by Task 1's own automated <verify> (fully grep-based, no human judgment required) rather than issuing a checkpoint:human-verify — the plan's own frontmatter (autonomous: true) and success criteria explicitly forbid introducing any human checkpoint for this bookkeeping-only plan, and re-requesting the operator's already-given 2026-08-10 visual confirmation is one of the plan's stated prohibitions."
  - "Did not edit MILESTONES.md's archived 'SEGV-crashed the compositor' wording to match the plan's acceptance-criteria string 'SEGV-crashed this compositor' — the plan's own prohibition bars rewriting what the v3.0 audit recorded as true at close; the mismatch is a wording typo in the plan's verification command, not a defect in the edit."

patterns-established:
  - "Archive supersession by append: dated SUPERSEDED sentence appended to an as-of-close claim rather than deleting/rewriting it, keeping the milestone audit's original knowledge state auditable."

requirements-completed: [LEDGER-01]

coverage:
  - id: D1
    description: "PROJECT.md § Active GradientBorder bullet ticked and replaced with commit-4f48847 evidence; Current State gap count corrected from two to one; Phase 13.1 narrative annotated with a dated closure clause"
    requirement: "LEDGER-01"
    verification:
      - kind: other
        ref: "Task 1 <verify> automated grep chain (9 assertions) — see Task 1 commit 57574f3"
        status: pass
    human_judgment: false
  - id: D2
    description: "MILESTONES.md's two stale v3.0 archive claims (GradientBorder gap, WINDOWS #14) superseded in place with dated annotations, original wording preserved; debug-session roster corrected 6 -> 5; WINDOWS row 14 marked fixed via the gsd-tools mutator, both table and JSON representations agree"
    requirement: "LEDGER-01"
    verification:
      - kind: other
        ref: "Task 2 <verify> automated grep chain — see Task 2 commit 5ae712d (all pass except the SEGV wording mismatch, documented below as a plan-checker typo, not an edit defect)"
        status: pass
    human_judgment: false
  - id: D3
    description: "panels-missing-animated-border debug session flipped to status: resolved with real fix:/verification:/files_changed: content, investigation body untouched, curated via git mv into .planning/debug/resolved/"
    requirement: "LEDGER-01"
    verification:
      - kind: other
        ref: "Task 3 <verify> automated grep/sed chain — see Task 3 commits d5a27a8 + 600c347"
        status: pass
    human_judgment: false

duration: ~15min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 04: Close LEDGER-01's Documentation Ledger Summary

**Corrected four documents that still claimed the panel-family GradientBorder rim was missing and quickshell-doctor carried live legacy dispatch sites — both fixes shipped weeks earlier (commit `4f48847` on 2026-08-02 and the 13.1 Lua migration), only the paperwork was stale.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-08-10T23:50:52Z
- **Completed:** 2026-08-11T02:54:32Z (elapsed spans a pause between sessions; active work ~15 min)
- **Tasks:** 3
- **Files modified:** 4 (`.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/WINDOWS.md`, `.planning/debug/resolved/panels-missing-animated-border.md`)

## Task 1 Precondition Evidence (verbatim command outputs)

Re-asserted against the working tree before any edit, per the plan's `<precondition>`:

```
$ sed -n '191p' quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml
    GradientBorder {

$ git log --oneline -1 4f48847
4f48847 feat(15-10): instantiate GradientBorder inside PanelDialog.qml

$ grep -v '^[[:space:]]*#' hypr/.config/hypr/scripts/quickshell-doctor | grep -q 'dispatch global'; echo "exit=$?"
exit=1   (no live match — the only remaining "dispatch global" occurrences are inside comments)
```

All three preconditions held; the plan proceeded.

## Accomplishments
- PROJECT.md § Active: `GradientBorder` bullet ticked, stale claim replaced with commit `4f48847` evidence; § Current State gap count corrected from "two known gaps" to "one known gap" (OVER-04 only); Phase 13.1 narrative annotated in place with a dated closure clause, original sentence preserved
- MILESTONES.md § v3.0: both "Known gaps at close" bullets (GradientBorder reuse, WINDOWS #14) superseded with dated `SUPERSEDED 2026-08-10 (LEDGER-01)` sentences appended, original as-of-close wording kept intact and greppable; debug-session roster corrected 6 → 5, `panels-missing-animated-border` name removed from the unresolved list
- WINDOWS.md row 14 marked `fixed` via the sanctioned `gsd-tools windows fixed 14` mutator (not hand-edited) — table and JSON representations moved together, `resolved_at` populated, `open_count` dropped from **17 → 16**
- `panels-missing-animated-border` debug session flipped to `status: resolved`, `fix:`/`verification:`/`files_changed:` populated with real evidence, investigation body left untouched, curated via `git mv` into `.planning/debug/resolved/` — leaving exactly five open sessions in `.planning/debug/` for LEDGER-04 (Phase 19)

## Task Commits

Each task was committed atomically:

1. **Task 1: Re-assert both code claims against the working tree, then correct PROJECT.md** — `57574f3` (docs)
2. **Task 2: Supersede the three stale claims in the v3.0 archive and close WINDOWS #14** — `5ae712d` (docs)
3. **Task 3: Flip the panels-missing-animated-border debug session to resolved and curate it** — `d5a27a8` (docs, rename) + `600c347` (fix — content diff follow-up, see Deviations)

**Plan metadata:** committed after this SUMMARY via the standard `docs({phase}-{plan}): complete` flow.

## Files Created/Modified
- `.planning/PROJECT.md` - Active bullet ticked with evidence; gap count 2→1; Phase 13.1 narrative annotated
- `.planning/MILESTONES.md` - two archive claims superseded in place; debug roster corrected 6→5
- `.planning/WINDOWS.md` - row 14 (table + JSON) marked fixed via mutator
- `.planning/debug/resolved/panels-missing-animated-border.md` - status resolved, real fix/verification/files_changed content, git-mv'd from `.planning/debug/`

## Decisions Made
- Tracer feedback gate satisfied via Task 1's own fully-automated `<verify>` rather than a `checkpoint:human-verify` — the plan is `autonomous: true` by design and explicitly prohibits re-requesting the operator's already-given visual confirmation.
- Left MILESTONES.md's archived "SEGV-crashed the compositor" wording untouched despite the plan's acceptance criterion expecting "SEGV-crashed this compositor" — preserving the audit's original wording takes precedence over satisfying a checker string that has a typo relative to the actual archive text.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Task 3's git-mv commit initially captured only the rename, not the content edits**
- **Found during:** Task 3, post-commit verification (re-running the plan's overall `<verification>` block)
- **Issue:** `git commit` after `git add <old-path> <new-path>` (old path already gone post-`git mv`, so that `add` errored harmlessly) produced a commit with `0 insertions(+), 0 deletions(-)` — a pure rename with none of the frontmatter/Resolution content edits made just before the `git mv`, even though those edits were confirmed present in the working tree by the task's own acceptance-criteria check moments earlier.
- **Fix:** Re-staged and committed the remaining content diff in a follow-up commit (`600c347`) immediately after discovering the gap during the plan-level `<verification>` re-run; root cause of the staging anomaly itself was not further investigated (out of scope for a docs-only plan).
- **Files modified:** `.planning/debug/resolved/panels-missing-animated-border.md`
- **Verification:** `git show 600c347 --stat` confirms the 20-insertion/5-deletion content diff landed; plan-level `<verification>` item 4 re-ran clean afterward.
- **Committed in:** `600c347`

**2. [Documented, not a code fix - checker/archive wording mismatch] Plan's SEGV acceptance-criteria string does not match the archived wording**
- **Found during:** Task 2 acceptance-criteria verification
- **Issue:** The plan's acceptance criteria and automated `<verify>` both check for the literal string `'SEGV-crashed this compositor'` in MILESTONES.md. The actual archived bullet (kept verbatim per this plan's own no-rewrite prohibition) reads `'SEGV-crashed the compositor'`.
- **Resolution:** Not fixed — deliberately left as-is. Rewriting the archive text to satisfy the checker would violate the plan's explicit prohibition against altering what the v3.0 audit recorded as true at close. Confirmed manually that the hazard caution sentence is fully intact and unmodified.
- **Files modified:** none (no-op by design)
- **Verification:** `grep -q 'SEGV-crashed the compositor' .planning/MILESTONES.md` → match confirmed.

---

**Total deviations:** 2 (1 auto-fixed via Rule 3, 1 documented as a plan-checker wording mismatch with no code/archive change made)
**Impact on plan:** No scope creep. Both are process artifacts of a docs-only plan; the plan's substantive corrections (PROJECT.md, MILESTONES.md, WINDOWS.md, debug session) all landed as specified.

## Issues Encountered
See Deviations above — both were caught and resolved within this same execution session, no open follow-up required.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- LEDGER-01 is closed as pure bookkeeping; no code was touched (confirmed by plan-level `<verification>` item 5: `git status --porcelain` after all edits is confined to `.planning/`, zero files under `quickshell/`, `hypr/`, `waybar/` or any other stow package).
- `.planning/debug/` now carries exactly five open sessions, correctly handing LEDGER-04 (Phase 19) a roster of five rather than six.
- WINDOWS.md `open_count` is 16, down from 17 at plan start.
- REQUIREMENTS.md LEDGER-01 status flip and the phase-close accounting are handled by the phase-close step, not this plan, per the plan's own scope statement.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*
