---
phase: 06-themed-surfaces-utility-suite
plan: 01
subsystem: infra
tags: [install-sh, stow, pacman, aur, systemd, swayosd, reproducibility]

# Dependency graph
requires:
  - phase: 04-notifications-logout-polish
    provides: install.sh verify_packages hard-fail pattern (D-63/D-64/D-65), AUR package-legitimacy checkpoint precedent
provides:
  - install.sh declares all 16 new binaries this phase's surfaces/utilities depend on (13 official-repo, 3 AUR)
  - swayosd-libinput-backend.service enabled as a systemd --user unit via install.sh (D-23)
  - stow.sh declares the swayosd stow package
affects: [06-02, 06-04, 06-05, 06-06, 06-07, 06-08, 06-09]

# Tech tracking
tech-stack:
  added: [hyprshot, satty, gpu-screen-recorder, swayosd, hyprpicker, wtype, ddcutil, papirus-icon-theme, tela-icon-theme, colloid-icon-theme-git, papirus-folders, 5x ttf-*-nerd fonts]
  patterns: [PACMAN_PKGS/AUR_PKGS array extension in commented groups, systemctl --user enable --now guarded with 2>/dev/null || true idiom]

key-files:
  created: []
  modified: [install.sh, stow.sh]

key-decisions:
  - "All 16 new packages confirmed official-extra-repo (13) vs AUR (3) per RESEARCH Package Legitimacy Audit — corrected CONTEXT.md's original assumption"
  - "colloid-icon-theme-git (with -git suffix) used, not plain colloid-icon-theme which does not exist on AUR"
  - "swayosd-libinput-backend.service enabled unconditionally in section_core_rice so caps-lock OSD works without any Hyprland keybind (D-23)"
  - "satty excluded from stow.sh PACKAGES — its themed config is matugen-rendered TOML symlinked via commit.sh, not a stow @import package"

patterns-established:
  - "New package groups added as commented blocks matching existing PACMAN_PKGS/AUR_PKGS style, preserving verify_packages auto-coverage via VERIFY_PKGS = PACMAN_PKGS + AUR_PKGS"

requirements-completed: [SHOT-01, SHOT-02, SHOT-03, OSD-01, UTIL-01, UTIL-02, UTIL-04, UTIL-05]

coverage:
  - id: D1
    description: "install.sh PACMAN_PKGS extended with 13 official-repo packages (hyprshot, satty, gpu-screen-recorder, swayosd, hyprpicker, wtype, ddcutil, papirus-icon-theme, 5 ttf-*-nerd fonts)"
    verification:
      - kind: other
        ref: "bash -n install.sh && grep -q <pkg> install.sh (all 13 present, none in AUR_PKGS block)"
        status: pass
    human_judgment: false
  - id: D2
    description: "install.sh AUR_PKGS extended with 3 human-approved AUR packages (tela-icon-theme, colloid-icon-theme-git, papirus-folders) after package-legitimacy checkpoint"
    verification:
      - kind: manual_procedural
        ref: "human approved all 3 AUR pages per Task 1 checkpoint how-to-verify steps"
        status: pass
    human_judgment: true
    rationale: "AUR package legitimacy requires a human to visually confirm maintainer/votes/upstream on the live AUR page — this is a security gate that cannot be auto-verified by the executor itself, only pre-screened by RESEARCH."
  - id: D3
    description: "swayosd-libinput-backend.service enabled as systemd --user unit in section_core_rice (D-23)"
    verification:
      - kind: other
        ref: "grep 'swayosd-libinput-backend.service' install.sh"
        status: pass
    human_judgment: false
  - id: D4
    description: "stow.sh declares the swayosd package (satty correctly excluded — symlink model, not stow)"
    verification:
      - kind: other
        ref: "bash -n stow.sh && grep -A25 'PACKAGES=(' stow.sh confirms swayosd present, satty absent"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-12
status: complete
---

# Phase 06 Plan 01: Package Reproducibility Foundation Summary

