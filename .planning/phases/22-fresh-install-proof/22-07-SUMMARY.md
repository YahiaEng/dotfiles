---
phase: 22-fresh-install-proof
plan: 07
subsystem: infra
tags: [podman, container-run, install.sh, bash-trap, aur, threat-model]

# Dependency graph
requires:
  - phase: 22-fresh-install-proof
    provides: "plan 22-01's baseline evidence (overall=FAIL, two non-migration causes) and the operator's harness-repair-first decision this plan was chartered to act on"
provides:
  - "install.sh: AUR_PKGS_HOST host-only group (limine-dracut-support, kernel-modules-hook), scoping the container gate's default package set to what a container can actually complete"
  - "verify/container-run.sh: podman run -d + cidfile + bounded wait (backgrounded, blocking on bash's own `wait` builtin) + stop-kill-verify escalation under a trap EXIT INT TERM — replaces the attached timeout mechanism that left an orphaned container running past the host's own FAIL verdict"
  - "CONTAINER_TIMEOUT raised 3600s -> 10400s from measured evidence, with the arithmetic in the comment"
  - "22-REBASELINE.md: the first real theme-doctor failure inventory this phase has produced (571 passed / 3 failed, structural-reason column deliberately empty) — the sole admissible D-22-09 input plan 22-04 was blocked on"
  - "RETIRE-09's container-tier question answered on evidence: overall=PASS in 17min22s against origin/main at 41fd13f — the five stow-package deletions did not break fresh-install reproduction at this tier"
  - "T-22-01-DOS closed (not merely reported disproven) — its superseding mitigation T-22-07-DOS proven both on throwaway containers and in this production re-run"
affects: [22-04-fresh-install-proof, 22-05-fresh-install-proof, 22-06-fresh-install-proof]

