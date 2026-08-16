---
phase: 22-fresh-install-proof
plan: 06
subsystem: docs
tags: [verification, inst-03, retire-09, graphical-vm-tier, human-render-gate]

# Dependency graph
requires:
  - phase: 22-fresh-install-proof
    plan: 03
    provides: "VERIFICATION.md amended to the current QBAR/QNOTIF/QOSD/QPOWER/QMEDIA surface inventory, unflagged VM install scope, and the pre-authored D-22-02 exemption list this plan's operator run followed"
  - phase: 22-fresh-install-proof
    plan: 05
    provides: "run-20260816T230409Z: the green, independently re-verified container run this plan's pre-flight cross-checked the SHA of, and whose evidence this plan's record cites alongside the VM verdict"
provides:
  - "22-VERIFICATION-RECORD.md: the full INST-03 verdict — both tiers, one tree (origin/main @ 4cee477c33df), operator verdict quoted verbatim, exemption row noted available-but-unused, teardown confirmed, success criteria closed on cited evidence"
  - "RETIRE-09 CLOSED — REQUIREMENTS.md checkbox ticked and Traceability row updated with the closing evidence citation"
  - "ROADMAP.md Phase 22 marked Complete: 9/9 plans, Progress table row updated (scoped edits, no other phase touched)"
affects: []

actuals:
  tokens: 9200
  tasks: 3
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Pre-flight tree-identity proof by diffstat, not assertion — when a checkpoint spans two independently-run proof tiers, diffing the exact SHA each tier touched against the current HEAD (and confirming every intervening commit is doc-only) is what makes 'both tiers proved the same tree' a checked fact rather than a hoped one"
    - "Exemption row disposition recorded as a three-state fact (invoked / available-but-unused / removed), never collapsed to two — an unused provisional exemption is neither 'resolved' nor silently deleted; the underlying risk it names stays real for the next run"

key-files:
  created:
    - .planning/phases/22-fresh-install-proof/22-VERIFICATION-RECORD.md
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md

key-decisions:
  - "Task 1's pre-flight found origin/main had moved 6 commits (not the anticipated handful) past the SHA the container tier actually cloned (56a9bd5 -> 4cee477). Rather than treat this as a drift failure, verified concretely via git diff --stat that every touched file across all 6 commits lives under .planning/ — zero touches to install.sh, stow.sh, verify/, hypr/, or theme-engine/ — so the reproduction-relevant tree is byte-identical between the two SHAs. This is the same discipline 22-05 applied when closing SC-1/2/3 on cited evidence rather than trusted prose, extended here to the tree-identity question specifically."
  - "The one pre-authored VM exemption (hypr-equivalence-check: options.jsonl, D-22-02) went unused this run — options.jsonl matched cleanly against the VM's own live Hyprland version. Recorded explicitly as 'available, not invoked in this verdict' rather than 'resolved': the underlying baseline-drift risk (0.56.1 capture vs. whatever a future fresh VM's extra-repo Hyprland build happens to be) is still real and the row stays in VERIFICATION.md, not deleted on the strength of one clean run."
  - "The VM's four session-dependent theme-doctor checks (walker/elephant process, gsettings gtk-theme, elephant listproviders) passed cleanly with NO allowlist needed on the VM — recorded explicitly in the verdict record as the point the container tier structurally cannot reach: its own separate allowlist exists to admit exactly these four failing headless, which is a limitation of the container, not the desktop."

patterns-established: []

requirements-completed: [RETIRE-09]

