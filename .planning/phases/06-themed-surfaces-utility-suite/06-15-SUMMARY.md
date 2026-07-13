---
phase: 06-themed-surfaces-utility-suite
plan: 15
subsystem: infra
tags: [install.sh, pacman, vlc, xdg-user-dirs, reproducibility, gap-closure]

# Dependency graph
requires:
  - phase: 06-themed-surfaces-utility-suite (06-11/06-14)
    provides: capture-region/window/full.sh and record-toggle.sh producing gpu-screen-recorder output that needed a decodable player
provides:
  - PACMAN_PKGS entries for vlc, vlc-plugins-all, and xdg-user-dirs so a fresh install.sh run leaves recordings playable and ~/Pictures reproducible
affects: [install.sh, fresh-install-reproducibility, SHOT-03 UAT re-verification]

# Tech tracking
tech-stack:
  added: [vlc, vlc-plugins-all, xdg-user-dirs]
  patterns: []

key-files:
  created: []
  modified: [install.sh]

key-decisions:
  - "vlc + vlc-plugins-all and xdg-user-dirs placed in PACMAN_PKGS (not AUR_PKGS) — all three are official Arch repo packages (vlc/vlc-plugins-all in extra, xdg-user-dirs in core), no legitimacy checkpoint required"

patterns-established: []

requirements-completed: [SHOT-03]

coverage:
  - id: D1
    description: "install.sh PACMAN_PKGS array installs vlc, vlc-plugins-all, and xdg-user-dirs on a fresh system"
    requirement: "SHOT-03"
    verification:
      - kind: unit
        ref: "grep -qxE '\\s*vlc' install.sh && grep -q 'vlc-plugins-all' install.sh && grep -q 'xdg-user-dirs' install.sh && bash -n install.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "gpu-screen-recorder recordings play in VLC out of the box with no manual codec install (live re-UAT of SHOT-03 gap)"
    requirement: "SHOT-03"
    verification: []
    human_judgment: true
    rationale: "Requires actually opening a recorded video in VLC on a machine where vlc-plugins-all was freshly installed via this change — cannot be proven by static grep/syntax checks alone."

# Metrics
duration: 1min
completed: 2026-07-13
status: complete
---

# Phase 6 Plan 15: Install Codecs for Screen Recording Playback Summary

**Added vlc, vlc-plugins-all, and xdg-user-dirs to install.sh's PACMAN_PKGS so fresh installs can decode gpu-screen-recorder output and get a deterministic ~/Pictures dir.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-07-13T00:41:35Z
- **Completed:** 2026-07-13T00:42:00Z
- **Tasks:** 1 completed
- **Files modified:** 1

## Accomplishments
- Closed the SHOT-03 UAT minor gap: fresh installs previously shipped no vlc entry at all, so gpu-screen-recorder recordings had no player able to decode them (Arch's vlc 3.0.23_2 split codec plugins out of base `vlc` into `vlc-plugins-*`)
- Added `xdg-user-dirs` to guarantee `~/Pictures` and `XDG_PICTURES_DIR` resolve deterministically on a fresh system, removing the fragile `${XDG_PICTURES_DIR:=~}` fallback risk
- All three packages verified as official Arch repo packages (vlc + vlc-plugins-all in `extra`, xdg-user-dirs in `core`) — no AUR, no legitimacy checkpoint needed

## Task Commits

Each task was committed atomically:

1. **Task 1: Add vlc, vlc-plugins-all, and xdg-user-dirs to PACMAN_PKGS** - `0e1e097` (feat)

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified
- `install.sh` - Added `vlc`, `vlc-plugins-all`, and `xdg-user-dirs` entries with explanatory comments to the "Screenshots, screen recording, OSD, utilities" block in `PACMAN_PKGS`

## Decisions Made
- vlc + vlc-plugins-all and xdg-user-dirs placed in `PACMAN_PKGS` (not `AUR_PKGS`) since all three are official Arch repo packages — no package-legitimacy checkpoint required (T-06-15-SC disposition: mitigate via official-repo signature verification)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. On the next fresh `install.sh` run, `vlc`, `vlc-plugins-all`, and `xdg-user-dirs` will install automatically via `pacman -Sy --needed`.

## Next Phase Readiness

- `install.sh`'s package list now covers the full screenshot/recording suite end-to-end: capture, annotate, and now playback of recordings.
- Live re-UAT still required (per plan's verification section): record a clip via the Alt+Print toggle, open it in VLC, confirm no "no suitable decoder" error. This is a human/manual step reserved for `gsd-verify-work` (see D2 in coverage above) since it needs a real fresh-codec-install environment to prove.
- No blockers for phase completion.

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-13*

## Self-Check: PASSED

- FOUND: install.sh contains vlc, vlc-plugins-all, xdg-user-dirs entries
- FOUND: commit 0e1e097 (Task 1)
- FOUND: .planning/phases/06-themed-surfaces-utility-suite/06-15-SUMMARY.md
