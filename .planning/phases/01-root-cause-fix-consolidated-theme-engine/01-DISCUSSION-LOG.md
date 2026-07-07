# Phase 1: Root-Cause Fix & Consolidated Theme Engine - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-07
**Phase:** 1-Root-Cause Fix & Consolidated Theme Engine
**Areas discussed:** Engine shape & interface, Generated output location, Switch UX & disruption, Audit format & fix policy

---

## Engine shape & interface

| Option | Description | Selected |
|--------|-------------|----------|
| theme-apply \<name\> | One script handling static and dynamic, owning reload; picker/init become thin callers | ✓ |
| apply + reload split | Two commands: theme-apply writes, theme-reload restarts/reloads | |
| You decide | | |

**User's choice:** theme-apply \<name\> (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Own stow package | New theme-engine/ package; theming becomes first-class component | ✓ |
| Stay in hypr/scripts | Keep under hypr/.config/hypr/scripts/ | |
| You decide | | |

**User's choice:** Own stow package (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| One matugen path | Static presets become palette definitions fed to the same matugen templates; parity by construction | ✓ |
| Keep dual paths | Static keeps cp-based files with contract enforced by convention | |
| You decide | | |

**User's choice:** One matugen path (recommended) — research must confirm matugen 4.x preset-palette input; fall back if not

| Option | Description | Selected |
|--------|-------------|----------|
| Engine owns reload | Strip all matugen post_hooks; one ordered reload step after render | ✓ |
| Matugen post_hooks own it | Per-template hooks fire in both modes | |
| You decide | | |

**User's choice:** Engine owns it (recommended)

---

## Generated output location

| Option | Description | Selected |
|--------|-------------|----------|
| ~/.local/state/theme | XDG_STATE_HOME; survives cache wipes; outside repo | ✓ |
| ~/.cache/theme | Conventional in rices; semantically wipeable | |
| You decide | | |

**User's choice:** ~/.local/state/theme (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Native imports + symlinks | Per-app native include where available; symlink/direct-write otherwise | ✓ |
| Symlinks everywhere | Every colors.* file a symlink into state dir | |
| You decide | | |

**User's choice:** Native imports + symlinks (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Init applies default | theme-init falls back to default preset when no state; repo tracks zero color files | ✓ |
| install.sh pre-generates | Populate state dir at install time | |
| Both | Pre-generate AND fallback | |
| You decide | | |

**User's choice:** Init applies default (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Catppuccin Mocha | Keep current hardcoded fallback | ✓ |
| Material You (dynamic) | Generate from shipped default wallpaper on first boot | |
| You decide | | |

**User's choice:** Catppuccin Mocha (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Per-app files | One rendered file per app, shared variable names | ✓ |
| Palette + adapters | Canonical colors.json + derived per-app files | |
| You decide | | |

**User's choice:** Per-app files (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| @import from stowed gtk.css | Stowed gtk.css static, imports state-dir palette; no concatenation | ✓ |
| Engine renders full gtk.css | Template contains colors + base; symlink from ~/.config | |
| You decide | | |

**User's choice:** @import from stowed gtk.css (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| ~/.local/state/theme/ | State file next to generated output | ✓ |
| Keep ~/.cache/current-theme | No migration, but lost on cache wipe | |
| You decide | | |

**User's choice:** ~/.local/state/theme/ (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| One-time setup, no login hacks | Wiring established once; init stops deleting/recreating dirs | ✓ |
| Keep per-login normalization | Self-healing delete/recreate each login | |
| You decide | | |

**User's choice:** One-time setup, no login hacks (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Drop wofi from engine now | Never include a wofi template/target in the new engine | ✓ |
| Carry until Phase 3 | Keep wofi in fan-out until configs removed | |

**User's choice:** Drop from engine now (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| All ten, as today | Hyprland, waybar, kitty, swaync, wlogout, GTK3, GTK4, walker, yazi, vscodium | ✓ |
| Core visual only | Drop yazi/vscodium to best-effort | |
| You decide | | |

**User's choice:** All ten, as today (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| uwsm env file | Declare GTK_THEME once in ~/.config/uwsm/env | ✓ |
| Engine config owns it | Engine-sourced env file pushed into session | |
| You decide | | |

**User's choice:** uwsm env file (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Render-then-commit | Temp dir render, move on success, then reload | ✓ |
| In-place, fail loudly | Direct render; notify and stop on error | |
| You decide | | |

