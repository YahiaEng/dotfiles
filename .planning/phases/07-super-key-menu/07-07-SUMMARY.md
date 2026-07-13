---
phase: 07-super-key-menu
plan: 07
subsystem: ui
tags: [elephant, hyprland, gaming, steam, lutris, gamemode, mangohud, menus, toml]

# Dependency graph
requires:
  - phase: 07-03
    provides: install.sh package declarations (steam+multilib, lutris, gamemode, mangohud) and AUR (heroic, protonup-qt)
  - phase: 07-05
    provides: root menu with `submenu = "game-center"` already wired; stow-parity guard in elephant-restart.sh
provides:
  - Game Center submenu (Steam, Lutris, Heroic, ProtonUp-Qt, Gaming mode)
  - gaming-mode-toggle.sh (runtime-only, fully reversible eye-candy/idle toggle)
  - Session-scoped reset of gaming-mode to OFF at login (D-28)
affects: [phase-08-waybar-evolution]

tech-stack:
  added: []
  patterns:
    - "Runtime-only compositor mutation: `hyprctl keyword` never a config-file write, so the git-clean invariant holds and a crash cannot persist a half-state"
    - "Session-scoped state reset at autostart: a toggle that can disable safety features (idle lock) must reset to OFF at login, so a crash-while-ON can never silently persist"
    - "LD_PRELOAD wrappers (gamemoderun/mangohud) belong at the GAME layer, not the CLIENT layer — they propagate into every child process"

key-files:
  created:
    - elephant/.config/elephant/menus/game-center.toml
    - hypr/.config/hypr/scripts/gaming-mode-toggle.sh
  modified:
    - hypr/.config/hypr/config/autostart.conf
    - stow.sh
  deleted: []

requirements-completed: [MENU-04]

verification:
  - claim: "menus:game-center registers live with elephant"
    ref: "`elephant listproviders` lists menus:game-center; symlink resolves into the repo"
    status: pass
  - claim: "Gaming mode is fully reversible — restores EXACT pre-toggle values"
    ref: "hyprctl getoption captured before/after across two independent ON->OFF cycles: rounding 12->0->12, blur/animations/shadow 1->0->1"
    status: pass
  - claim: "Runtime-only — never writes a config file"
    ref: "sha256sum of ~/.local/state/theme/hyprland.conf identical across a full ON->OFF cycle; git status clean for all touched paths"
    status: pass
  - claim: "Idle inhibit engages and releases"
    ref: "hypridle confirmed in T (SIGSTOP) state while ON; confirmed resumed after OFF"
    status: pass
  - claim: "D-28 session reset to OFF at login"
    ref: "autostart.conf unconditionally resets ~/.cache/gaming-mode to off; human logout/login test"
    status: pass
  - claim: "All four launchers start real applications"
    ref: "Human-tested from the live menu after packages were installed; Steam confirmed launching post-fix"
    status: pass
  - claim: "gamemode daemon is actually live (gamemoderun is only a shim)"
    ref: "systemctl --user is-active gamemoded -> active; gamemoded -t self-test engaged"
    status: pass

duration: ~45min (executor run + package install + Steam root-cause + closeout)
completed: 2026-07-13
status: complete
---

# Phase 07 Plan 07: Game Center Summary

## Accomplishments

- **MENU-04 delivered.** Game Center submenu with Steam, Lutris, Heroic, ProtonUp-Qt and a Gaming mode toggle, registered live as `menus:game-center`.
- **`gaming-mode-toggle.sh`**: disables blur/animations/shadow/rounding at runtime only (`hyprctl keyword`, never a config write), inhibits `hypridle` via SIGSTOP/SIGCONT, hides waybar, and restores the *exact* pre-toggle values on toggle-off — measured across two independent cycles.
- **D-28 session reset**: `autostart.conf` unconditionally resets `~/.cache/gaming-mode` to `off` at login, so a crash while gaming mode is ON can never leave the idle lock permanently disabled.
- **The executor caught a real bug in its own OFF path before committing**: the state-file read-back tripped the `set -e`/`pipefail` failure class this repo's own `reload.sh` warns about (a `grep -m1` miss propagating as a pipeline failure). Reproduced with `bash -x`, fixed, re-verified with a fresh cycle.

