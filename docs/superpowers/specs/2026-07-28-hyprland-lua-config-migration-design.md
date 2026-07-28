# Hyprland Lua Config Migration — Design

**Date:** 2026-07-28
**Status:** Approved, pending roadmap insertion
**Target:** v3.0, new Phase 14 (Dashboard Drawer and successors shift down)

## Context

Hyprland 0.56.1 emits a deprecation warning on startup:

> You are using the .conf config format, support for which will be removed in hyprland 0.57

This is **not** a syntax revision. Hyprland is replacing hyprlang with **Lua**; the config
moves to `$XDG_CONFIG_HOME/hypr/hyprland.lua`. Deprecation began at 0.55 and upstream
stated hyprlang would be maintained for "1–2 releases starting from 0.55."

Two properties of the transition shape everything below:

- **The formats cannot coexist.** Hyprland selects one at startup and will not load a
  legacy config if Lua is active. The check happens once, at launch.
- **0.56 still supports both.** The migration can therefore be built and validated on a
  running system, with rollback by renaming a single file. After 0.57 the same work would
  be done on a compositor that will not start.

The second point is the entire reason for doing this now.

## Constraints

- Arch + Hyprland + uwsm + stow + matugen, per CLAUDE.md — this extends the existing
  setup, it is not a rewrite.
- Theme switching must keep working through one pipeline in both static-preset and
  matugen dynamic modes.
- Everything must remain reproducible from `install.sh` + `stow.sh`.
- `hyprlock` and `hypridle` are separate binaries with their own hyprlang parsers. Nothing
  indicates they move to Lua on Hyprland's schedule, so hyprlang output must survive for
  them.

## Decisions (locked)

| Decision | Choice | Rationale |
|---|---|---|
| Timing | Migrate now, on 0.56 | Both formats work today; rollback is one `mv`. Post-0.57 the fallback disappears. |
| Token contract | Rework to **data**, not generated config syntax | Eliminates the load-order hazard and the syntax-injection class of bug. |
| Roadmap placement | Insert as Phase 14 | Phases 14–17 all consume the design tokens this rewrites. Migrating first avoids retrofitting four phases of surface. |

## Architecture

### The contract change is 2 of 30 files

`theme-engine/contract.json` declares 30 generated files. Exactly two are Hyprland-format:

| File | Current format | After |
|---|---|---|
| `hyprland.conf` | `hypr-vars` (22 `$colour` vars) | → `hyprland.lua`, new `lua-table` format |
| `hyprland-motion.conf` | `hypr-motion` (9 speed vars + `animations { bezier = }`) | → **merged into the same table** |
| `hyprlock.conf` | `hypr-vars` | **unchanged** — hyprlock keeps its own parser |

The remaining 27 entries (GTK CSS, SCSS, QML, TOML, JSON, kitty, fzf…) are untouched.

### Why merging colours and motion is the point

`hypr/.config/hypr/hyprland.conf` currently carries this hazard, documented in-file:

> `source = ~/.local/state/theme/hyprland-motion.conf` — **MUST come before**
> `config/animations.conf` … an undefined variable there is a hard parse error
> ("cannot parse as an int")

A Lua table has no load-order semantics. A missing key is `nil` — defaultable at the point
of use — rather than a parse failure that prevents the compositor starting. Collapsing the
two generated fragments into one table removes:

- the ordering constraint between motion tokens and `animations.conf`
- the "generated file is executable config syntax" coupling
- most of what `scripts/motion-lint` exists to detect (raw and dangling motion values
  injected into config text)

### Two emitters, no new cost

The theme engine already renders `hyprland.conf` and `hyprlock.conf` from separate matugen
templates over shared colour data. After the migration the Hyprland template emits a Lua
table and the hyprlock template continues emitting hyprlang. The "two formats" requirement
is satisfied by a split that already exists.

## Components

### Static config

The 8 files under `hypr/.config/hypr/` become Lua modules, preserving the current modular
split — **923 lines**:

| File | Lines |
|---|---|
| `config/windowrules.conf` | 307 |
| `config/keybinds.conf` | 209 |
| `config/permissions.conf` | 121 |
| `hyprland.conf` | 101 |
| `config/autostart.conf` | 92 |
| `config/animations.conf` | 61 |
| `config/monitors.conf` | 17 |
| `config/env.conf` | 15 |

(A naive `find -name '*.conf'` over the tree reports 1,277, but that sweeps in
`hyprlock.conf`, `hypridle.conf` and the 5 motion-lint test fixtures — none of which are
ported here.)