coverage:
  - id: D1
    description: "A human has personally seen the fully themed desktop come up on a genuinely fresh Arch install, on the VM's own display, and recorded a verdict — the tier the container cannot exercise at all"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "22-VERIFICATION-RECORD.md § VM tier — operator verdict quoted verbatim (PASS / no exemptions / nothing unexpected / VM destroyed), returned against VERIFICATION.md's own D-53 pass condition which requires personally seeing every listed surface themed correctly on the VM's own display"
        status: pass
    human_judgment: false
  - id: D2
    description: "Both proof tiers have run against the same origin/main, so the graphical evidence and the container evidence describe one repository state rather than two"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "git diff --stat 56a9bd5 4cee477 (Task 1 pre-flight): all 13 changed files confined to .planning/; zero touches to install.sh, stow.sh, verify/, hypr/, theme-engine/ — the reproduction-relevant tree is identical between the SHA the container tier cloned (56a9bd5) and the SHA the VM tier cloned (4cee477)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The VM tier ran install.sh unflagged, installing the previously-never-installed tracked system tree for the first time in any reproduction proof"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "22-VERIFICATION-RECORD.md § VM tier 'Install scope actually run' — unflagged install.sh per VERIFICATION.md §5's D-22-11 amendment; operator's unqualified PASS entails the post-install verification table ended with [OK] for every package including the fallback-kernel set the unflagged run adds, with no [MISS]"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-22-02: Every deviation the human accepted appears on the exemption list authored before the run; anything outside that list was treated as a real defect"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "22-VERIFICATION-RECORD.md § Exemptions invoked — operator reported ZERO exemptions invoked (a stronger result than the bar required); the sole pre-authored D-22-02 row (hypr-equivalence-check: options.jsonl) is recorded as available-but-unused, not deleted, not extended"
        status: pass
    human_judgment: false
  - id: D5
    description: "The VM was destroyed after the verdict, so no passwordless-sudo configuration survives anywhere"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "22-VERIFICATION-RECORD.md § Teardown — operator confirmed destroyed, per VERIFICATION.md step 9 (virsh destroy + virsh undefine --remove-all-storage)"
        status: pass
    human_judgment: false
  - id: D6
    description: "RETIRE-09 is marked complete only after both tiers passed — a tool-only pass without human visual confirmation does not satisfy it, by the procedure's own stated condition"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "REQUIREMENTS.md RETIRE-09 row and Traceability table: ticked only after this plan recorded the operator's PASS verdict in Task 3, not at Task 1's pre-flight or at any prior plan in this phase (22-01..22-05 all explicitly declined to close it early, per their own frontmatter)"
        status: pass
    human_judgment: false

