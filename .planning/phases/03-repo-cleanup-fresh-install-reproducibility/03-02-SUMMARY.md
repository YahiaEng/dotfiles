---
phase: 03-repo-cleanup-fresh-install-reproducibility
plan: 02
subsystem: infra
tags: [bash, install.sh, stow, pacman, aur, idempotency, arch-linux]

# Dependency graph
requires:
  - phase: 03-repo-cleanup-fresh-install-reproducibility
    provides: "03-01: dead wofi package removed from the repo tree, README aligned, screenshot-in-git root cause fixed"
provides:
  - "install.sh restructured into section_core_rice/section_hardware/section_personal, gated by a --core-only/--help flag parser that rejects unknown flags"
  - "install.sh hardware guards: NVIDIA package group installs only when lspci detects an NVIDIA GPU; limine steps only run when limine-install is present"
  - "install.sh hard-fail verify_packages() post-install verification table (pacman -Q per package, exit 1 on any miss)"
  - "install.sh fragile-operation guards: idempotent paru bootstrap clone, array+count-guarded orphan removal, backed-up+idempotent limine.conf removal"
  - "install.sh package-list corrections: wofi removed from PACMAN_PKGS, swaync moved from AUR_PKGS to PACMAN_PKGS"
  - "stow.sh fully idempotent: guarded hyprland.conf mv (existence+non-symlink check), no phantom scripts/wofi PACKAGES entries"
  - "stow.sh zero-prompt: sudo chsh replaces interactive chsh"
  - "stow.sh seeds ~/.local/state/theme/ via theme-apply catppuccin after the stow loop, guarded to degrade harmlessly without a session"