Note the shape of the work: `windowrules.conf` and `keybinds.conf` alone are 56% of it, and
both are dense, repetitive, high-count declarations. That is where converter output needs
the most scrutiny and where the equivalence gate earns its cost — `hyprctl -j binds` covers
keybinds directly.

A community converter — [hyprconf2lua](https://github.com/Prateek-squadron/hyprconf2lua)
(Python) or [hyprlang2lua](https://github.com/EIonTusk/hyprlang2lua) (Go) — provides a
mechanical first pass. Both must be treated as a **draft, not a result**: their coverage
claims are against standard configs, and this config references `$primary`,
`$motion_enabled` and friends that are defined in files generated at runtime and therefore
unresolvable by any static converter.

### Theme engine

- `lib/motion.sh` — emit Lua table fields instead of `hypr-motion` text.
- matugen `templates/hyprland-colors.conf` → a Lua-table template.
- `contract.json` — replace the two entries with one, and register the `lua-table` format.
- `lib/contract.sh` — add validation for the new format.
- `lib/reload.sh` — confirm the reload path still applies (`hyprctl reload` semantics under
  Lua need verification; see Open Questions).

### motion-lint

`scripts/motion-lint` and its fixtures under `scripts/tests/motion-fixtures/` currently
parse hyprlang. Its purpose — catching raw or dangling motion values — still applies to the
Lua consumer side, so it needs a Lua-aware path plus new fixtures. Its hyprlang path stays
for the hyprlock output.

## Verification

The central risk is silent divergence across 923 ported lines. `waybar-equivalence-check`
already establishes the pattern in this repo: snapshot a pre-refactor baseline, diff after,
report-only, never mutate.

A new `hypr-equivalence-check` follows it, with one necessary difference: waybar's effective
config resolves statically, whereas Hyprland's is observable only at runtime.

- `--snapshot` — while still booted on the `.conf` config, parse the config files for every
  option key actually set, dump each via `hyprctl -j getoption`, and capture
  `hyprctl -j binds` and `hyprctl -j animations`. Commit as the baseline.
- default mode — after switching to Lua, re-dump and diff. Exit 0 only on exact match.

Verified available: `hyprctl -j getoption decoration:rounding` returns
`{"option": "decoration:rounding", "int": 12, "set": true }`.

This converts the correctness question from a reading exercise into a gate.

## Rollback

`hyprland.conf` and its `config/` tree remain on disk, untouched, for the duration of the
phase. Because Hyprland selects a format once at startup, rollback at any point is:

```
mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.disabled
```

followed by a compositor restart. The legacy tree is deleted only after the equivalence gate
passes and the Lua config has survived normal use.

## Phase breakdown

Approximately five plans:

1. **Baseline** — build `hypr-equivalence-check`, capture and commit the `.conf` baseline.
   Must land before any config edit.
2. **Static port** — converter pass plus hand-review of the 8 files into Lua modules.
3. **Token contract** — theme-engine and matugen emit the merged Lua table; `contract.json`
   and `lib/contract.sh` updated.
4. **motion-lint** — Lua-aware path and fixtures; hyprlang path retained for hyprlock.
5. **Cutover** — equivalence gate green, soak under normal use, then retire the legacy tree
   and update `install.sh` / `stow.sh` as needed.

## Open questions (resolve during phase research)

These are **not** yet verified and must not be assumed:

- **The actual Lua API.** The wiki pages fetched during this design did not document how
  options, keybinds, window rules, `exec-once`, or nested blocks like
  `decoration { blur { … } }` are expressed in Lua. Any Lua syntax shown in this document
  or in the discussion that produced it is **illustrative only**. The phase's research step
  must establish the real API from the current wiki and `hl.meta.lua` stubs.
- **Exact removal version.** Upstream said "1–2 releases starting from 0.55"; the 0.56.1
  runtime warning names 0.57. Treated as 0.57 for planning. Worth reconfirming before
  cutover, but it does not change the plan.
- **`hyprctl reload` under Lua.** Whether live reload behaves identically affects
  `lib/reload.sh` and the theme-apply path.
- **Whether every set option is introspectable** via `hyprctl getoption`. If some are not,
  the equivalence gate needs a documented, explicit list of what it cannot cover — silent
  gaps in a verification tool are worse than a smaller tool with known limits.
- **hyprlock/hypridle roadmap.** If they later move to Lua, the hyprlang emitter can be
  retired; until then it stays.

## Out of scope

- Any change to the other 27 contract entries.
- Converting `hyprlock.conf` / `hypridle.conf`.
- Redesigning the theming pipeline beyond the two Hyprland-format outputs.
- Rewriting keybinds, window rules, or animation curves — this is a format migration, and
  behaviour must be provably identical. Improvements belong in a later phase.
