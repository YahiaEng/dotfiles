# Phase 22 Baseline: Unmodified Container Gate vs Today's `origin/main`

**Purpose (D-22-12):** the phase's opening measurement, not a change. Run
`verify/container-run.sh` exactly as it stands, against the repository exactly
as it stands, and record what it says — before touching a line of the
harness. This document is that record.

## Run identity

- Run directory: `verify/logs/run-20260816T191755Z/`
- `git rev-parse HEAD` at run start: `9169785f8c44b7c4fe04e8d303ffe91bd5f25fa0`
- `HEAD` == `origin/main` at run start: confirmed (both resolved to the same
  SHA before the run was launched; re-confirmed identical after the run
  completed — nothing was pushed while the run was in flight).
- Working tree at run start: clean (`git status --porcelain` empty). One
  pre-existing uncommitted `.planning/STATE.md` bookkeeping edit — orchestrator
  phase-transition metadata (casing, timestamp, position), unrelated to
  anything the harness clones or tests — was committed and pushed immediately
  before the precondition check so the letter of the "clean tree, HEAD ==
  origin/main" precondition held; see `9169785` in git log.
- `verify/container-run.sh` was invoked with **no flags**, **no edits**, and
  **no `CONTAINER_TIMEOUT` override**. `git diff --quiet origin/main --
  verify/container-run.sh` exits 0 — byte-identical to `origin/main`
  throughout.

## Verdict

**`overall=FAIL`, for two independent, non-overlapping reasons — one about
the harness's own timeout mechanism, one about a real, pre-existing AUR
package build failure inside the container.** Neither reason is caused by
the five stow-package deletions this milestone made (waybar, swaync,
swayosd, wleave, ags). The run is **inconclusive** on RETIRE-09's actual
question — whether the deletions broke fresh-install reproduction — because
it never got far enough to test that; it failed for reasons that would have
failed identically on the pre-migration `origin/main` from 2026-07-09.

`summary.log`'s full contents (5 `step=` lines, 2 `overall=` lines — see
"Harness health" below for why there are two):

```
# container-run summary — 20260816T191755Z
step=pull status=ok
step=bootstrap status=ok
step=clone status=ok
step=container-run status=timeout after=3600s
overall=FAIL
step=install status=fail
overall=FAIL
```

- Harness (host-side `verify/container-run.sh`) exit code: **1**.
- Printed `Reason:` line: `container run exceeded 3600s and was killed
  (timeout) — check the last-running step's log in
  /home/aorus/dotfiles/verify/logs/run-20260816T191755Z/`
- `container-run.sh:277`'s rc/summary-mismatch branch was not the path taken
  here — the mismatch that actually happened is more unusual than that branch
  anticipates and is described in full under "Harness health."

