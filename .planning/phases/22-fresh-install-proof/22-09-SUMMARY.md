---
phase: 22-fresh-install-proof
plan: 09
subsystem: infra
tags: [install.sh, podman, container-run, pacman, paru, caching, aur]

requires:
  - phase: 22-07
    provides: AUR_PKGS_HOST group (dbe25e7), detached-container/owned-CID/stop-with-trap mechanism (e907f44), CONTAINER_TIMEOUT=10400s
provides:
  - install.sh with tela-icon-theme + colloid-icon-theme-git moved into AUR_PKGS_HOST (skipped under --core-only, still installed by default)
  - verify/container-run.sh --cold flag and read-only host-cache mounts (pacman + paru), with a persistent gitignored writable pair under verify/cache/
  - measured before-figure + deterministic Task-1 saving + explicitly-unmeasured Task-2 projection, ready for 22-07's task 3 re-run to produce the real verdict
affects: [22-07]

actuals:
  tokens: 3512
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "pacman.conf multi-CacheDir (read-only host mirror first, writable second) for native read-then-write cache reuse without touching pacman itself"
    - "cp -an best-effort skip-existing seed for a cache with no native multi-dir read mechanism (paru), pointed at via XDG_CACHE_HOME"
    - "self-detecting container-side cache setup ([[ -d /caches/... ]]) rather than coupling to an expanded host variable, preserving the single-quoted heredoc's host/container variable isolation"

key-files:
  created: []
  modified:
    - install.sh
    - verify/container-run.sh
    - .gitignore

key-decisions:
  - "tela-icon-theme and colloid-icon-theme-git moved to AUR_PKGS_HOST (host-only), not deleted — a default (no-flag) install.sh run still installs both; only the container-gate scope changed"
  - "papirus-folders stays in AUR_PKGS core — pairs with the already-core papirus-icon-theme pacman package, so --core-only keeps a real installed icon theme present"
  - "pacman cache reuse via native multi-CacheDir; paru cache reuse via a best-effort cp -an seed + XDG_CACHE_HOME repoint, since paru has no pacman-style multi-directory read mechanism and its clone dir must stay writable for -git packages' pkgver()"
  - "chown -R builder:builder on the writable cache mounts, found live-necessary: builder (a subordinate-range uid under rootless podman) has no write access to a host-mounted directory owned by the container's mapped root without it"

patterns-established:
  - "Any future host-cache-reuse addition to container-run.sh should self-detect via [[ -d /caches/... ]] inside the single-quoted heredoc, never via an expanded host variable"

requirements-completed: []  # RETIRE-09 intentionally NOT marked complete here — corrected post-hoc; the original [RETIRE-09] was a slip inconsistent with every sibling plan in this phase. This plan is a performance change to the gate (scope cut + cache mounts); it produced no verdict at all. RETIRE-09 closes only in 22-06, on both tiers passing.

coverage:
  - id: D1
    description: "tela-icon-theme and colloid-icon-theme-git moved out of --core-only scope (43min deterministic saving), papirus-folders confirmed to remain, retirement-check clean"
    requirement: "RETIRE-09"
    verification:
      - kind: other
        ref: "bash -n install.sh; python3 array-extraction diff of CORE_ONLY=true (27 pkgs, neither icon theme) vs CORE_ONLY=false (31 pkgs, both present); retirement-check --all (8/8 summaries failed_classes=0, exit 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "verify/container-run.sh mounts host pacman/paru caches read-only with a --cold escape hatch, writable host-persisted overlay, and per-run cache-mode logging"
    requirement: "RETIRE-09"
    verification:
      - kind: other
        ref: "bash -n + shellcheck (0 new findings vs origin/main, same pre-existing SC2034); sourced variable-construction probe (--cold => 0 mount args, default => 8); throwaway podman container: write to both RO mounts rejected as root AND builder, builder read of a real cached package file byte-identical to host's own read (165934 bytes), builder read of a real paru clone dir listing; host caches confirmed byte-unchanged via du -sh before/after (23G / 8.4G, no stray files)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Actual post-change container-gate wall-clock (the real before/after number)"
    verification: []
    human_judgment: true
    rationale: "This plan explicitly does not run the full gate (D-22-12/plan scope: that is 22-07's task 3, dispatched next). The wall-clock improvement is a labelled projection in this SUMMARY, not a measurement — a human/orchestrator must treat 22-07's task 3 re-run as the source of truth, not this document."

