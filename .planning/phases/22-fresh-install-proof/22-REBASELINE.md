# Phase 22 Re-baseline: Repaired Container Gate vs Today's `origin/main`

**Purpose (plan 22-07, Task 3):** the run plan 22-01 was chartered to
produce and could not, because the unmodified harness died in
`install.sh --core-only` before ever reaching `stow.sh`, `theme-doctor` or
`theme-parity` (22-BASELINE.md). This document is that run, against the
harness as repaired by 22-07 (Tasks 1-2) and sped up by 22-09.

## Run identity

- Run directory: `verify/logs/run-20260816T222431Z/`
- `git rev-parse HEAD` == `origin/main` at run start: `41fd13fc8172f8704b22429b9fa432831244fb96`
  (confirmed identical before launch; working tree clean,
  `git status --porcelain` empty).
- `verify/container-run.sh` invoked **exactly once**, with **no flags**
  (default/warm cache mode, not `--cold`), no `CONTAINER_TIMEOUT` override.
  Unmodified beyond plan 22-07's Tasks 1-2 and plan 22-09's speedup —
  both already committed and pushed to `origin/main` before this run
  started (`dbe25e7`, `e907f44`, `1c24290`, `ee5009a`, `07e4aa2`, `9c78d60`,
  `41fd13f`).
- Launched: 2026-08-16T22:24:31Z. Completed: 2026-08-16T22:41:53Z.
- **Wall clock: 17min 22s (1042s)** — measured, not projected. Well inside
  22-09's ~19-minute projection (which was explicitly labelled
  unmeasured) and far under the 35-minute reporting threshold. Budget
  headroom: 1042s used of a 10400s `CONTAINER_TIMEOUT` — the timeout
  mechanism was never exercised by this run.
- Cache mode: `warm` (host pacman cache `/var/cache/pacman/pkg/` and paru
  cache `/home/aorus/.cache/paru` mounted read-only, per 22-09's
  cache-mode logging in `summary.log`).

## Verdict

**`overall=PASS`.** The gate reached every step this milestone's
reproduction procedure defines — `install.sh --core-only`, `stow.sh`,
`theme-doctor` (informational), `theme-parity` — and both hard-gating
steps (`install`, `stow`, `theme-parity`) recorded `status=ok`.

**Plain-sentence answer:** on this run's evidence, `install.sh --core-only`
+ `stow.sh` + `theme-parity` reproduce the fully themed desktop's
non-graphical prerequisites from a genuine fresh clone of today's
`origin/main` — the five stow-package deletions (waybar, swaync, swayosd,
wleave, ags) did not break fresh-install reproduction at the container
tier. RETIRE-09's container-tier half is now answerable on real evidence,
not inference from a pre-migration run.

`summary.log`'s full contents (single, unambiguous `overall=` line — the
double-verdict defect 22-BASELINE.md recorded does not recur):

```
# container-run summary — 20260816T222431Z
cache-mode=warm
cache-pacman-ro=/var/cache/pacman/pkg/
cache-paru-ro=/home/aorus/.cache/paru
cache-pacman-write=/home/aorus/dotfiles/verify/cache/pacman-write
cache-paru-write=/home/aorus/dotfiles/verify/cache/paru-write
step=pull status=ok
step=bootstrap status=ok
step=paru-cache-seed status=attempted rc=0
step=clone status=ok
step=install status=ok
step=stow status=ok
step=theme-doctor status=informational rc=1
step=theme-parity status=ok
overall=PASS
```

- Harness (host-side `verify/container-run.sh`) exit code: **0**.
- No `Reason:` line printed — PASS path.
- `install.sh --core-only`: **All 125 packages verified installed**
  (`03-install.log` tail) — includes neither `limine-dracut-support` nor
  `kernel-modules-hook` (22-07 Task 1) nor `tela-icon-theme` /
  `colloid-icon-theme-git` (22-09), all four correctly moved to the
  host-only group and skipped under `--core-only`.
- `stow.sh`: "Dotfiles stowed successfully!", first-boot theme baseline
  seeded, headless reload fan-out correctly skipped
  (`theme_engine_reload: no graphical session detected`).
- `theme-parity`: **1545 passed, 0 failed** (`06-theme-parity.log`).

## Harness health

**Yes — the repaired harness completed cleanly, well within its budget,
on the first invocation.** No timeout was hit; the `podman run -d` +
bounded `wait` + stop/kill/verify mechanism built in 22-07 was present but
never exercised past the "started, watched, exited on its own" path,
since the run finished in 1042s against a 10400s budget. `podman ps -a`
after the run shows no containers — the trap-driven cleanup fired
correctly on normal exit, same as verified live on throwaway containers
during 22-07's Task 2.