**Extended install.sh with 16 new packages (13 official-repo, 3 human-approved AUR) and swayosd-libinput-backend systemd service; declared swayosd in stow.sh — full reproducibility foundation for the themed-surfaces-utility-suite phase.**

## Performance

- **Duration:** 15 min (spanning a checkpoint pause for AUR legitimacy approval)
- **Started:** 2026-07-12T15:56:37Z
- **Completed:** 2026-07-12T16:04:32Z
- **Tasks:** 3 (1 checkpoint + 2 auto)
- **Files modified:** 2

## Accomplishments
- install.sh PACMAN_PKGS extended with 13 official `extra`-repo packages: hyprshot, satty, gpu-screen-recorder, swayosd, hyprpicker, wtype, ddcutil, papirus-icon-theme, and 5 ttf-*-nerd fonts (jetbrains-mono, cascadia-code, hack, iosevka, meslo)
- install.sh AUR_PKGS extended with 3 human-approved AUR packages: tela-icon-theme, colloid-icon-theme-git, papirus-folders
- swayosd-libinput-backend.service enabled as a systemd --user unit in section_core_rice (D-23) so caps-lock OSD works without any keybind
- stow.sh PACKAGES array now declares swayosd (satty correctly excluded, following the symlink-not-stow model)
- verify_packages automatically covers all 16 new packages via its existing VERIFY_PKGS = PACMAN_PKGS + AUR_PKGS composition — no separate edit needed

## Task Commits

Each task was committed atomically:

1. **Task 1: AUR package-legitimacy gate** - checkpoint (human-verify, gate="blocking-human") — approved by user, "Approved — wire all 3" (no file changes, gate only)
2. **Task 2: Add all new packages to install.sh + enable swayosd libinput backend** - `f5247cf` (feat)
3. **Task 3: Declare swayosd stow package in stow.sh** - `ebb1166` (feat)

**Plan metadata:** (pending — this commit)

## Files Created/Modified
- `install.sh` - Added 13-package commented group to PACMAN_PKGS, 3-package block to AUR_PKGS, and swayosd-libinput-backend.service enable in section_core_rice
- `stow.sh` - Added `swayosd` entry to PACKAGES array

## Decisions Made
- Confirmed and wired the RESEARCH-corrected official-vs-AUR split (13 official / 3 AUR), overriding CONTEXT.md's original less-precise assumption
- Used `colloid-icon-theme-git` exact name (plain `colloid-icon-theme` does not exist on AUR)
- Enabled swayosd-libinput-backend.service unconditionally (not hardware-guarded) since it is software-only and required for D-23's keybind-free caps-lock OSD
- Kept satty out of stow.sh — its config is matugen-rendered TOML symlinked by commit.sh, matching the walker/yazi symlink model rather than swaync's stow @import model

## Deviations from Plan

None - plan executed exactly as written. Task 1's checkpoint was pre-resolved by the user ("Approved — wire all 3") before this continuation agent was spawned; Tasks 2 and 3 followed the plan's exact package lists, array locations, and verification commands with no adjustments needed.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required. All packages install automatically on the next `install.sh` run; swayosd-libinput-backend.service self-enables via `systemctl --user enable --now`.

## Next Phase Readiness
- All 16 binaries this phase's later plans (06-02 satty config, 06-04..06-09 surfaces/scripts) depend on are now declared for fresh-install reproducibility
- swayosd systemd service and stow package both wired ahead of plan 06-06, which creates the actual `swayosd/.config/swayosd/style.css` content
- No blockers for subsequent wave-1/wave-2 plans in this phase

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-12*

## Self-Check: PASSED

- FOUND: install.sh
- FOUND: stow.sh
- FOUND: .planning/phases/06-themed-surfaces-utility-suite/06-01-SUMMARY.md
- FOUND: f5247cf (Task 2 commit)
- FOUND: ebb1166 (Task 3 commit)
- FOUND: 734c5fd (SUMMARY.md commit)