actuals:
  tokens: 25247
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Detached podman container lifecycle: podman run -d + --cidfile, bounded wait via background job + bash `wait` builtin (not a synchronous foreground `timeout`, which isolates its child into a new process group and defers bash's own trap execution), stop --time=30 -> kill -> re-inspect-confirm escalation, all under trap ... EXIT INT TERM"

key-files:
  created:
    - .planning/phases/22-fresh-install-proof/22-REBASELINE.md
    - .planning/phases/22-fresh-install-proof/baseline-evidence/rerun-summary.log
    - .planning/phases/22-fresh-install-proof/baseline-evidence/05-theme-doctor.log
  modified:
    - install.sh
    - verify/container-run.sh

key-decisions:
  - "Operator selected proceed-to-04 at the Task 3 blocking checkpoint: the re-run resolved to world 1 (overall=PASS, gate reached a verdict) — plan 22-04 is unblocked with its D-22-09 input, no harness-repair round or rescope needed."
  - "T-22-01-DOS marked CLOSED, not merely disproven-and-reported: the superseding mitigation (T-22-07-DOS, this plan's Task 2) is now verified both on isolated throwaway containers and in a real production gate run — exactly one overall= line, no orphaned container."
  - "RETIRE-09 deliberately NOT marked complete. The container tier passed, but the requirement also needs the graphical VM tier (plan 22-06) and its human verdict — marking it now would be a false completion claim, matching the precedent plans 22-01, 22-08 and 22-09 already set."

patterns-established:
  - "Any future harness that starts a container it must be able to bound should copy this plan's mechanism verbatim (podman run -d + cidfile + backgrounded wait + bash wait builtin + stop/kill/verify escalation under a trap) rather than an attached foreground timeout — the latter's SIGKILL only reaches the podman run CLI client under rootless podman, not the conmon-owned container."

requirements-completed: []  # RETIRE-09 intentionally NOT marked complete — container tier only; VM tier (plan 22-06) still required.

coverage:
  - id: D1
    description: "install.sh --core-only no longer attempts limine-dracut-support or kernel-modules-hook; a default (no-flag) run still installs both"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "install.sh AUR_PKGS_HOST group + guard; both CORE_ONLY branches extracted and diffed via a source-isolated snippet (commit dbe25e7)"
        status: pass
    human_judgment: false
  - id: D2
    description: "container timeout mechanism actually stops the container it starts, not merely detaches from it — proven on throwaway containers before trusting it against the real gate"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "verify/container-run.sh podman run -d/wait/stop/kill/trap mechanism (commit e907f44); live demonstration on throwaway sleep(600) containers — budget-expiry and self-delivered-SIGINT interrupt paths both confirmed via podman ps -a"
        status: pass
    human_judgment: false
  - id: D3
    description: "verify/container-run.sh re-run against origin/main reaches a verdict: overall=PASS in 17min22s (1042s of a 10400s budget), install 125/125, stow ok, theme-parity 1545/0"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/22-fresh-install-proof/22-REBASELINE.md ## Run identity, ## Verdict, ## Step ledger"
        status: pass
    human_judgment: false
  - id: D4
    description: "theme-doctor's verbatim failure inventory (571 passed / 3 failed) captured with structural-reason column deliberately empty, as the sole admissible D-22-09 input for plan 22-04's allowlist"
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/22-fresh-install-proof/22-REBASELINE.md ## theme-doctor failure inventory (D-22-09 input); baseline-evidence/05-theme-doctor.log byte-identical copy"
        status: pass
    human_judgment: false
  - id: D5
    description: "T-22-01-DOS closed, superseded by T-22-07-DOS, proven in production (single overall= line, no orphaned container after the real gate run) not just on throwaway containers"
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/22-fresh-install-proof/22-REBASELINE.md ## Threat model update: T-22-01-DOS closed, superseded by T-22-07-DOS"
        status: pass
    human_judgment: false
  - id: D6
    description: "Task 3 blocking decision checkpoint (world-selection: proceed-to-04 / repair-again / rescope) presented to and answered by the operator"
    verification: []
    human_judgment: true
    rationale: "A blocking human decision by design — the plan withholds a recommendation and requires operator judgment on which world the re-run's verdict fits."
  - id: D7
    description: "RETIRE-09 deliberately left incomplete in requirements-completed — container tier only, VM tier (plan 22-06) still outstanding"
    verification: []
    human_judgment: true
    rationale: "Whether a requirement is genuinely complete vs. only partially proven is an operator-facing scope judgment, not a mechanically checkable fact — recorded explicitly per the operator's instruction so this is never inferred as a false completion later."

duration: multi-session (~50min active work across two sessions, paused mid-plan for the concurrent plan 22-09 speedup to land)
completed: 2026-08-17
status: complete
---

# Phase 22 Plan 07: Container-Gate Harness Repair + Re-baseline Summary

**Repaired two production harness defects (timeout-doesn't-stop-the-container, install.sh package scope mismatch), then re-ran the container gate against origin/main to `overall=PASS` in 17min22s — the first run this phase to reach `theme-doctor` and `theme-parity` at all, answering RETIRE-09's container-tier question on evidence.**

## Performance

- **Duration:** multi-session — Task 1+2 (~17 min, `dbe25e7`→`e907f44`), then a pause while the operator dispatched the concurrent plan 22-09 speedup (`1c24290`..`41fd13f`, not this plan's work), then Task 3 (re-run 17min22s + evidence-write, `4d2d387`)
- **Started:** 2026-08-16T21:15:14Z
- **Completed:** 2026-08-16T22:48:28Z (wall clock across sessions; the harness's own container-gate run measured 17min22s exactly)
- **Tasks:** 3
- **Files modified:** 5 (`install.sh`, `verify/container-run.sh`, `22-REBASELINE.md`, `baseline-evidence/rerun-summary.log`, `baseline-evidence/05-theme-doctor.log`)

## Accomplishments

- **Task 1:** Moved `limine-dracut-support` and `kernel-modules-hook` into a new `AUR_PKGS_HOST` group in `install.sh`, appended to `AUR_PKGS` only when `CORE_ONLY != true` — matching `install.sh:816`'s existing container-scope reasoning for `kernel-module-verify`. Both branches extracted and diffed via a source-isolated snippet (no real `install.sh` run) to prove the move was scope-correct in both directions.
- **Task 2:** Replaced `verify/container-run.sh`'s attached `timeout --kill-after=30 ... podman run --rm` with a detached, harness-owned lifecycle: `podman run -d --cidfile=...`, a bounded wait on bash's own `wait` builtin (backgrounded `timeout ... podman wait`, not synchronous — a genuine finding during live testing: GNU `timeout` isolates its child into a new process group by default and bash defers trap execution while blocked on a synchronous foreground command, so the original synchronous form would have left an interrupt-driven cleanup trap unexecuted until the full budget elapsed), `podman stop`→`kill`→re-inspect-confirm escalation on budget expiry, and `trap cleanup_container EXIT INT TERM` for unconditional cleanup. Raised `CONTAINER_TIMEOUT` 3600s→10400s from measured evidence. Demonstrated live on throwaway `sleep 600` containers (budget-expiry and self-delivered-SIGINT interrupt paths) before trusting it against the real gate.
- **Task 3:** Ran `verify/container-run.sh` exactly once against `origin/main` at `41fd13f` (unmodified beyond this plan's Tasks 1-2 and the concurrent plan 22-09's speedup). Result: `overall=PASS` in 17min22s of a 10400s budget — `install.sh --core-only` 125/125 packages verified, `stow.sh` ok, `theme-parity` 1545/0, `theme-doctor` informational at 571 passed / 3 failed. Wrote `22-REBASELINE.md` with the full ledger, verdict, verbatim theme-doctor inventory (structural-reason column deliberately empty), and a baseline-vs-rerun comparison table. Copied `summary.log` and `05-theme-doctor.log` into `baseline-evidence/` (byte-identical, `diff -q` confirmed) since `verify/logs/` is gitignored.
- Presented the Task 3 blocking decision checkpoint with the full re-run evidence; operator selected **proceed-to-04**, recorded in `22-REBASELINE.md`.
- Recorded T-22-01-DOS as **closed** (not merely disproven-and-reported) — its superseding mitigation, T-22-07-DOS, is now proven both on isolated throwaway containers (Task 2's own verify step) and in this production re-run (exactly one `overall=` line, `podman ps -a` empty afterward).

## Task Commits

Each task was committed atomically:

1. **Task 1: Move bootloader + kernel-hook packages out of `--core-only` scope** - `dbe25e7` (fix)
2. **Task 2: Stop the container on timeout instead of detaching from it** - `e907f44` (fix)
3. **Task 3: Re-run the gate, record verdict + theme-doctor inventory** - `4d2d387` (docs)

**Plan metadata:** *(pending — this SUMMARY + STATE.md + ROADMAP.md commit, made immediately after this document)*

*(Interleaved by the operator between Tasks 2 and 3, not this plan's own work but load-bearing to the re-run: plan 22-09's speedup — `1c24290`, `ee5009a`, `07e4aa2`, `9c78d60`, `41fd13f`.)*

## Files Created/Modified

- `install.sh` - `AUR_PKGS_HOST` host-only group (2 packages) + append guard, scoping the container gate's package set
- `verify/container-run.sh` - detached container lifecycle (run -d + cidfile + bounded wait + stop/kill/verify + trap), raised `CONTAINER_TIMEOUT`, defensive duplicate-`overall=` write guard
- `.planning/phases/22-fresh-install-proof/22-REBASELINE.md` - full re-run record: run identity, verdict, harness health, step ledger, theme-doctor inventory, baseline-vs-rerun comparison, checkpoint resolution, T-22-01-DOS closure
- `.planning/phases/22-fresh-install-proof/baseline-evidence/rerun-summary.log` - verbatim copy of the re-run's machine-readable summary
- `.planning/phases/22-fresh-install-proof/baseline-evidence/05-theme-doctor.log` - verbatim copy of the re-run's full theme-doctor output (574 checks)

## Decisions Made

- **Operator decision at the Task 3 blocking checkpoint: `proceed-to-04`.** The re-run resolved to world 1 (the gate reached a verdict, `overall=PASS`) — RETIRE-09's container-tier question is answered on evidence, plan 22-04 is unblocked with its D-22-09 input, and no harness-repair round or rescope is needed.
- **T-22-01-DOS marked CLOSED**, superseded by T-22-07-DOS. At the time T-22-07-DOS was written into the threat register (Task 2), the mitigation was verified only on throwaway containers. This plan's Task 3 re-run is the production proof: exactly one `overall=` line, no orphaned container confirmed via `podman ps -a` after a real 125-package install + stow + theme-doctor + theme-parity run.
- **RETIRE-09 deliberately NOT marked complete** (`requirements-completed: []`), per explicit operator instruction. The container tier passed, but the requirement also needs the graphical VM tier (plan 22-06) and its human verdict — matching the precedent plans 22-01, 22-08 and 22-09 already set of declining to mark it early.
- **The theme-doctor allowlist derivation is NOT performed here.** The three failures (`gsettings gtk-theme`, `walker process running`, `elephant process running`) are handed to plan 22-04 verbatim with the structural-reason column empty, per D-22-09's requirement that the allowlist be justified from `theme-doctor`'s own source — that justification work belongs to 22-04, not this plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Synchronous foreground `timeout ... podman wait` defers bash's own trap execution on interrupt**
- **Found during:** Task 2's own live-demonstration verify step, before trusting the mechanism against the real gate
- **Issue:** The first working version of the stop/wait mechanism used `timeout "$CONTAINER_TIMEOUT" podman wait "$CID"` as a synchronous foreground command inside a command substitution. Live-testing the interrupt path (a self-delivered SIGINT, the faithful proxy for a real terminal Ctrl-C) showed the cleanup trap did not fire promptly: GNU `timeout` isolates its child into a new process group by default (its own `--foreground` flag exists specifically to opt out of that isolation), so a signal delivered to the script's own process/group never reaches the `podman wait` child at all — and bash additionally defers running a trap for a signal received while blocked on a synchronous foreground external command until that command exits. Combined, an operator's Ctrl-C during the wait would have left the container running, unbounded, until the full budget elapsed — reproducing the exact defect class this task exists to close, in a new costume.
- **Fix:** Restructured to background the `timeout ... podman wait` job and block on bash's own `wait "$WAIT_PID"` builtin instead, which returns immediately when a trapped signal arrives (documented bash behavior). Container cleanup (`podman rm -f "$cid"` in the trap) does not depend on the backgrounded wait job's own state — it operates on the container directly.
- **Files modified:** `verify/container-run.sh`
- **Verification:** Re-demonstrated live: self-delivered SIGINT against a 120s budget fired the trap at +3s (not +120s); container confirmed removed via `podman ps -a` after full script exit.
- **Committed in:** `e907f44` (Task 2 commit — found and fixed before the commit, not as a follow-up)

**2. [Rule 3 - Blocking] Suppressed a shellcheck SC2329 false positive on the trap-invoked cleanup function**
- **Found during:** Task 2's shellcheck-no-new-findings verify step
- **Issue:** shellcheck's SC2329 ("This function is never invoked") fired on `cleanup_container()`, even though it is invoked indirectly via `trap cleanup_container EXIT INT TERM` — shellcheck's static analysis does not attribute a bare `trap FUNC ...` argument as an invocation in this shape (confirmed via isolated minimal reproductions; the message's own wording, "or ignored if invoked indirectly," anticipates this class).
- **Fix:** Added an inline `# shellcheck disable=SC2329` directive immediately above the function definition, with a comment stating why.
- **Files modified:** `verify/container-run.sh`
- **Verification:** `shellcheck verify/container-run.sh` vs. `origin/main`'s version: zero new findings (the only diff line is the temp-file path in shellcheck's own header text).
- **Committed in:** `e907f44` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 Rule 1 - bug found via live testing before it could reach production, 1 Rule 3 - blocking tooling false-positive).
**Impact on plan:** Both fixes strengthened Task 2's own deliverable before it was trusted against the real gate; no scope creep, no fix applied outside `verify/container-run.sh`.

## Issues Encountered

- **Mid-plan interruption between Tasks 2 and 3:** the coordinator paused this plan's execution to land the concurrent plan 22-09 speedup (icon-theme package scope cut + host cache mounting) before Task 3's re-run, so the re-run would benefit from both this plan's harness repair and 22-09's speedup in one measurement. Resumed cleanly — Task 2's mechanism (verified via `git diff`, `bash -n`, `grep`) was confirmed intact and unaltered by 22-09's changes before Task 3 launched.
- **The container gate's stdout buffering meant no live progress was visible in the harness's own stdout log during either run** — liveness was judged instead by `03-install.log`'s growing byte size and, once, by `podman top` showing genuine CPU activity (`makepkg`/`fakeroot`/`find` mid-tidy on a large icon-theme package) during an 8-minute stall in log growth on the first (pre-22-09) attempt. Not a defect — a documented judgment call, not an assumption.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Plan 22-04 is unblocked**: `.planning/phases/22-fresh-install-proof/22-REBASELINE.md`'s theme-doctor failure inventory (3 entries, structural-reason column empty) is the D-22-09 input it was blocked on. Do not re-derive it from a different run — this is the measured, current one.
- **Plan 22-05's fix-and-re-run loop** has, for the first time, evidence that the green path is reachable and clean at the container tier — `overall=PASS` with zero repository-caused failures at `install`/`stow`/`theme-parity`. Its remaining scope narrows to whatever plan 22-04's allowlist derivation surfaces as genuinely structural vs. a real defect.
- **Plan 22-06's graphical VM tier** remains the outstanding half of RETIRE-09 — this plan proved the container tier only, deliberately not marking the requirement complete.
- **No blockers for the rest of the wave graph.** `verify/container-run.sh` and `install.sh` are both stable, pushed to `origin/main`, and confirmed clean (`podman ps -a` empty, working tree clean).

---
*Phase: 22-fresh-install-proof*
*Completed: 2026-08-17*

## Self-Check: PASSED

All 5 claimed files verified present on disk; all 3 task commits (`dbe25e7`, `e907f44`, `4d2d387`) verified present in `git log --oneline --all`.