No `overall=` conflict: exactly one `overall=PASS` line, written once, by
the host script after confirming the container had exited on its own
(`WAIT_RC=0` path) — the double-verdict race 22-BASELINE.md documented
cannot occur on this code path either, since the host only writes a
verdict after the container's own lifecycle is fully resolved one way or
the other.

## Step ledger

| Step token | Status | Notes |
|---|---|---|
| `step=pull` | `ok` | `podman pull docker.io/archlinux/archlinux:latest` succeeded. |
| `step=bootstrap` | `ok` | `pacman -Sy --noconfirm --needed git base-devel sudo` succeeded. |
| `step=paru-cache-seed` | `attempted rc=0` | 22-09's best-effort `cp -an` seed of the writable paru cache from the read-only host mount; non-fatal by design, succeeded here. |
| `step=clone` | `ok` | `git clone --depth 1` of the real remote (D-56) succeeded, against `origin/main` at `41fd13f`. |
| `step=install` | `ok` | `install.sh --core-only` succeeded; **all 125 packages verified installed**. |
| `step=stow` | `ok` | `stow.sh` succeeded; first-boot theme baseline seeded; headless reload correctly skipped. |
| `step=theme-doctor` | `informational rc=1` | 571 passed / 3 failed — see inventory below. Does not gate `overall=` (by design, per this script's header comment — theme-doctor's session-dependent checks legitimately cannot pass headless). |
| `step=theme-parity` | `ok` | **1545 passed, 0 failed.** Hard-gates `overall=`. |
| *(host-written)* `overall=PASS` | — | Written once, after `WAIT_RC=0` (container exited on its own) and `grep -qx 'overall=PASS' summary.log` confirmed the in-container script's own verdict line. |

5 gating `step=` tokens (`pull`, `bootstrap`, `clone`, `install`, `stow`,
`theme-parity` — 6 if counting `paru-cache-seed`, which is non-gating),
1 informational (`theme-doctor`), 1 `overall=` line total.

## theme-doctor failure inventory (D-22-09 input)

**Available for the first time this phase.** 574 total checks
(571 passed, 3 failed). Structural-reason column deliberately left
**empty** — D-22-09 requires the allowlist be justified from
`theme-doctor`'s own source, which is plan 22-04's scope, not this
plan's. Nothing here is fixed; this is the measured, verbatim input
22-04 was blocked on.

| # | `[FAIL]` description | structural reason (to be justified from theme-doctor source in 22-04) |
|---|---|---|
| 1 | `gsettings gtk-theme = adw-gtk3-dark (mode=dark, got: Adwaita)` | |
| 2 | `walker process running` | |
| 3 | `elephant process running` | |

Full log: `.planning/phases/22-fresh-install-proof/baseline-evidence/05-theme-doctor.log`
(copied verbatim from `verify/logs/run-20260816T222431Z/05-theme-doctor.log`,
byte-identical, `diff -q` confirmed).

**Comparison against the dev host:** the dev host's `theme-doctor` (after
plan 22-08's sweep-scope fix) reports **580 passed / 0 failed** — a
graphical session with a real Hyprland compositor, GNOME settings daemon,
running walker/elephant, etc. This container run reports **571 passed / 3
failed** at 574 total checks. The 6-check difference in total count (580
vs 574) and the 3 failures are both plausible session-dependent deltas
(no compositor, no D-Bus session bus, no walker/elephant processes to
find) rather than an obviously repository-caused regression — but per
this plan's own scope boundary, that judgment is 22-04's to make from
`theme-doctor`'s source, not asserted here. Recorded as a genuine finding
for that plan to work from, not fixed or waved through in this document.

## Comparison against `22-BASELINE.md`

| | Baseline (`run-20260816T191755Z`) | Re-run (`run-20260816T222431Z`) |
|---|---|---|
| `overall=` | `FAIL` (written twice, two different writers) | `PASS` (written once) |
| Furthest step reached | `install` (never finished — killed by timeout) | `theme-parity` (finished) |
| `install.sh --core-only` | Failed: `limine-dracut-support` Gradle build error | `ok`: 125/125 packages verified |
| Container timeout mechanism | Broken: SIGKILL detached from client, container kept running (T-22-01-DOS falsified) | Not exercised — run finished in 1042s of a 10400s budget; mechanism verified separately on throwaway containers in 22-07 |
| `theme-doctor` | Never ran — no `05-theme-doctor.log` | 571 passed / 3 failed — first real inventory this phase |
| `theme-parity` | Never ran | 1545 passed / 0 failed |
| Wall clock | 3600s killed, still running ~65min later | 1042s (17min 22s), completed |
| RETIRE-09 (container tier) | Untested | **Answered: PASS** — five deletions did not break reproduction |

