# Phase 22 Plan 05: Fix-and-Re-Run Loop — Zero-Defect Finding

**Purpose of this document (per plan 22-05, Task 1):** one row per iteration —
step that failed, actual failing line, repository-vs-harness classification,
fix, commit SHA, resulting step ledger. This run of the loop produced **zero
rows**, and this document records why that is a legitimate outcome rather than
an absence of one.

## Iteration count: 0

Task 1's bounded loop (max 4 iterations) never entered iteration 1, because
its own precondition — a step that failed — was never true. Plan 22-04's
Task 3 run (`run-20260816T230409Z`, `origin/main` at `56a9bd5`, warm cache)
already reached `overall=PASS` with all nine gating step tokens `status=ok`
before this plan started. There is no defect to work from; the failing-line
extraction in step 1 of the per-defect cycle has nothing to extract.

## What was verified before accepting the zero-defect finding

Per this plan's own instruction ("Do NOT take the green run on trust"), the
green run's evidence was independently re-examined rather than accepted from
22-04's SUMMARY on faith:

1. **`git rev-parse HEAD` vs `origin/main` at the start of this plan:**
   both `1da4da968118ab76403e8e8165fc3b333b83483e` — identical, working tree
   clean. No unpushed local commits exist that a re-run would need to see.

2. **No repository or harness change has landed since the green run.**
   `git log --oneline -5` from this plan's start shows only doc-only commits
   (`1da4da9`, `f30fe6c`) on top of 22-04's own run-recording commit
   (`5657fda`) — nothing in `install.sh`, `stow.sh`,
   `verify/container-run.sh` or the allowlist has changed since the run that
   produced `overall=PASS`. The evidence is current, not stale.

3. **The four copied evidence logs (`baseline-evidence/22-04-*.log`) were
   read in full and checked against 22-04-SUMMARY.md's claims — line by
   line, not by trusting the summary's prose:**
   - `22-04-summary.log`: exact line `overall=PASS`; all nine step tokens
     (`pull`, `bootstrap`, `paru-cache-seed`, `clone`, `install`, `stow`,
     `retirement-check`, `stow-link-check`, `theme-doctor`, `theme-parity`)
     present with `status=ok` (`paru-cache-seed` is `attempted rc=0`, its own
     non-gating convention); `theme-doctor` line reads
     `status=ok allowed=3 blocking=0` verbatim.
   - `22-04-04a-retirement-check.log`: all eight registered surfaces
     (`waybar`, `swaync`, `swayosd`, `wleave`, `ags`, `wlogout`, `eww`,
     `retirement-fixture`) report `Summary: surface=<name> status=retired
     failed_classes=0` — read every one, not sampled.
   - `22-04-04b-stow-link-check.log`: `Summary: 3 passed, 0 failed`, sweeping
     three present roots (`.config` — 43 symlinks, `Pictures/Wallpapers` —
     92 symlinks, `.` — 1 symlink), none dangling.
   - `22-04-05-theme-doctor.log`: tail confirms `Summary: 571 passed, 3
     failed` — the exact count `allowed=3 blocking=0` in `summary.log`
     depends on, and the same three session-dependent failures 22-04's
     allowlist derivation already justified from source.

4. **`verify/container-run.sh` on `origin/main` still carries all nine
   step tokens and zero informational statuses** — `grep -c
   'status=informational'` returns 0, confirming no gate was silently
   weakened between the green run and this plan starting.

5. **All three of 22-04's task commits (`4662571`, `56a9bd5`, `5657fda`)
   are present in `git log --oneline --all` and on `origin/main`** — the
   fixes that got the harness to green genuinely reached the remote the
   container clones from, not merely the local tree.

## Why the loop was not re-run live in a fresh container

The plan authorizes either path explicitly: close on 22-04's existing run
after verifying its evidence, or re-run the gate for fresh first-hand
evidence. Given (a) the evidence above is internally consistent and
independently re-derivable from the raw logs rather than only the summary
prose, (b) zero repository or harness changes have landed since the green
run that could plausibly flip its verdict, and (c) a re-run costs ~17 minutes
of container time to reproduce a result already fully evidenced on disk, this
plan closes on the existing run rather than re-running. This is the
plan-sanctioned "close on 22-04's existing run" path, exercised with its
required verification step actually performed (§ above), not skipped.

## The actual finding

**The five stow-package deletions this milestone made (`waybar`, `swaync`,
`swayosd`, `wleave`, `ags`, plus the already-retired `wlogout`/`eww`
leftovers) did not break fresh-install reproduction, and the newly-blocking
`retirement-check --all` and `stow-link-check` steps — which assert
specifically against the *reproduced* system rather than the developer
host — found nothing to catch.** This is the substantive result plan 22-04
projected in its own "Next Phase Readiness" section, now confirmed rather
than merely anticipated: "This run's `overall=PASS` with `allowed=3
blocking=0` means the modified harness itself works correctly and the
repository currently has zero defects the new blocking steps caught."

A zero-defect loop is not "nothing happened" — it is the harness's answer to
the question this whole phase exists to ask, and the answer is that the
migration reproduces cleanly. Per this plan's acceptance criteria, the row
count in this document (0) correctly equals the number of harness runs made
in this plan (0) minus the final green one (which is 22-04's, not a new run
of this plan's own) — 0 minus a run this plan did not itself make land on 0
by construction, consistent with "close on the existing run" rather than
"run and then subtract the green one from a new count."

## Task 3 checkpoint: not triggered

Task 1's bounded loop did not exhaust four iterations without reaching
green — it never needed a first iteration, because the precondition for
entering the loop (a failing step) was never true. The checkpoint at the end
of this plan exists only for that non-convergence case and its
architecture-change escalation case; neither applies. Per the plan's own
framing ("If Task 1 reached green, skip this checkpoint entirely and the
plan is autonomous in practice"), this plan proceeds directly to Task 2.