duration: 20min
completed: 2026-08-16
status: complete
---

# Phase 22 Plan 09: Container-Gate Scope Cut + Host Cache Reuse Summary

**Moved the two 21/22-minute icon-theme AUR builds out of `--core-only` scope (43 deterministic minutes gone) and added read-only host-cache mounts with a `--cold` escape hatch to `verify/container-run.sh` — the actual post-change wall-clock stays unmeasured until 22-07's task 3 re-run.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-08-16T22:09:13Z
- **Completed:** 2026-08-16T22:21:08Z
- **Tasks:** 3
- **Files modified:** 3 (`install.sh`, `verify/container-run.sh`, `.gitignore`)

## Accomplishments

- `tela-icon-theme` and `colloid-icon-theme-git` moved from `AUR_PKGS` into the existing `AUR_PKGS_HOST` group (dbe25e7's structure) — skipped under `--core-only`, still installed by a default run. `papirus-folders` deliberately stays in the core set.
- `verify/container-run.sh` gained a `--cold` flag (mounts nothing, byte-for-byte today's behaviour) and, by default, read-only mounts of the host's real pacman (`/var/cache/pacman/pkg`, resolved via `pacman-conf CacheDir`) and paru (`${XDG_CACHE_HOME:-$HOME/.cache}/paru`) caches, plus a persistent, gitignored, container-writable pair under `verify/cache/`.
- Every run now logs `cache-mode=` and, when warm, all four `cache-*=` paths into `summary.log` — a fast cached run can never later be mistaken for a full cold proof.
- A real permission bug (`builder`'s subordinate uid has no write access to the host-mounted writable cache dirs) was found live via a throwaway container before it could break the actual gate, and fixed with a `chown -R builder:builder` right after `useradd`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Move the two heavy icon-theme packages out of `--core-only` scope** - `1c24290` (perf)
2. **Task 2: Mount host package caches read-only, with a `--cold` escape hatch** - `ee5009a` (perf)
3. **Task 3: Measure the improvement and record it** - (this commit, docs)

**Plan metadata:** plan file `07e4aa2` (docs: insert plan)

## Files Created/Modified

- `install.sh` - `tela-icon-theme`/`colloid-icon-theme-git` moved into `AUR_PKGS_HOST`, with a comment recording the measured 21min/22min build times and why the cut is safe (icon-theme-picker.sh's runtime discovery, no repo config names either theme)
- `verify/container-run.sh` - `--cold` flag/arg parsing, host cache path resolution, cache-mount-plan construction, pacman.conf `CacheDir` injection (RO host mirror + writable second entry), paru `cp -an` seed + `XDG_CACHE_HOME` repoint, `chown -R builder` fix, `cache-mode=`/`cache-*=` summary.log logging
- `.gitignore` - added `verify/cache/` (persistent, container-writable cache artifacts, never repo content)

## Decisions Made

- **pacman cache reuse via native multi-`CacheDir`, not a copy.** pacman.conf's `CacheDir` directive is consulted in the order listed and downloads to the first writable entry (pacman.conf(5)) — listing the read-only host mirror first, and a writable directory second, gets read-then-write reuse for free with zero seed cost and zero risk to the 23GB host cache.
- **paru cache reuse via a best-effort `cp -an` seed, not an OverlayFS mount.** paru has no pacman-style multi-directory read mechanism, and its clone dir must stay writable (a `-git` package's `pkgver()` needs `git pull`), so the read-only mount can't be the live directory paru writes into. A skip-existing copy (GNU coreutils, no `rsync` dependency) seeds the writable, host-persisted directory once per run; paru is then pointed at it for the whole `install.sh` invocation via `XDG_CACHE_HOME`. Considered and rejected: a kernel OverlayFS mount (RO lower + writable upper) would be the more "correct" textbook answer, but adds real complexity and privilege-mount risk under rootless podman for a plan whose own `<action>` asks for "a writable cache directory of its own," not an overlay filesystem — kept to the simpler, explicitly-asked-for shape.
- **`chown -R builder:builder` on both writable cache mounts.** Found live, not assumed: under rootless podman, the container's mapped root equals the host user, but `builder` (created via `useradd`) maps to a different, subordinate-range uid with no write access to a host-mounted directory it doesn't own. Proven to fail with `mkdir: Permission denied` before the fix, and to work (43/43 files seeded, `touch` succeeded) after it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `builder` had no write access to the host-mounted writable cache directories**
- **Found during:** Task 2, live verification with a throwaway container
- **Issue:** The writable `verify/cache/{pacman,paru}-write` mounts are host directories owned by the container's mapped root (== the host user under rootless podman). `builder` (a separate, subordinate-range uid) got "Permission denied" on `mkdir` inside them — this would have silently broken both the paru cache seed AND, more seriously, paru's actual AUR-build writes during the real gate run (paru/makepkg refuse to run as root).
- **Fix:** Added `chown -R builder:builder /caches/pacman-write /caches/paru-write` immediately after `useradd -m builder`, guarded on the mount actually being present.
- **Files modified:** `verify/container-run.sh`
- **Verification:** Re-ran the same throwaway-container test after the fix — seed copied all 43/43 files, a `touch` as `builder` into `/caches/pacman-write` succeeded. Documented the resulting `podman unshare rm -rf` cleanup requirement inline (T-22-09-DESTRUCT is unaffected — that threat covers the read-only host caches, which no in-container write can touch regardless of ownership).
- **Committed in:** `ee5009a` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug, found via live testing before it could reach the real gate)
**Impact on plan:** Necessary for Task 2's caching mechanism to actually function during a real (non-`--cold`) run. No scope creep — the fix is entirely inside `verify/container-run.sh`, the plan's own declared file.

## Issues Encountered

None beyond the deviation above — both throwaway-container test rounds (before and after the chown fix) ran cleanly, and host cache byte-counts were confirmed unchanged (`du -sh` before/after: 23G pacman / 8.4G paru, identical) after all testing.

## Timing: Measured vs Projected

**This section exists specifically to keep those two categories separate.** The phase has already been damaged once by an unmeasured claim (T-22-01-DOS) presented as a passing mitigation; nothing here repeats that.

### Measured (source: `22-BASELINE.md`, `03-install.log` timestamp diffs — the only real container-gate run this phase has produced)

| Item | Time | Source |
|---|---|---|
| `tela-icon-theme` build | 21 min | `19:36:13 → 19:57:21` |
| `colloid-icon-theme-git` build | 22 min | `19:57:21 → 20:19:30` |
| `paru` bootstrap | 7 min | `19:20:07 → 19:27:13` |
| All ~30 other AUR packages combined | ≈ 11 min | differenced `==> Making package:` timestamps |
| **Baseline total (unmodified harness, unmodified repo)** | **~62 min** | 22-BASELINE.md, stated directly as the phase's opening measurement |

`22-BASELINE.md` does **not** separately break out clone/bootstrap/stow/theme-parity wall-clock — only the AUR package-build portion was timestamp-differenced. Those other steps are real but their individual durations are not part of this plan's measured record.

### Deterministic (Task 1 — a scope cut, not a speed trick; requires no cache to be warm)

Removing `tela-icon-theme` (21 min) and `colloid-icon-theme-git` (22 min) from `--core-only` is a **guaranteed** 43-minute reduction of the baseline's AUR-build time, regardless of caching, network conditions, or whether `verify/cache/` has ever been populated — the packages simply are not built under `--core-only` any more. This holds on the very first run, cold or warm.

Applying it to the measured baseline arithmetically: `62 - 43 = 19 min` for what's left of the AUR-install-related portion (`7 min paru bootstrap + 11 min remaining AUR packages ≈ 18 min`, consistent with the ~19 min figure within the baseline's own rounding). **This 19-minute figure is an arithmetic projection built from measured sub-components, not a re-measurement of a real run** — the clone/bootstrap/stow/theme-parity overhead the baseline run also incurred (untimed individually, see above) is not included, so the real post-Task-1 total is `19 min + that untimed overhead`, not exactly 19 min.

### Explicitly UNMEASURED (Task 2 — host-cache reuse)

No full gate run happened in this plan (by design — `22-07`'s task 3 owns that). The caching mechanism was proven **correct** (mounts, permissions, `--cold` behaviour — see `## Accomplishments` and the coverage block above) but its **speed effect was never timed**. Known reasons it may be smaller than hoped, or absent entirely on a given run:

- **Cache hits key on package version.** Every remaining core AUR package except one is version-pinned, so a warm cache should, in principle, skip re-downloading/re-building an already-cached exact version — but this plan did not run a real `install.sh --core-only` inside a container to confirm that in practice.
- **The `-git` caveat has moved, not disappeared.** The context this plan inherited named `colloid-icon-theme-git`'s `pkgver()` re-resolution against upstream HEAD as the reason caching can't help a `-git` package — but `colloid-icon-theme-git` left `--core-only` scope entirely under Task 1. The same structural limitation now applies to `ttf-material-symbols-variable-git`, the one `-git` package still in the post-Task-1 core set (27 packages): its cache entry, even if present, cannot prevent a fresh clone+build check each run.
- **First-run cold-start.** `verify/cache/` starts empty. The pacman half gets an immediate benefit only if the packages needed are already present in the *developer's own* `/var/cache/pacman/pkg` (23 GB of real accumulated state, plausible for a personal dev machine) — the paru half only benefits after its `cp -an` seed step, whose own cost (copying whatever fraction of the developer's 8.4 GB paru cache is new to `verify/cache/paru-write/`) was not timed either.

**Projected post-change wall-clock (a projection, not a claim):** a **deterministic floor of ~19 min plus untimed overhead** from Task 1 alone (holds even under `--cold`, or on a first warm run with nothing pre-cached), with Task 2 potentially shrinking the `7 min` paru-bootstrap and `11 min` remaining-package figures further **if** the host's real caches already contain matching versions — by an amount this plan does not estimate, let alone measure. The only way to replace "projected" with "measured" here is 22-07's task 3 re-run, which is dispatched next and is the phase's actual verdict-producing run.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `install.sh` and `verify/container-run.sh` are ready for 22-07's task 3 re-run, which will produce the phase's real verdict and the real timing.
- `verify/cache/` starts empty on that re-run (never populated by this plan) — its first real-world benefit, if any, will show up either on that run (if the developer's own host caches already have matching packages) or on a second same-session re-run (once `verify/cache/` itself has been seeded by the first).
- No blockers. This plan's own `<verification>` items (list diffs, retirement-check, live throwaway-container proofs) are all closed; nothing here is deferred to a later plan.

---
*Phase: 22-fresh-install-proof*
*Completed: 2026-08-16*

## Self-Check: PASSED

- FOUND: install.sh
- FOUND: verify/container-run.sh
- FOUND: .gitignore
- FOUND: .planning/phases/22-fresh-install-proof/22-09-SUMMARY.md
- FOUND commit: 1c24290 (Task 1)
- FOUND commit: ee5009a (Task 2)
- FOUND commit: 9c78d60 (Task 3 / this SUMMARY)