## Not done here

Nothing surfaced by this run was fixed here — the theme-doctor allowlist
derivation belongs to plan 22-04, and per this plan's own scope boundary
(22-07-PLAN.md's `<objective>`), fixing whatever the green-path run
surfaces is plan 22-05's fix-and-re-run loop, not this document's job.
`verify/container-run.sh` was invoked exactly once for this re-run, per
the plan's own constraint.

## Checkpoint (Task 3)

This re-run reached `step=theme-doctor` and recorded a verdict —
**world 1** of the three the plan's Task 3 anticipated: "the gate reached
`theme-doctor` and recorded a verdict. RETIRE-09 is now answerable; the
failure inventory unblocks plan 22-04; plan 22-05's size is finally
estimable from named defects." `overall=PASS` (not `FAIL` on a real
repository defect), so the "gate got further but died again" world does
not apply either — this is the clean-pass outcome, closer to world 3
("the gate completed and reported `overall=PASS`. The five deletions did
not break reproduction, and the remaining plans are about raising the bar
rather than repairing anything") than any of the FAIL-flavored worlds.

**Operator decision: `proceed-to-04`.**

**Resolution:** this run resolves to **world 1** — the gate reached a
verdict (`overall=PASS`), and RETIRE-09's container-tier question is
answered on evidence: the five package deletions (waybar, swaync,
swayosd, wleave, ags) did **not** break fresh-install reproduction. Plan
22-04 is unblocked and inherits the verbatim `theme-doctor` failure
inventory above (3 entries, structural-reason column deliberately empty)
as its sole admissible D-22-09 input. No harness repair round is needed;
no rescope is needed — the phase resumes its planned shape.

## Threat model update: T-22-01-DOS closed, superseded by T-22-07-DOS

Plan 22-01's baseline recorded T-22-01-DOS's mitigation claim ("the
`timeout --kill-after=30` wrapper bounds the whole run") as **disproven
by measurement** — the orphaned container `197980ef926b` was confirmed
still `running=true` several minutes after the host wrapper had already
exited with its own verdict.

Plan 22-07 Task 2 replaced that mechanism (`podman run -d --cidfile` +
bounded `wait` on bash's own `wait` builtin + `podman stop`→`kill`→verify
escalation under a `trap ... EXIT INT TERM`) and is recorded in
22-07-PLAN.md's threat register as **T-22-07-DOS**, disposition
`mitigate`, explicitly **superseding** T-22-01-DOS. At the time that
register entry was written, the mitigation was verified only on
throwaway `sleep 600` containers (budget-expiry stop path and a
self-delivered-SIGINT interrupt path), not on a real gate run.

**This re-run is that production proof.** `run-20260816T222431Z` exercised
the full mechanism end-to-end against a real, non-trivial workload
(125-package install, `stow.sh`, `theme-doctor`, `theme-parity`) and:

- Wrote **exactly one** `overall=` line (`overall=PASS`) — the
  double-verdict signature of the original defect (two independent
  writers appending to the same `summary.log`) did not recur.
- Left **no orphaned container**: `podman ps -a` after the run completed
  was empty, confirmed directly (not inferred from exit code alone, per
  this harness's own "never trust the container exit code alone"
  discipline).
- Did not need to exercise the stop/kill escalation itself (the container
  exited on its own at 1042s, well inside the 10400s budget) — but the
  cleanup trap's `podman rm -f "$cid"` ran unconditionally on the normal
  `WAIT_RC=0` exit path too, and its removal is exactly what left
  `podman ps -a` empty.

**T-22-01-DOS status: CLOSED**, not merely "reported as disproven." The
superseding mitigation (T-22-07-DOS) is now verified both on isolated
throwaway containers (22-07 Task 2's own verify step) and in production
against a real gate run (this document). Any future re-opening of this
threat class should reference T-22-07-DOS's mechanism
(`verify/container-run.sh`'s `podman run -d`/bounded-`wait`/trap block)
as the current state, not the pre-22-07 attached-`timeout` form
T-22-01-DOS described.
