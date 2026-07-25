---
phase: 10-ags-media-applet
plan: 01
subsystem: infra
tags: [install.sh, cava, aylurs-gtk-shell, ags, pacman, aur, reproducibility]

# Dependency graph
requires: []
provides:
  - "install.sh declares cava (PACMAN_PKGS/official extra repo) and aylurs-gtk-shell (AUR_PKGS)"
  - "Verified working AGS v3 (3.1.0), cava (0.10.7), and gjs (1.88.1) toolchain on this host"
affects: [10-ags-media-applet, media-applet-scaffold, media-applet-backend, cava-underlay, media-applet-theming, media-applet-integration]

# Tech tracking
tech-stack:
  added: [cava 0.10.7 (official extra repo), aylurs-gtk-shell/AGS v3 3.1.0 (AUR), gjs 1.88.1 (transitive dep of aylurs-gtk-shell)]
  patterns: ["install.sh package-array registration matching existing grouping/comment conventions (Phases 6/7/8 precedent)"]

key-files:
  created: []
  modified: [install.sh]

key-decisions:
  - "Both packages were already installed and verified on this machine prior to plan execution; Task 2's install commands were correctly skipped as a verified no-op rather than re-run destructively or interactively."

patterns-established: []

requirements-completed: [MEDIA-04]

coverage:
  - id: D1
    description: "install.sh declares cava in PACMAN_PKGS and aylurs-gtk-shell in AUR_PKGS, making the AGS media applet toolchain reproducible on a fresh Arch install"
    requirement: "MEDIA-04"
    verification:
      - kind: other
        ref: "grep -nE 'cava' install.sh && grep -nE 'aylurs-gtk-shell' install.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "ags, cava, and gjs binaries are installed and runnable on this host"
    requirement: "MEDIA-04"
    verification:
      - kind: other
        ref: "ags --version && cava -v | head -1 && gjs --version"
        status: pass
    human_judgment: false

# Metrics
duration: 6min
completed: 2026-07-15
status: complete
---

# Phase 10 Plan 01: Install & Register AGS Media Applet Dependencies Summary

**Registered `cava` (official extra) and `aylurs-gtk-shell` (AUR) in install.sh's package arrays; verified all three toolchain binaries (ags 3.1.0, cava 0.10.7, gjs 1.88.1) already present and working on this host.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-15T12:46:00Z
- **Completed:** 2026-07-15T12:52:13Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- `install.sh` PACMAN_PKGS array now declares `cava` (audio visualizer underlay, official `extra` repo — package-signed, trusted source)
- `install.sh` AUR_PKGS array now declares `aylurs-gtk-shell` (AGS v3 GTK4 toolkit — AUR, no official-repo alternative)
- Confirmed `ags --version` (3.1.0), `cava -v` (0.10.7), and `gjs --version` (1.88.1) all exit 0 on this machine — the full toolchain the rest of Phase 10 depends on is present and functional

## Task Commits

Each task was committed atomically:

1. **Task 1: Register cava (pacman) and aylurs-gtk-shell (AUR) in install.sh** - `314301a` (feat)
2. **Task 2: Verify installed toolchain (no-op install — see Deviations)** - no commit (no file changes; verify-only, read-only commands executed)

**Plan metadata:** committed separately (see below)

## Files Created/Modified
- `install.sh` - Added `cava` to `PACMAN_PKGS` (official extra repo) and `aylurs-gtk-shell` to `AUR_PKGS`, each with a short comment block matching the existing grouping/comment convention. No neighboring entries reformatted or removed.

## Decisions Made
- Skipped Task 2's install commands (`sudo pacman -S`, `paru -S`) because both packages, and their `gjs` transitive dependency, were already installed and verified working on this machine (pre-verified by the orchestrator before dispatch: `cava 0.10.7-1`, `aylurs-gtk-shell 3.1.2-1`, `gjs 1.88.1`). Running the install commands in this non-interactive context would have hung indefinitely waiting on a sudo password prompt (no TTY) and a paru AUR PKGBUILD confirmation prompt (no human present) — see Deviations below.

## Deviations from Plan

### Auto-fixed Issues

None — no bugs or missing functionality found.

### Plan Assumption Correction (pre-authorized by orchestrator, not a Rule 1-4 deviation)

**1. Task 2 install step run as verify-only no-op — packages were already installed**
- **Found during:** Task 2 (Install both deps on this machine and verify the toolchain)
- **Issue:** The plan assumed `cava` and `aylurs-gtk-shell` were not yet installed and specified `sudo pacman -S --needed --noconfirm cava` and `paru -S --needed --noconfirm aylurs-gtk-shell` as the task action. Reality (confirmed directly on this machine, both before and during this plan's execution): `cava 0.10.7-1`, `aylurs-gtk-shell 3.1.2-1`, and `gjs 1.88.1` were all already installed and functional (`ags --version` → 3.1.0, `cava -v` → 0.10.7, `gjs --version` → 1.88.1, all exit 0).
- **Fix:** Did not run the install commands (`sudo pacman -S`/`paru -S`) — running `sudo` non-interactively with no TTY for a password prompt, or `paru` with no human present to confirm the AUR PKGBUILD prompt, would have hung the session indefinitely. Instead ran only the plan's read-only `<verify>` command (`ags --version && cava -v | head -1 && gjs --version`), which satisfies Task 2's `<acceptance_criteria>` and `<done>` condition exactly as written (all three commands print the expected versions and exit 0).
- **Files modified:** None (Task 2 made no file changes — `install.sh` was already fully updated by Task 1).
- **Verification:** `ags --version` (3.x — 3.1.0), `cava -v | head -1` (0.10.x — 0.10.7), `gjs --version` (1.88.1); all exit 0. Full command output captured during execution.
- **Commit:** N/A — no changes to commit for this task (Task 1's commit `314301a` already covers install.sh; the toolchain binaries themselves are host system state, not repo-tracked).

---

**Total deviations:** 1 (plan-assumption correction, pre-authorized — not a Rule 1-4 auto-fix)
**Impact on plan:** None on scope. The plan's stated goal (both packages installed and declared in install.sh) is fully met — the packages simply arrived pre-installed rather than being installed by this execution. No architectural or functional change.

## Issues Encountered
None.

## User Setup Required

The plan's frontmatter declared a `user_setup` block (local-terminal presence for sudo/paru prompts during Task 2's install). Since Task 2's install commands were not run (packages already present — see Deviations), **no user setup action was actually required** this run. If either package is ever reinstalled from scratch on a different machine, the human MUST be present at the terminal for the sudo password prompt and to review paru's PKGBUILD prompt for `aylurs-gtk-shell`, per the plan's original threat-model mitigation (T-10-01-SC).

## Next Phase Readiness
- The AGS v3 / cava / gjs toolchain is confirmed present and functional on this host, and `install.sh` now reproduces it on a fresh Arch install (MEDIA-04 requirement closed).
- Ready for 10-02 (AGS applet scaffold) — no blockers.

---
*Phase: 10-ags-media-applet*
*Completed: 2026-07-15*

## Self-Check: PASSED

- FOUND: `.planning/phases/10-ags-media-applet/10-01-SUMMARY.md`
- FOUND: `install.sh`
- FOUND: commit `314301a` in git log
