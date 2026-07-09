---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 03
current_phase_name: repo-cleanup-fresh-install-reproducibility
status: executing
stopped_at: "INST-03 container tier PASSED (run-20260709T060703Z, overall=PASS, parity 287/0); VM tier human sign-off is the last outstanding evidence"
last_updated: "2026-07-09T06:45:00.000Z"
last_activity: 2026-07-09
last_activity_desc: Container gate green - first full PASS; only VM human visual confirmation remains for INST-03
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 9
  completed_plans: 9
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-07)

**Core value:** One theme switch — static or dynamic — instantly and consistently re-themes the entire desktop, and the whole setup reproduces from scratch with one script.
**Current focus:** Phase 03 — repo-cleanup-fresh-install-reproducibility

## Current Position

Phase: 03 (repo-cleanup-fresh-install-reproducibility) — EXECUTING
Plan: 4 of 4
Status: Ready to execute
Last activity: 2026-07-08 — Phase 03 execution started

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 5
- Average duration: - min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3 | - | - |
| 02 | 2 | - | - |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
| Phase 01 P01 | 25min | 2 tasks | 2 files |
| Phase 01 P02 | 40min | 3 tasks | 27 files |
| Phase 01 P03 | multi-session | 3 tasks | 9 files |
| Phase 02 P01 | 25min | 3 tasks | 4 files |
| Phase 02 P02 | 11min | 3 tasks | 3 files |
| Phase 03 P01 | 20min | 3 tasks | 8 files |
| Phase 03 P02 | 10min | 3 tasks | 2 files |
| Phase 03 P03 | 55min+continuation | 2 tasks | 2 files |
| Phase 03 P04 | 20min | 3 tasks | 3 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Roadmap: Fix theming pipeline root-cause-first before any v2 expansion — every v2 surface reads from the pipeline this milestone repairs.
- Roadmap: Full-repo bug audit (SCAN-01) placed in Phase 1 as foundational discovery to break the patch-without-diagnosing loop (8+ prior failed fix commits).
- [Phase 01]: elephant-runner/websearch/files added to install.sh AUR array — all three verified via paru -Si (RESEARCH A2 confirmed)
- [Phase 01]: elephant-providerlist silent install failure and menus-provider-inactive anomaly deferred to Phase 3 INST-01 verification loop
- [Phase 01]: 01-02: matugen 4.1.0 never populates colors.image in EITHER json or image render mode (correction to 01-RESEARCH.md) - hardcoded a blank $image in the hyprland template since hyprlock theming is out of scope this milestone
- [Phase 01]: 01-02: walker-restart.sh/walker-theme-gen.sh/gtk-reload.sh/vscodium-theme.sh left on disk unreferenced - Plan 01-03 explicitly owns their retirement
- [Phase 01]: 01-03: set -e + (( counter++ )) at counter=0 silently aborts theme-apply mid-reload before the walker relaunch line — rewritten to counter=$((counter+1)) everywhere in reload.sh/gtk.sh
- [Phase 01]: 01-03: walker-style.css selectors (#box/#search/row) matched no real widget in walker 2.16.2's class-based UI — rewritten against the actual widget tree
- [Phase 01]: 01-03: Thunar deferred-restart notify-and-skip branch never re-fired — replaced with a deduped bounded-poll watcher that restarts once the last window closes
- [Phase 01]: 01-03: RESEARCH Open Question 2 answered — GTK3 windows do not re-color live, D-15's stale-until-closed caveat stands unmodified
- [Phase 01]: 01-03: theme-doctor's one remaining gap (elephant listproviders missing files/menus/providerlist/runner/websearch) is accepted and deferred to Phase 3 INST-01 per user sign-off
- [Phase ?]: 02-01: contract.json models the output contract as files[] with per-file format/exempt_keys (not a flat variable-name list) because the 10 rendered files span 6 genuinely different syntaxes (D-30)
- [Phase ?]: 02-01: theme-parity all-green (217 passed, 0 failed) across all 7 targets - zero divergence found between static presets and matugen dynamic mode; no Phase-1 palette/template fix was needed
- [Phase ?]: 02-01: semantic-value no-empty-slot rule is format-conditional - enforced for gtk-css/hypr-vars/kitty-kv/css-literal (every key is definitionally a color) but only color-shaped values are validated for toml/json (mixed formats with legitimate non-color string leaves like yazi.toml icon glyphs)
- [Phase 02]: 02-02: D-40 fix scope - excluded logs/ from commit.sh's rsync --delete rather than relocating logs/ or reworking the commit sync logic — Minimal fix preserving the atomic-commit contract for all 10 tracked output files while protecting the harness's own runtime log output
- [Phase 02]: 02-02: D-41 gate satisfied by running theme-stress-test then theme-parity back-to-back (22:27:06Z to 22:28:32Z) in one uninterrupted session — Immediately after the D-40 fix landed - not stitched together from separate historical runs, satisfying the 'no stitched/resumed runs as passing evidence' requirement
- [Phase 03]: screenshot.sh save path left unchanged; fixed via stow-fold exclusion + gitignore pair, not path relocation (D-48) — ~/Pictures is stow-folded from wallpapers/Pictures, so relocating the save path alone would not stop future screenshots from re-entering the fold
- [Phase 03]: powermenu.sh and .vscode/settings.json kept undeleted, batched as ambiguous per D-47/D-51 — D-51 explicitly names older switch/picker variants and root-level oddities as ambiguous-bucket candidates requiring confirmation, even when functionally superseded
- [Phase 03]: 03-02: verify_packages() runs once at the end of main with a combined array (core set always, NVIDIA_PKGS only when section_hardware actually installed them) — Matches D-65's 'verify exactly what the selected sections installed' without per-section verification calls
- [Phase 03]: 03-02: theme-apply invoked via its absolute stowed path (/home/aorus/.config/theme-engine/theme-apply), matching theme-init.sh's convention — theme-engine's binaries are never added to PATH in this repo, so a bare theme-apply call would not resolve
- [Phase 03]: 03-03: elephant provider gap resolved via human-run paru --rebuild of the elephant split package + restart — root cause was a Go plugin/host build-invocation mismatch, not missing packages; theme-doctor now exits 0 (23 passed, 0 failed)
- [Phase 03-04]: container-tier gate execution deferred — origin/main is ~80 commits behind local HEAD (predates theme-engine entirely); running verify/container-run.sh now would clone a pre-Phase-3 state and produce meaningless evidence. Push to origin was NOT performed autonomously — requires explicit user authorization before container run + VM human sign-off can close INST-03. (Since resolved: user authorized the push; origin/main current.)
- [Quick 260709-a5i]: Removed dead alpm_octopi_utils AUR_PKGS entry from install.sh — package no longer exists in AUR (only -git variant) and octopi 0.19.0 declares Conflicts With: alpm_octopi_utils, making paru hard-fail under --noconfirm during the INST-03 container gate
- [Quick 260709-buf]: theme_engine_reload now early-returns headless (no WAYLAND_DISPLAY/DBUS_SESSION_BUS_ADDRESS) — swaync-client -rs blocked forever in the headless container during stow.sh's first-boot seed (gate run 042501Z hung 45+ min); swaync call additionally pgrep-gated + timeout 5. container-run.sh now bounds the whole podman run with timeout (CONTAINER_TIMEOUT, default 3600s) so any future hang is a loud FAIL, not a stall
- [Quick 260709-ciu]: current.jpg wallpaper symlink retargeted to relative shaded-landscape.jpg and wallpaper-picker.sh switched to ln -sfr — the tracked symlink stored a host-absolute /home/aorus path that dangles for any other user, breaking materialyou on fresh installs (gate run 054046Z: theme-parity 246/1)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260709-a5i | Fix install.sh AUR conflict: remove dead alpm_octopi_utils | 2026-07-09 | 0ffa5d9 | [260709-a5i-fix-install-sh-aur-conflict-remove-dead-](./quick/260709-a5i-fix-install-sh-aur-conflict-remove-dead-/) |
| 260709-buf | Fix theme reload headless hang + gate step timeout | 2026-07-09 | 1e747eb, 50ad696 | [260709-buf-fix-theme-reload-headless-hang-gate-step](./quick/260709-buf-fix-theme-reload-headless-hang-gate-step/) |
| 260709-ciu | Make current.jpg wallpaper symlink relative (fresh-install materialyou fix) | 2026-07-09 | 49536d5 | [260709-ciu-fix-host-absolute-wallpaper-symlink-brea](./quick/260709-ciu-fix-host-absolute-wallpaper-symlink-brea/) |

### Pending Todos

[From .planning/todos/pending/ — ideas captured during sessions]

None yet.

### Blockers/Concerns

[Issues that affect future work]

- Source discrepancy: REQUIREMENTS.md coverage note and the roadmapper brief state "18 total" v1 requirements, but there are actually 19 requirement IDs. Roadmap maps all 19; coverage note corrected to 19 in REQUIREMENTS.md traceability.
- Research flags (verify empirically during Phase 1 planning): does Walker `hotreload_theme=true` remove the restart need? does GTK3 gtk.css file-monitoring make the Thunar restart optional? does `dbus-update-activation-environment` truly eliminate relogin?
- INST-03 evidence: container tier PASSED 2026-07-09 (verify/logs/run-20260709T060703Z — overall=PASS, theme-parity 287/0, install verify all-OK) after 4 quick-fix rounds (wlogout AUR move, alpm_octopi_utils removal, headless reload guard + gate timeout, relative wallpaper symlink). REMAINING: graphical VM tier human visual confirmation per VERIFICATION.md (steps through 8). Resolve before declaring Milestone 1 complete.

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Milestone 2 | OSD, Walker menus, media widget, polish, more themes | Deferred to v2 | 2026-07-07 |

## Session Continuity

Last session: 2026-07-09 (resumed)
Stopped at: INST-03 container tier PASSED (run-20260709T060703Z). Next: VM tier human visual confirmation per VERIFICATION.md, then milestone close.
Resume file: None