## The Headline Finding: LD_PRELOAD Wrappers Belong at the Game Layer, Not the Client Layer

D-26 specifies that gamemode and mangohud are "wired into the Steam/Lutris **launch commands** as env/wrappers." Implemented literally, that produced `uwsm app -- gamemoderun mangohud steam` — and **Steam would not start**, failing with *"Steam encountered an unexpected error during startup (0x03008)"*.

**Root cause:** `gamemoderun` and `mangohud` both work by `LD_PRELOAD`ing a library into the target process. Steam's launcher is a shell script that spawns an entire process tree — bash, the reaper, srt-logger, and `steamwebhelper` (a Chromium/CEF process). The preload propagates into **every** child: `gamemoded` was observed registering `/usr/bin/bash` and dozens of transient PIDs as "games" (with a storm of ioprio errors), while MangoHud injected a Vulkan/GL overlay into Steam's own CEF UI processes.

**A/B proven live:** wrapped → a `Steam :: Unexpected Transport Error` window and no usable client. Plain → a healthy `Sign in to Steam` window with `steamwebhelper` alive. **Lutris is unaffected** (verified: it launches fine wrapped), so its wrapper is unchanged.

**Resolution (deviation from D-26's mechanism, preserving its intent):** Steam launches plain. D-26's intent — per-launch, *never* global toggle state — is fully preserved and arguably better served, because the correct application point for Steam is **per-game Launch Options** (`gamemoderun mangohud %command%`), which is strictly *more* per-launch than wrapping the client.

**The plan's own acceptance criterion encoded the bug.** T-07-24's verify asserts that `grep` finds `gamemoderun|mangohud` in the Steam and Lutris launch commands — that check passes while Steam is completely unusable. This is the same failure class the phase keeps rediscovering: **a grep is not a launch**, just as a TOML parse is not a registration (07-05) and a doc read is not a binary check (07-06).

## Game Center Label Descope (D-27)

The toggle entry's label is a neutral `"Gaming mode"` with no ON/OFF state suffix. elephant 2.21.0's `menus` provider only reads a TOML's entries at daemon startup (`LoadMenus()` runs once). The one genuinely dynamic mechanism — confirmed by extracting the provider's embedded README directly from `usr/lib/elephant/menus.so` — is a Lua-scripted menu whose `GetEntries()` re-runs per query when `Cache` is unset; adopting it would replace the whole declarative TOML with a first-use-in-this-repo mechanism and break the plan's own `tomllib`-based verification. The alternative, having the toggle rewrite its own git-tracked TOML on every flip, was rejected as a violation of the repo's git-clean invariant. A neutral label never asserts a state it cannot keep truthful; real state is surfaced by the toggle's own notification and by `~/.cache/gaming-mode`.

## Task Commits

| Commit | What |
|--------|------|
| 59e9f14 | gaming-mode-toggle.sh — runtime-only, reversible toggle |
| ecafd4d | session-scoped gaming-mode reset to OFF (D-28) |
| 6809d61 | game-center.toml — 4 launchers + toggle entry |
| 7645b35 | fix: unwrap Steam launch (0x03008 root cause above) |

## Issues Encountered

**All six pacman packages and both AUR packages were declared in `install.sh` (07-03) but never installed on this machine**, so the four launcher entries could not be exercised until the human installed them mid-checkpoint (`steam lutris gamemode mangohud ollama aichat`, `paru -S heroic-games-launcher-bin protonup-qt`). Installing them immediately exposed **two latent bugs that every repo-side gate had passed**: the Steam wrapper crash above, and 07-06's broken aichat config seed (fixed in `1fe4c7c`). Both had shipped as "correct by construction, not verified against the installed binary."

Also verified: `gamemoded` is actually running as a user service — `gamemoderun` is only a shim, and had the daemon been absent, the Steam/Lutris entries would have launched while GameMode silently never engaged.

## Next Phase Readiness

- 07-08 (cheat-sheet) is the last plan in the phase; it modifies `windowrules.conf` and `main.toml`, both touched by earlier wave-3 plans, so it must run after these commits (it does).
- Phase 8 owns waybar and can read `~/.cache/gaming-mode` for an indicator (D-27's deferred half). `gaming-mode-toggle.sh`'s waybar hide/show is marked in-script as Phase 8's re-point target.

---

*Completed: 2026-07-13*