duration: ~35min active (across a blocking checkpoint pause for the operator's VM run)
completed: 2026-08-17
status: complete
---

# Phase 22 Plan 06: Graphical VM Tier and RETIRE-09 Closure Summary

**The milestone's closing regression gate is proven on both tiers: the container's mechanical PASS (`run-20260816T230409Z`) and now a human's own eyes on a genuinely fresh Arch VM's own display — PASS, zero exemptions invoked, VM destroyed — closing `RETIRE-09` and, with it, every requirement in v4.0.**

## Performance

- **Duration:** ~35 min active executor time, spanning a blocking `checkpoint:human-verify` for the operator's own VM run (steps 1-9 of `VERIFICATION.md`, run by hand, not timed as executor duration)
- **Tasks:** 3 (Task 1 pre-flight, Task 2 the operator's own checkpoint, Task 3 verdict recording + closure)
- **Files modified:** 3 (`22-VERIFICATION-RECORD.md` created, `REQUIREMENTS.md`, `ROADMAP.md`)

## Accomplishments

- **Task 1 — pre-flight found and resolved a genuine tree-drift question rather than assuming it away.** `origin/main` had moved 6 commits past the SHA the container tier's actual run cloned (`56a9bd5` → `4cee477`). Rather than block or silently proceed, ran `git diff --stat` across the full range and confirmed every touched file lives under `.planning/` — zero touches to `install.sh`, `stow.sh`, `verify/`, `hypr/`, or `theme-engine/`. The reproduction-relevant tree the container tier proved is byte-identical to the tree the VM tier was about to clone. Also verified the amended procedure directly: unflagged VM invocation, all five `QBAR`/`QNOTIF`/`QOSD`/`QPOWER`/`QMEDIA` IDs present in `VERIFICATION.md`, the exemption list's single row resolving both its source references (`.hypr-baseline/MANIFEST.md:3` confirming the 0.56.1 capture, live `hyprctl version` confirming 0.56.2 drift, `hypr-equivalence-check:347/350` confirming the unconditional-FAIL branches). Produced the operator handoff (SHA, pass bar, exemption row verbatim, surface inventory, teardown reminder) as the checkpoint's own content rather than a separate file.
- **Task 2 — the operator ran the graphical VM tier and returned a verdict.** PASS, zero exemptions invoked, nothing unexpected, VM confirmed destroyed. This is the tier no automation in this phase could perform, simulate, or self-approve — the checkpoint was returned and genuinely awaited, not skipped.
- **Task 3 — the verdict recorded, RETIRE-09 closed.** `22-VERIFICATION-RECORD.md` written with all seven required sections (tiers/tree, container tier, VM tier, exemptions invoked, anything unexpected, teardown, success criteria closure). Two details captured precisely rather than smoothed: the sole D-22-02 exemption row is recorded as **available, not invoked** — not resolved, not deleted, since the Hyprland baseline-drift risk it names stays real for future runs — and the VM's four session-dependent `theme-doctor` checks (walker/elephant process, gsettings, elephant listproviders) are called out as passing cleanly with **no allowlist needed on the VM**, the exact question the container tier's own separate allowlist exists only to defer. `REQUIREMENTS.md`'s `RETIRE-09` row ticked with a citing evidence trail in both the main list and the Traceability table. `ROADMAP.md`'s Phase 22 entry, plan-list checkbox, plan-count line, and Progress table row all updated — `git diff --stat` confirms the edit stayed confined to those four spots, no other phase touched. `retirement-check --all` re-run after every edit: `failed_classes=0` across all 8 registered surfaces, both before and after.

## Task Commits

1. **Task 1: Pre-flight — confirm both tiers prove the same tree** — no commit (read-only; the handoff was the checkpoint's own returned content, per the plan's `<files>` spec)
2. **Task 2: Operator's graphical VM tier + verdict** — no commit (the operator's own run, outside this repo's git history)
3. **Task 3: Record the verdict and close RETIRE-09** — `9712afd` (docs)

**Plan metadata:** *(pending — this SUMMARY + STATE.md commit, made immediately after this document)*

## Files Created/Modified

- `.planning/phases/22-fresh-install-proof/22-VERIFICATION-RECORD.md` — new, the full INST-03 closing record
- `.planning/REQUIREMENTS.md` — `RETIRE-09` ticked in the main list and the Traceability table, both carrying the closing evidence citation
- `.planning/ROADMAP.md` — Phase 22's checklist entry, plan-count line, `22-06-PLAN.md`'s own checkbox, and the Progress table row all updated to Complete/9/9/2026-08-17; edit confirmed scoped to Phase 22 only

## Decisions Made

- **Tree-identity proof by diffstat, not assertion.** See `key-decisions`. The precondition text asked for "an explicit comparison, not implied" — a diff over the actual commit range, filtered by which subtrees were touched, is the concrete form that takes.
- **Exemption disposition kept as a three-state fact.** Invoked / available-but-unused / removed are three genuinely different things and this record keeps them distinct — collapsing "unused" into "resolved" would misrepresent a real, still-open baseline-drift risk as closed.
- **Session-dependent checks called out by name as the container's structural blind spot, not the desktop's weakness.** Worth stating explicitly per the coordinator's own framing: the container tier's allowlist exists because the container cannot start Hyprland, not because those four checks are unreliable — and this run is the direct proof, since they passed with zero exemption on real hardware-adjacent conditions.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written across all three tasks. The 6-commit (rather than assumed-smaller) drift found at Task 1's pre-flight was investigated and resolved within the task's own instructions (compare explicitly, don't imply), not a deviation requiring a rule.

## Issues Encountered

None blocking. `retirement-check --all` stayed green (`failed_classes=0` x8) both before this plan's edits and after — no retired-surface name leaked into the new prose despite this phase's own history of that exact trap (22-03's discrepancy record, 21's `git blame`-caught regression).

## User Setup Required

None beyond the operator's own VM run, which is the substance of this plan's Task 2 — already completed and recorded above.

## Next Phase Readiness

- **`RETIRE-09` is closed — the last open requirement in v4.0.** All 55 v4.0 requirements are now `[x]` in `REQUIREMENTS.md`.
- **Phase 22 is complete (9/9 plans), and it is v4.0's final phase (Phases 18-22).** This plan's own scope does not extend to milestone-level closeout (archiving, `MILESTONES.md`, `PROJECT.md` evolution) — that is `/gsd-complete-milestone`'s job, not this executor's, and `ROADMAP.md`'s milestone-level header/status was deliberately left untouched per this plan's own "scoped edits only, do not rewrite the file" instruction.
- **Push discipline held.** `HEAD` matched `origin/main` at plan start (`4cee477`); this plan's one commit (`9712afd`) is pushed alongside the SUMMARY/STATE commit that follows.

---
*Phase: 22-fresh-install-proof*
*Completed: 2026-08-17*

## Self-Check: PASSED

Both claimed files verified present on disk; claimed commit (`9712afd`) verified present in `git log --oneline --all`.