**Plain-sentence answer:** on this run's evidence, the five package
deletions did **not** demonstrably break fresh-install reproduction — the
run never reached a step that could have shown that. It failed at
`install.sh --core-only`, on an AUR package (`limine-dracut-support`) that
has been in `install.sh` since 2026-03-14 (`git blame install.sh:324` →
commit `95bb86a4`), five months before this milestone's retirement work and
entirely unrelated to any of the five deleted packages. The actual failure
is a Gradle/Java toolchain mismatch inside the container image (see "Defects
surfaced"), not a symptom of the migration.

## Harness health

**No — the harness does not reliably complete within its own 3600s budget,
and a second, more serious defect was found alongside that: the timeout
wrapper's kill does not actually stop the container.**

Two distinct things happened, discovered in this order:

1. **The 3600s budget was exceeded during genuine forward progress**, not a
   hang. `container-run.sh:241`'s `timeout --kill-after=30 3600 podman run
   ...` fired at the budget (SIGTERM, escalating to SIGKILL 30s later per the
   host's own stdout: `` verify/container-run.sh: line 247: 133168 Killed
   timeout --kill-after=30 "$CONTAINER_TIMEOUT" podman run ... ``). At that
   moment `03-install.log` was still actively growing — `paru` was mid-batch
   through a 32-package AUR list (`matugen-bin`, `walker`, five `elephant-*`
   providers, `octopi`, `tela-icon-theme`, `colloid-icon-theme-git`,
   `heroic-games-launcher-bin`, and 20+ more). This class of AUR batch (a
   from-source C++/Qt build for `octopi`, a full Electron app in
   `heroic-games-launcher-bin`, several icon-theme git builds) plausibly
   exceeds an hour on a first, cold-cache run — this is evidence the
   **budget is undersized for this package set**, not that anything hung.

2. **A second, independent defect: the outer `timeout`'s SIGKILL only killed
   the host-side `podman run` client process (PID 133168) — it did not stop
   the actual container.** Verified directly, after the host-side
   `container-run.sh` had already printed its FAIL verdict and exited:
   `podman ps -a` showed container `197980ef926b` still `Up About an hour`;
   `podman top` showed the in-container `paru` process (PID 14595) still
   running, 54+ minutes elapsed, actively building further AUR packages
   (`limine-dracut-support`, `vscodium-bin`, `zen-browser-bin`, `spotify`,
   `discord`, `1password`, ... continuing down the same 32-package list).
   `podman inspect` confirmed `running=true` a full **~3 minutes after** the
   host wrapper had exited with `overall=FAIL`/rc 1. The container was left
   running, unbounded, consuming host CPU/network/disk with no supervision —
   under rootless podman, SIGKILL to the attached `podman run` client detaches
   the CLI but does not propagate to the conmon-owned container process. This
   falsifies this plan's own threat-model line for T-22-01-DOS ("Existing
   `timeout --kill-after=30 "$CONTAINER_TIMEOUT"` wrapper
   (`container-run.sh:241`) bounds the whole run") — it bounds the **host-side
   wrapper's own exit**, not the containerized workload.
   - The orphaned container was **not** left running after being found: it
     was observed continuing to make forward progress on its own for a few
     more minutes, then self-terminated (the `--rm` flag auto-removed it) once
     `install.sh --core-only` reached its own natural failure — the real AUR
     build error under "Defects surfaced" below. That is what produced the
     *second* `step=install status=fail` / `overall=FAIL` pair appended to
     `summary.log` after the first, host-written `overall=FAIL` — two
     different processes (the outer wrapper, then the still-running
     in-container script) each wrote their own verdict to the same file,
     independently, minutes apart. By the time this was checked again to stop
     it manually, `podman ps -a` was already empty — the container had exited
     and self-removed on its own between two checks 18 seconds apart.
   - **Compared against the recorded history:** the last `overall=PASS` was
     `run-20260709T060703Z` (2026-07-09). Four later runs
     (`run-20260711T175822Z`, `run-20260714T102234Z`, and two more on
     2026-07-14) recorded no verdict at all, the last stopping after
     `step=clone status=ok` with nothing further written. Today's run does
     **not** reproduce that exact silent-death pattern — it got further
     (`clone` → into `install`, and the in-container script itself did
     eventually reach and write its own verdict, just very late and racing
     the host's own premature one). But it confirms the same underlying
     symptom family: **the harness, unmodified, does not deliver a clean
     single verdict within its stated budget**, for a materially different
     and newly-discovered reason (timeout-kill not reaching the container)
     than whatever silently killed the four July runs at `clone`.

## Step ledger

| Step token | Status | Notes |
|---|---|---|
| `step=pull` | `ok` | `podman pull docker.io/archlinux/archlinux:latest` succeeded. |
| `step=bootstrap` | `ok` | `pacman -Sy --noconfirm --needed git base-devel sudo` succeeded. |
| `step=clone` | `ok` | `git clone --depth 1` of the real remote (D-56) succeeded. |
| `step=container-run` | `timeout after=3600s` | Host-side `timeout` wrapper expired; SIGKILLed the `podman run` client. Written by the **host-side** script. |
| *(host-written)* `overall=FAIL` | — | Written immediately after the timeout line, by the host script, before it exits. |
| `step=install` | `fail` | Written **later**, by the **in-container** script itself, once `install.sh --core-only` reached its own genuine failure (see below) — several minutes after the host script had already exited. |
| *(in-container-written)* `overall=FAIL` | — | Written by `container-script.sh`'s own closing verdict block, independently of the host's earlier line. |
| `step=stow` | *(absent)* | Never reached in either the host's or the container's own accounting. |
| `step=theme-doctor` | *(absent)* | Never reached — no `05-theme-doctor.log` was produced. |
| `step=theme-parity` | *(absent)* | Never reached. |

5 `step=` lines total (`grep -c '^step=' summary.log` → 5), 2 `overall=` lines
(both `FAIL`) — see "Harness health" for why there are two.

## theme-doctor failure inventory (D-22-09 input)

**Not available. This run produced no `05-theme-doctor.log` at all** — the
container never got past `install.sh --core-only` in either the host's
timeout-truncated view or the in-container script's own eventual conclusion.
`theme-doctor` runs only after `stow.sh`, which never ran.

D-22-09 requires this failure list, measured, as the **only** admissible
input for deriving plan 22-04's session-failure allowlist. That input does
not exist yet. **Nothing is substituted for it here** — not the pre-migration
`run-20260709T060703Z` list (20 passed / 3 failed), not an inferred or
guessed list. Per the plan's own prohibition, no such list is fabricated.
**Plan 22-04 is blocked** until a run reaches `step=theme-doctor` and produces
a real, current log.

| # | `[FAIL]` description | structural reason (to be justified from theme-doctor source in 22-04) |
|---|---|---|
| — | *(no data — theme-doctor did not run)* | |

## Defects surfaced

| # | Failing step | Log | Actual failing line(s), verbatim |
|---|---|---|---|
| 1 | `install.sh --core-only` (`step=install`) | `03-install.log:13056-13064` (build attempt at `03-install.log:13032` onward) | `FAILURE: Build failed with an exception.` / `* What went wrong:` / `A problem occurred configuring root project 'limine-entry-tool'.` / `> Cannot find module 'gradle-public-api-legacy' in distribution directory '/usr/share/java/gradle'.` / `==> ERROR: A failure occurred in build().` / `Aborting...` / `error: failed to build 'limine-dracut-support-1.37.1-1': ` — followed at `03-install.log:17967` by paru's aggregate `error: packages failed to build: limine-dracut-support-1.37.1-1` after it finished the remaining packages in the batch. |
| 2 | harness timeout mechanism (`step=container-run`) | host stdout (captured verbatim, see "Harness health") | `` verify/container-run.sh: line 247: 133168 Killed                     timeout --kill-after=30 "$CONTAINER_TIMEOUT" podman run --rm -v "$LOG_DIR:/logs:Z" "$IMAGE" bash /logs/container-script.sh `` — the container it was supposed to stop (`197980ef926b`) was independently confirmed via `podman ps -a`/`podman top`/`podman inspect` still `running=true` for several minutes after this line printed. |

**Attribution:** Defect 1 (`limine-dracut-support` / Gradle) is a real,
present-day fresh-install blocker, but `git blame install.sh:324` (commit
`95bb86a4`, 2026-03-14) shows it predates this milestone's retirement work by
five months and has nothing to do with any of the five deleted packages —
its most likely cause is upstream drift between the PKGBUILD's Gradle
expectations and the Gradle version now shipped in `archlinux/archlinux:latest`,
external to this repository. Defect 2 (timeout-does-not-kill-the-container)
is a defect in `verify/container-run.sh` itself, specifically in the gap
between "the host-side `timeout` wrapper expires" and "the containerized
workload is actually stopped" — it is not touched or modified by this plan
per D-22-12's prohibition, only measured and recorded.

Neither defect demonstrates or refutes whether the five stow-package
deletions broke fresh-install reproduction. **That question remains
untested** — the run never got past `install.sh --core-only`, and even
`install.sh --core-only` itself never got as far as the deletions could have
mattered (they affect `stow.sh`'s `PACKAGES` array and later steps, not the
`AUR_PKGS` list `limine-dracut-support` sits in).

## Not done here

Nothing was fixed, nothing was pushed, and `verify/container-run.sh` was not
modified — confirmed by `git diff --quiet origin/main -- verify/
install.sh stow.sh theme-engine/ hypr/` exiting 0 for every path except the
newly-created files this baseline plan is scoped to add under
`.planning/phases/22-fresh-install-proof/`. The one exception to strict
non-intervention: the orphaned container left running by Defect 2 was
manually stopped after its evidence was fully captured (`podman kill`/`podman
rm -f` attempted, though it had already self-terminated by the time the
command ran) — this is host-resource cleanup of a runaway process this
measurement itself created, not a change to any tracked file or to the
harness's behavior, and it happened only after every fact recorded above was
already captured.
