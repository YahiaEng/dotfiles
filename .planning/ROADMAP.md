# Roadmap: Arch + Hyprland Dotfiles

## Overview

This milestone fixes the theming pipeline that is the project's entire premise: one theme switch — static preset or matugen dynamic — instantly re-themes every visible app, reproducibly from a fresh install. The journey goes root-cause-first: Phase 1 eliminates the verified stuck-white root cause (a missing GTK theme package), consolidates the scattered/duplicated orchestration into one shared engine, and makes every app (Walker, Thunar, GTK4, waybar, swaync) re-theme live. Phase 2 proves static and dynamic modes are genuinely one pipeline and stays correct under repeated switching. Phase 3 removes dead configs and verifies the whole setup reproduces unattended on a fresh Arch system. The v2 expansion (SwayOSD, Walker menus, media widget, polish, more themes) is a future milestone and deliberately excluded here — every one of those surfaces reads colors from the pipeline this milestone repairs.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Root-Cause Fix & Consolidated Theme Engine** - Eliminate the stuck-white root cause, unify orchestration, make every app re-theme live
- [ ] **Phase 2: Static ↔ Dynamic Parity & Switch Reliability** - Prove both modes are one pipeline and survive repeated switching
- [ ] **Phase 3: Repo Cleanup & Fresh-Install Reproducibility** - Remove dead configs and verify the themed desktop reproduces from scratch

## Phase Details

### Phase 1: Root-Cause Fix & Consolidated Theme Engine

**Goal**: Every visible desktop app re-themes live from a single shared engine, with the root cause of the long-standing stuck-white bug eliminated and the full repo audited so fixes stop looping.
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: THEME-01, THEME-02, THEME-03, THEME-04, THEME-05, THEME-06, PIPE-01, PIPE-02, PIPE-03, PIPE-05, SCAN-01, SCAN-02
**Success Criteria** (what must be TRUE):

  1. After a theme switch, Walker opens in the new theme's colors instead of default white — no restart or relogin, and its elephant backend serves results normally.
  2. After the same switch, Thunar and other GTK3 apps show the new palette (adw-gtk-theme installed and applied), and GTK4/libadwaita apps follow the correct light/dark mode + accent color.
  3. Waybar and swaync visibly re-theme on the same switch, confirmed in both a static preset and a matugen dynamic switch.
  4. A single theme switch updates every visible app at once, with no relogin or session restart required.
  5. The same theme applies identically whether triggered from the interactive picker or at login (one shared entrypoint, one reload owner, one GTK_THEME source), and a documented full-repo audit records findings across the theme pipeline, hyprland/keybinds/uwsm config, stow, and install scripts.

**Plans**: 3 plans

Plans:
**Wave 1**

- [ ] 01-01-PLAN.md — Full-repo bug audit (AUDIT.md) + root-cause dependency fix (adw-gtk-theme install, Walker/elephant provider health)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 01-02-PLAN.md — Consolidated theme engine: shared theme-apply entrypoint, single-rendering-path palettes, atomic apply, single reload owner, outputs out of the git tree, single GTK theme env source

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 01-03-PLAN.md — Per-app live re-theme: hardened restart-based Walker reload (no hotreload key exists) + elephant health, daemon-only Thunar restart, GTK4 dark/accent, all-ten end-to-end verify (static + dynamic)

### Phase 2: Static ↔ Dynamic Parity & Switch Reliability

**Goal**: Static presets and matugen dynamic themes are proven to be one pipeline producing an identical output contract, and switching stays correct under repeated real-world use.
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: PIPE-04, PIPE-06
**Success Criteria** (what must be TRUE):

  1. Switching to a static preset and to a matugen dynamic theme both produce the same canonical color files — identical paths and variable names — verifiable by diffing the generated output structure.
  2. Every app re-themes identically regardless of whether the source was a static preset or a dynamic wallpaper theme (no mode-only divergence).
  3. Running 10 consecutive theme switches with Thunar and Walker open leaves every app correctly themed on the final switch — no drift, no stuck-white, no stale caches (100% correct).

**Plans**: 1 plan

Plans:

- [ ] 02-01: Parity verification (canonical output contract) + repeated-switch stress test

### Phase 3: Repo Cleanup & Fresh-Install Reproducibility

**Goal**: The repo is clean of dead configs and generated artifacts, and the entire themed desktop reproduces unattended on a genuinely fresh Arch system via install.sh + stow.
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: CLEAN-01, CLEAN-02, INST-01, INST-02, INST-03
**Success Criteria** (what must be TRUE):

  1. Dead configs are gone — the wofi package, debug.txt, and stray screenshots no longer exist in the repo, and stow applies cleanly with no conflicts.
  2. After any theme switch, `git status` stays clean — no generated color files tracked in the repo.
  3. On a genuinely fresh Arch VM/container, `install.sh` installs all theming-critical packages (adw-gtk-theme, not the nonexistent adw-gtk3) and reports post-install verification of critical packages.
  4. On that same fresh system, `stow.sh` completes without aborting — no unguarded operations that assume pre-existing state.
  5. A full `install.sh` + `stow.sh` run in a disposable VM/container produces the fully themed desktop unattended — a real reproduction, not a re-stow on the dev machine.

**Plans**: 2 plans

Plans:

- [ ] 03-01: Repo cleanup — remove wofi/debug.txt/screenshots, gitignore generated outputs, verify clean git status after switch
- [ ] 03-02: Fresh-install hardening + disposable-VM verification (package names, post-install checks, stow fresh-run guards)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Root-Cause Fix & Consolidated Theme Engine | 0/3 | Not started | - |
| 2. Static ↔ Dynamic Parity & Switch Reliability | 0/1 | Not started | - |
| 3. Repo Cleanup & Fresh-Install Reproducibility | 0/2 | Not started | - |