**User's choice:** Render-then-commit (recommended)

---

## Switch UX & disruption

| Option | Description | Selected |
|--------|-------------|----------|
| Restart only daemon | Never kill visible Thunar windows; next window opens themed | ✓ |
| Full restart, as today | Kill open windows for instant consistency | |
| You decide | | |

**User's choice:** Restart only daemon (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Hotreload, restart fallback | Verify walker hotreload_theme; hardened restart w/ elephant health check as fallback | ✓ |
| Always restart | Keep killing walker + elephant each switch | |
| You decide | | |

**User's choice:** Hotreload, restart fallback (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Dark-only for v1 | Hardcoded prefer-dark fine; seam for later light support | ✓ |
| Per-theme dark/light now | Doubles verification matrix | |
| You decide | | |

**User's choice:** Dark-only for v1 (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep as today | Success toast + loud errors; errors say "desktop unchanged" | ✓ |
| Errors only | Silent success | |
| You decide | | |

**User's choice:** Keep as today (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Engine/picker owns wallpaper | matugen set=false; awww only from picker/init | ✓ |
| Matugen owns it | Renderer keeps the side effect | |
| You decide | | |

**User's choice:** Engine/picker owns it (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, re-theme on pick | Explicit wallpaper pick in Material You mode re-runs theme-apply | ✓ |
| No, decouple them | Wallpaper pick never re-themes | |
| You decide | | |

**User's choice:** Yes, re-theme on pick (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Under ~2s | Soft target, sync matugen + signal reloads | |
| Whatever correctness costs | No latency target | |
| Sub-second, snappy | Hard snappy requirement | ✓ (initial) |

**User's choice:** Sub-second, snappy — user then asked to clarify the follow-up options before answering.

| Option | Description | Selected |
|--------|-------------|----------|
| Visible surface <1s | On-screen surface flips <1s; restart-based targets may finish 1–2s later, correct by next interaction | ✓ |
| Strictly everything <1s | All ten targets within 1s; forces hotreload-only, endangers atomicity | |

**User's choice:** Visible surface <1s (recommended)
**Notes:** Clarification explained the reliability trade-offs of a strict stopwatch guarantee vs perceived snappiness; user chose no correctness trade-offs.

---

## Audit format & fix policy

| Option | Description | Selected |
|--------|-------------|----------|
| AUDIT.md in .planning | Single structured report: severity, evidence, disposition | ✓ |
| GitHub-style issue list | One finding per file in findings/ | |
| You decide | | |

**User's choice:** AUDIT.md in .planning (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Theming + breakage only | Defer non-theming to P2/P3 per roadmap | |
| Fix everything found | One big cleanup | ✓ (initial) |
| Critical only, defer rest | Tightest phase | |

**User's choice:** Fix everything found — flagged as conflicting with roadmap phase boundaries; follow-up asked.

| Option | Description | Selected |
|--------|-------------|----------|
| Everything except P2/P3-owned | Fix all findings not explicitly covered by a Phase 2/3 requirement; defer those with phase assignment | ✓ |
| Truly everything, reshape roadmap | Pull P3 work into P1; deliberate roadmap change | |

**User's choice:** Everything except P2/P3-owned (recommended)
**Notes:** Keeps ROADMAP.md intact; AUDIT.md dispositions ensure deferred findings have owners.

| Option | Description | Selected |
|--------|-------------|----------|
| Audit first, then fix | Full AUDIT.md before engine build; adw-gtk-theme fix lands immediately | ✓ |
| Audit and fix interleaved | Fix per component while auditing | |
| You decide | | |

**User's choice:** Audit first, then fix (recommended)

| Option | Description | Selected |
|--------|-------------|----------|
| Scripted checks | theme-doctor script verifying invariants; reused by P2/P3 | ✓ |
| Manual checklist in AUDIT.md | Hand-run steps | |
| You decide | | |

**User's choice:** Scripted checks (recommended)

---

## Claude's Discretion

- Exact name/layout of the new stow package and script names (theme-apply, theme-doctor are working names)
- Internal engine structure, argument parsing, logging
- Per-app reload mechanics beyond captured decisions; reload ordering
- How theme-init and pickers invoke the engine
- Whether vscodium-theme.sh is absorbed into the engine or stays a helper

## Deferred Ideas

- Light theme support (per-theme dark/light attribute) — v2 THEMES item; engine leaves a seam only
