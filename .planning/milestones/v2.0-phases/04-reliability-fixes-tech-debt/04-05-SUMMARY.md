---
phase: 04-reliability-fixes-tech-debt
plan: 05
subsystem: infra
tags: [fish, nvm, nvm.fish, node, install.sh, shell-init]

# Dependency graph
requires:
  - phase: 04-reliability-fixes-tech-debt (plan 04)
    provides: fish adoption for kitty (D-08), fisher + nvm.fish bootstrap, fish_plugins pin
provides:
  - Explicit, guarded nvm default-version activation in fish's interactive block, closing the D-10 node-tooling parity gap
  - Documented one-time `nvm install v24.18.0` provisioning step in install.sh's "Next steps" output
affects: [phase-05, phase-06, phase-07, phase-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "fish conf.d/*.fish files source before config.fish — any plugin relying on a config.fish-set variable at conf.d-load time needs an explicit re-check/activation call later in config.fish, not just the variable set"

key-files:
  created: []
  modified:
    - fish/.config/fish/config.fish
    - install.sh

key-decisions:
  - "Fixed via explicit guarded `nvm use --silent $nvm_default_version` inside the existing `status is-interactive` block (04-REVIEW.md CR-01 primary option), not a conf.d snippet or set -U universal — self-contained, stow-reproducible, independent of nvm.fish's internal guard/conf.d sort order"
  - "Fresh-machine Node provisioning documented as a one-time install.sh 'Next steps' doc line rather than automated — an automated download in install.sh would race stow's fish_plugins symlinking and complicate the D-24 container gate; a pinned, copy-pasteable command is the proportionate fix"

patterns-established: []

requirements-completed: [FIX-03]

coverage:
  - id: D1
    description: "A fresh interactive fish shell in a clean environment auto-activates nvm default version v24.18.0 and has node/npm/npx on PATH"
    requirement: "FIX-03"
    verification:
      - kind: manual_procedural
        ref: "env -i HOME=\"$HOME\" USER=\"$USER\" TERM=xterm PATH=/usr/bin:/bin fish -i -c 'type -q node; and echo NODE=YES; or echo NODE=NO' -> NODE=YES; echo $nvm_current_version -> v24.18.0"
        status: pass
    human_judgment: false
  - id: D2
    description: "install.sh documents the one-time nvm install v24.18.0 provisioning step for a genuinely fresh machine"
    requirement: "FIX-03"
    verification:
      - kind: other
        ref: "grep -q 'nvm install v24.18.0' install.sh && bash -n install.sh"
        status: pass
    human_judgment: false

# Metrics
duration: 10min
completed: 2026-07-11
status: complete
---

# Phase 04 Plan 05: fish nvm activation gap closure Summary

**Fixed fish's silent node-tooling activation gap (04-REVIEW.md CR-01) by adding an explicit, guarded `nvm use --silent` call in config.fish's interactive block, plus documented the one-time fresh-machine `nvm install v24.18.0` provisioning step in install.sh.**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-07-11
- **Tasks:** 2 completed
- **Files modified:** 2

## Accomplishments
- Root-caused and fixed CR-01: fish sources `conf.d/nvm.fish` (the plugin's own auto-activation guard) before `config.fish` sets `nvm_default_version`, so the guard silently no-ops on every fresh shell — the failed D-10 parity truth is now observably true (`NODE=YES`, `nvm_current_version=v24.18.0` in a clean-env probe)
- Corrected the stale config.fish comment that incorrectly claimed parity with zsh's D-04 lazy-load
- Documented the one-time `nvm install v24.18.0` fresh-machine provisioning step in install.sh's "Next steps" output, closing the verification gap's secondary `missing:` item without adding any automated network/download step to install.sh

## Task Commits

Each task was committed atomically:

1. **Task 1: Activate the nvm default version explicitly in config.fish (closes CR-01)** - `a9d9653` (fix)
2. **Task 2: Document one-time fresh-machine Node provisioning in install.sh** - `58b672d` (docs)

**Plan metadata:** (pending — final docs commit)

## Files Created/Modified
- `fish/.config/fish/config.fish` - Added a guarded `nvm use --silent $nvm_default_version` activation block inside the `status is-interactive` block (no-op when nvm.fish isn't bootstrapped or a version is already active); corrected the stale "D-04 lazy-load equivalent" comment to accurately describe the conf.d-before-config.fish ordering
- `install.sh` - Added one "Next steps" line documenting the one-time `nvm install v24.18.0` provisioning command; renumbered subsequent steps

## Decisions Made
- Explicit in-config.fish activation over a conf.d snippet or `set -U` universal (04-REVIEW.md CR-01 primary recommendation — self-contained, stow-reproducible, independent of nvm.fish's internal guard structure and conf.d filename sort order)
- Node provisioning documented as a manual one-time doc step in install.sh rather than automated, to avoid racing stow's fish_plugins symlinking and to keep the D-24 container gate clean

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Both automated verification commands passed on first attempt:
- `fish -n fish/.config/fish/config.fish` exits 0; `grep -q 'nvm use --silent'` and `grep -q 'functions -q nvm'` both match
- Clean-env probe: `env -i HOME="$HOME" USER="$USER" TERM=xterm PATH=/usr/bin:/bin fish -i -c 'type -q node; and echo NODE=YES; or echo NODE=NO'` printed `NODE=YES`; `$nvm_current_version` reported `v24.18.0`
- `bash -n install.sh` exits 0; `grep -q 'nvm install v24.18.0' install.sh` matches; `git diff install.sh` shows only added echo lines, no new PACMAN_PKGS/AUR_PKGS/functions/network calls

## User Setup Required

None - no external service configuration required. (The documented `nvm install v24.18.0` step is a one-time fresh-machine setup instruction printed by install.sh, not an action needed on this already-provisioned dev machine — verified `nvm_current_version=v24.18.0` is already active here.)

## Next Phase Readiness
- Phase 4's single verification gap (04-REVIEW.md CR-01) is closed; the failed D-10 truth ("fish reaches day-one parity: working node tooling") is now observably true
- No regression to 04-01..04-04 deliverables — only config.fish's interactive block and install.sh's "Next steps" echo block were touched
- Phase 4 is now ready for milestone-level verification / transition

---
*Phase: 04-reliability-fixes-tech-debt*
*Completed: 2026-07-11*

## Self-Check: PASSED