affects: [03-03, 03-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "verify_packages() nameref-array hard-fail accumulator, mirroring theme-doctor's check()/PASS/FAIL idiom (theme-doctor precedent → install.sh)"
    - "guard-before-mutate for every state-assuming shell operation (existence/type checks before mv/rm, count checks before array-expansion removal)"
    - "hardware detect-guards layered on top of CLI flags: flags select intent (--core-only), lspci/command -v detect actual hardware/bootloader presence"

key-files:
  created: []
  modified:
    - install.sh
    - stow.sh

key-decisions:
  - "verify_packages() is called once at the end of main with a combined VERIFY_PKGS array (PACMAN_PKGS + AUR_PKGS always, + NVIDIA_PKGS only when section_hardware actually installed them) rather than per-section, so --core-only and full runs each verify exactly what they installed (D-65)"
  - "NVIDIA_INSTALLED tracked as a script-global flag set inside section_hardware, defaulting false — lets the final verify step know whether NVIDIA_PKGS were installed without re-running lspci detection"
  - "theme-apply catppuccin invoked via the absolute stowed path ($HOME/.config/theme-engine/theme-apply), matching theme-init.sh's own invocation convention, not via PATH (theme-engine's bin is never added to PATH in this repo)"

patterns-established:
  - "Section-banner echo style + flag-gated function calls in main body: install.sh's section_core_rice/section_hardware/section_personal is now the template for any future installer restructuring in this repo"

requirements-completed: [INST-01, INST-02, CLEAN-01]

coverage:
  - id: D1
    description: "install.sh parses --core-only/--help; unknown flags reject with nonzero exit; --help prints usage before any install"
    requirement: "INST-01"
    verification:
      - kind: other
        ref: "bash install.sh --help (exit 0, no installs); bash install.sh --bogus (exit nonzero)"
        status: pass
    human_judgment: false
  - id: D2
    description: "install.sh installs correct theming-critical package names (adw-gtk-theme present, wofi absent, swaync in PACMAN_PKGS not AUR_PKGS)"
    requirement: "INST-01"
    verification:
      - kind: other
        ref: "grep -c wofi install.sh (PACMAN_PKGS) -> 0; grep swaync install.sh -> inside PACMAN_PKGS block"
        status: pass
    human_judgment: false
  - id: D3
    description: "NVIDIA packages install only when lspci detects an NVIDIA GPU; limine steps only run when limine-install is present"
    requirement: "INST-01"
    verification:
      - kind: other
        ref: "grep -q 'lspci' install.sh; grep -q 'command -v limine-install' install.sh"
        status: pass
    human_judgment: false
  - id: D4
    description: "install.sh ends with a hard-fail verify_packages() table printing per-package OK/MISS and exiting nonzero on any miss"
    requirement: "INST-01"
    verification:
      - kind: other
        ref: "grep -q verify_packages install.sh; function body contains exit 1 on nonzero missing count"
        status: pass
    human_judgment: false
  - id: D5
    description: "Fragile install.sh operations guarded: idempotent paru clone, array+count orphan removal, backed-up idempotent limine.conf removal"
    requirement: "INST-01"
    verification:
      - kind: other
        ref: "grep -q '/tmp/paru' install.sh (rm -rf guard); grep -q 'mapfile -t ORPHANS' install.sh; grep -q 'limine.conf.bak' install.sh; grep -Eq 'rm -f[[:space:]]+/boot/limine/limine.conf' install.sh"
        status: pass
    human_judgment: false
  - id: D6
    description: "stow.sh runs to completion on a genuinely fresh system where hyprland.conf does not exist, and re-runs without aborting"
    requirement: "INST-02"
    verification:
      - kind: other
        ref: "grep -q HYPR_CONF stow.sh; grep -q '! -L \"\\$HYPR_CONF\"' stow.sh"
        status: pass
    human_judgment: false
  - id: D7
    description: "stow.sh login-shell switch is non-interactive (sudo chsh, no PAM password prompt)"
    requirement: "INST-02"
    verification:
      - kind: other
        ref: "grep -Eq 'sudo (chsh|usermod)' stow.sh; grep -c 'chsh -s \\$(which zsh)$' stow.sh -> 0"
        status: pass
    human_judgment: false
  - id: D8
    description: "stow.sh seeds ~/.local/state/theme/ via theme-apply catppuccin after stowing, guarded against a missing entrypoint or no-session reload"
    requirement: "INST-02"
    verification:
      - kind: other
        ref: "grep -q 'theme-apply catppuccin' stow.sh; invocation wrapped in [[ -x \"$THEME_APPLY\" ]] with || true"
        status: pass
    human_judgment: false
  - id: D9
    description: "stow.sh PACKAGES array has neither the phantom scripts entry nor the retired wofi entry (CLEAN-01)"
    requirement: "CLEAN-01"
    verification:
      - kind: other
        ref: "awk '/^PACKAGES=\\(/,/^\\)/' stow.sh | grep -icE 'scripts|wofi' -> 0"
        status: pass
    human_judgment: false
  - id: D10
    description: "install.sh completes on a fresh system with zero orphan packages and re-runs without aborting; both scripts pass bash -n and shellcheck -S error"
    requirement: "INST-01"
    verification: []
    human_judgment: true
    rationale: "Static checks (bash -n, shellcheck, grep-based structural assertions) all pass, but a genuine end-to-end fresh-install run has not been executed in this plan — that is the container/VM reproduction gate owned by 03-04. This deliverable's structural correctness is proven; its live behavior on a real fresh box is unverified until 03-04's gate runs."

# Metrics
duration: 10min
completed: 2026-07-08
status: complete
---

# Phase 3 Plan 2: Install/Stow Hardening Summary

**install.sh restructured into a flagged, hardware-guarded, hard-fail-verifying installer (--core-only/--help, section_core_rice/section_hardware/section_personal, verify_packages()); stow.sh made fully idempotent, zero-prompt, and seeds the first-boot theme via theme-apply catppuccin.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-08T11:27:14Z
- **Completed:** 2026-07-08T11:33:43Z
- **Tasks:** 3 completed
- **Files modified:** 2

## Accomplishments
- install.sh now parses `--core-only`/`--help` and rejects unknown flags loudly; the default (no-flag) run preserves today's full real-machine behavior while `--core-only` runs only the packages/services section for the VM/container verification gate
- NVIDIA packages and the limine bootloader block are hardware-guarded (`lspci | grep -qi nvidia`, `command -v limine-install`) instead of always running
- `wofi` removed from `PACMAN_PKGS`; `swaync` moved from `AUR_PKGS` to `PACMAN_PKGS` (it has lived in the official `extra` repo since IN-11 was flagged)
- Three confirmed-broken install.sh operations hardened for a fresh install / re-run: the paru bootstrap clone (`rm -rf /tmp/paru` guard), the orphan-removal abort (`mapfile`+count-guarded array expansion replacing the unquoted single-string form), and the limine.conf deletion (backup-then-`rm -f` replacing a bare, no-backup `rm`)
- `verify_packages()` added: a hard-fail post-install table (`pacman -Q` per package, `[OK]`/`[MISS]` per line, `exit 1` on any miss) run once at the end against exactly the package set the selected sections installed
- stow.sh's unguarded `mv ~/.config/hypr/hyprland.conf` — which would hard-abort on a genuinely fresh system since the hyprland package ships no default config there — is now existence+non-symlink guarded
- stow.sh's `chsh` (which triggers an interactive PAM password prompt) replaced with `sudo chsh`, eliminating the last interactive step before the final human visual check
- stow.sh's phantom `scripts` PACKAGES entry (no such directory exists) and the retired `wofi` entry removed
- stow.sh now runs `theme-apply catppuccin` once after the stow loop so `~/.local/state/theme/` is seeded before first login, guarded so a missing entrypoint or no-session reload degrades harmlessly instead of aborting under `set -e`

## Task Commits

Each task was committed atomically:

1. **Task 1: Restructure install.sh into flagged sections with hardware guards** - `98e7d93` (feat)
2. **Task 2: Guard fragile operations and add the hard-fail post-install verification table** - `289980d` (fix)
3. **Task 3: Make stow.sh idempotent, non-interactive, and seed the first-boot theme** - `372feb8` (feat)

**Plan metadata:** (pending — this SUMMARY + STATE.md + ROADMAP.md commit)

## Files Created/Modified
- `install.sh` - flagged/sectioned installer (`section_core_rice`/`section_hardware`/`section_personal`), hardware guards, package-list corrections, `verify_packages()` hard-fail table, guarded orphan/limine/paru-clone operations
- `stow.sh` - guarded hyprland.conf mv, non-interactive `sudo chsh`, cleaned `PACKAGES` array, post-stow `theme-apply catppuccin` seed

## Decisions Made
- `verify_packages()` is called once at the very end of `main` with a combined array (`PACMAN_PKGS` + `AUR_PKGS` always, `NVIDIA_PKGS` appended only when `section_hardware` actually installed them via the `NVIDIA_INSTALLED` flag) — matches D-65's "verify exactly what the selected sections installed" requirement without duplicating verification calls per-section
- `theme-apply` is invoked via its absolute stowed path (`$HOME/.config/theme-engine/theme-apply`), the same convention `theme-init.sh` already uses — theme-engine's binaries are never added to `PATH` in this repo, so a bare `theme-apply` call would not resolve
- Kept the original section-banner echo style (`╔══╗`) for `section_hardware`'s new banner, matching the existing `install.sh`/`stow.sh` visual convention noted in 03-PATTERNS.md

## Deviations from Plan

None - plan executed exactly as written. One micro-correction was made and resolved within Task 2's own verification loop, before the commit: the Task 2 acceptance-criteria grep `! grep -qF 'R "$(pacman -Qtdq)"'` initially failed because the explanatory code comment quoted the old buggy line verbatim; reworded the comment to describe the bug without reproducing the exact string, then re-ran the full verification gate — not logged as a Rule-1 deviation since it never reached a commit in the broken state.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for the remainder of Phase 3 (03-03 elephant provider/theme-doctor hardening, 03-04 the container + graphical-VM reproduction gate that exercises exactly these two hardened scripts)
- `install.sh --core-only` and `stow.sh` are structurally ready for the 03-04 VM/container gate; live fresh-install behavior (D10 above) remains unverified until that gate actually runs them end-to-end on a disposable environment
- No blockers for continuing Phase 3 execution

---
*Phase: 03-repo-cleanup-fresh-install-reproducibility*
*Completed: 2026-07-08*
