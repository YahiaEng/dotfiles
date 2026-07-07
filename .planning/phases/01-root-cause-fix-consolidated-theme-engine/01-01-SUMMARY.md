---
phase: 01-root-cause-fix-consolidated-theme-engine
plan: 01
subsystem: theming-pipeline
tags: [audit, gtk, adw-gtk-theme, walker, elephant, install-sh]
requires: []
provides:
  - AUDIT.md with 23 component-grouped findings, each with severity + file:line evidence + owned disposition
  - adw-gtk-theme 6.5-1 installed (stuck-white root cause eliminated at package level)
  - install.sh corrected package arrays (adw-gtk-theme in PACMAN_PKGS; elephant-runner/websearch/files in AUR_PKGS; wrong adw-gtk3 name removed)
affects:
  - 01-02 (engine build reads AUDIT.md findings 1, 2, 4, 5, 8, 11, 12, 17)
  - 01-03 (walker restart-only design per finding 6)
  - phase-03 (findings 10, 15, 16, 20, 21, 22, 23 dispositioned fix-in-phase-3)
tech-stack:
  added: [adw-gtk-theme 6.5-1 (official extra repo)]
  patterns: [audit-first-then-fix (D-24), disposition-owned findings (D-22/D-23)]
key-files:
  created:
    - .planning/phases/01-root-cause-fix-consolidated-theme-engine/AUDIT.md
  modified:
    - install.sh
decisions:
  - "elephant-runner/websearch/files added to install.sh AUR array — all three verified to resolve via paru -Si (RESEARCH assumption A2 confirmed), matching the adw-gtk-theme exception shape"
  - "walker-theme-gen.sh missing exec bit dispositioned wontfix — masked by stow.sh's chmod +x step; noted for Plan 01-02 to commit new scripts with correct mode"
  - "elephant-providerlist silent install failure and menus-provider-inactive anomaly deferred to Phase 3 (INST-01 verification loop), not spot-fixed here"
metrics:
  duration: ~25 min (excluding sudo auth gate wait)
  completed: 2026-07-07
status: complete
---

# Phase 1 Plan 01: Full-Repo Audit + Root-Cause Package Fix Summary

**One-liner:** 23-finding component-grouped AUDIT.md (SCAN-01/SCAN-02) plus the verified stuck-white root-cause fix: adw-gtk-theme installed from official extra repo and install.sh's nonexistent adw-gtk3 AUR entry replaced.

## What Was Done

### Task 1: Full-repo bug audit → AUDIT.md (commit d447341)

Produced `.planning/phases/01-root-cause-fix-consolidated-theme-engine/AUDIT.md` following D-22's format exactly:

- **5 component sections:** theme pipeline (findings 1-10), hyprland/keybinds (11-12), uwsm (13-14), stow (15-17), install scripts (18-23)
- **Every finding** carries severity (critical/major/minor), `file:line` evidence, and exactly one disposition token (fix-in-phase-1 / fix-in-phase-3 / wontfix — no finding was assigned fix-in-phase-2 and none left unowned)
- **SCAN-02 dedicated section** with a provider-by-provider gap table comparing `elephant listproviders` live output (4 active: calc, symbols, desktopapplications, clipboard) against walker config.toml's 9 referenced providers and installed elephant-* packages
- **All five research-mandated findings recorded:** three-way apply/reload duplication naming wallpaper-picker.sh:132-157 explicitly (#1), double reload fan-out (#2), GTK_THEME triplication (#8), generated-files-tracked-in-git (#4, with 22 tracked overwrite-target files enumerated via git ls-files), matugen [config.wallpaper]+json panic (#5)
- **RESEARCH assumption A2 resolved empirically:** `paru -Si elephant-runner elephant-websearch elephant-files` — all three names resolve as real AUR packages

### Task 2: Root-cause package fix (commit 7b73a53 + live install)

- Removed `adw-gtk3` (nonexistent package name — the actual root cause) from install.sh's `AUR_PKGS` (was line 150)
- Added `adw-gtk-theme` to `PACMAN_PKGS` (official `extra` repo — NOT the AUR array, per RESEARCH's placement correction)
- Added `elephant-runner`, `elephant-websearch`, `elephant-files` to `AUR_PKGS` alongside the existing elephant block (all verified resolvable in Task 1)
- Installed `adw-gtk-theme 6.5-1` on this machine via `sudo pacman -S --needed adw-gtk-theme` (user-executed after auth gate)

## Verification Results

| Check | Result |
|-------|--------|
| `pacman -Q adw-gtk-theme` | `adw-gtk-theme 6.5-1` — exit 0 |
| Theme resolves on disk | `/usr/share/themes/adw-gtk3` and `/usr/share/themes/adw-gtk3-dark` both exist |
| `grep -q 'adw-gtk-theme' install.sh` | pass |
| `grep -vE '^\s*#' install.sh \| grep -cw 'adw-gtk3'` | `0` (wrong install target gone) |
| AUDIT.md exists, has 5 component headings, severity + disposition on every finding | pass |
| SCAN-02 comparison section present | pass |
| wallpaper-picker.sh named in three-way duplication finding | pass |
| No Phase 2/3 fixes performed (only recorded + disposed) | pass — install.sh edits limited to the two D-24-exception fix shapes |

## Deviations from Plan

None - plan executed exactly as written.

## Authentication Gates

**Task 2 — sudo password gate:** `sudo pacman -S --needed --noconfirm adw-gtk-theme` could not run non-interactively (no terminal for password, no askpass helper). Committed the install.sh fix, returned a checkpoint:human-action; the user ran the install in their own terminal. Re-verified afterward: package installed, theme dirs present. Normal flow, not a deviation.

## Decisions Made

- All three candidate elephant provider packages added to install.sh (none failed `paru -Si` resolution, so no Phase-3 TBD note was needed)
- Finding #9 (walker-theme-gen.sh missing exec bit in git) dispositioned wontfix — mitigated by stow.sh's existing chmod step; flagged as a hygiene note for Plan 01-02's new scripts
- Finding #7's disposition split: package additions fixed here (fix-in-phase-1); the `menus`-installed-but-inactive anomaly and `elephant-providerlist` silent-install-failure deferred to Phase 3's INST-01 verification loop

## Known Stubs

None — this plan produced documentation and package-array edits only; no application code with data flow was created.

## Threat Flags

None — the only new surface is the pacman install of `adw-gtk-theme`, already covered by the plan's threat model T-01-SC (verified official `extra` repo, disposition mitigate, applied as specified).

## For Plan 01-02 (next)

Read AUDIT.md before building the engine (D-24). Key inputs:
- Finding #5: `[config.wallpaper]` must be removed/disabled before any `matugen json` call — hard crash otherwise
- Finding #6: Walker reload must be restart-based; `hotreload_theme` does not exist in walker 2.16.2
- Finding #4: the 22 git-tracked generated files must be `git rm --cached`/converted when the output contract moves to `~/.local/state/theme/`
- Finding #17: add walker rice-theme dir to `.stow-local-ignore` as part of one-time wiring (D-09)

## Commits

| Hash | Message |
|------|---------|
| d447341 | docs(01-01): full-repo bug audit (SCAN-01, SCAN-02) |
| 7b73a53 | fix(01-01): install adw-gtk-theme from official repo, add elephant providers |

## Self-Check: PASSED

- AUDIT.md exists — FOUND
- 01-01-SUMMARY.md exists — FOUND
- install.sh modified — FOUND
- Commit d447341 — FOUND
- Commit 7b73a53 — FOUND
