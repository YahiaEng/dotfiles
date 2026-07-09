# Architecture Research: v2.0 Desktop Expansion Integration

**Domain:** Personal Arch + Hyprland dotfiles — theme-engine-centered rice, GNU stow package-per-app
**Researched:** 2026-07-09
**Confidence:** HIGH for all findings sourced from direct repo inspection (the large majority of this document); LOW for the two findings explicitly marked websearch/webfetch (elephant custom-menu schema, Zen browser theming mechanism) — those need a phase-specific research spike before implementation, not roadmap-level trust.

This document supersedes the 2026-07-07 pre-implementation ARCHITECTURE.md (that research predates Phase 1's theme-engine consolidation — its "themes/{static,css,gtk,...}/ is the static source" claim is now stale; see the dead-code finding below). It answers one question only: **how do the six v2.0 feature groups plug into the existing `theme-engine`/stow architecture**, not whether the architecture itself should change. The pipeline (`theme-apply` → generate → commit → reload, `contract.json` as single source of truth, one stow package per app) is treated as fixed per PROJECT.md constraints.

## Standard Architecture (as it exists today, verified against the repo)

### System Overview

```
┌───────────────────────────────────────────────────────────────────────┐
│  TRIGGER LAYER (thin callers — D-01: only pick a name/action)          │
│  theme-switch.sh · wallpaper-picker.sh · wallpaper-switch.sh ·          │
│  theme-init.sh (autostart) · waybar-switch.sh (independent, no engine) │
└───────────────────────────┬─────────────────────────────────────────┘
                             │  theme-apply <name>
                             ▼
┌───────────────────────────────────────────────────────────────────────┐
│  theme-engine/.config/theme-engine/  (SINGLE OWNER of render+reload)   │
│  ┌────────────┐  ┌───────────┐  ┌───────────┐  ┌────────────────────┐ │
│  │generate.sh │→ │commit.sh  │→ │reload.sh  │  │contract.json (D-30) │ │
│  │matugen json│  │atomic     │  │ONE fan-out│  │single source of     │ │
│  │or image →  │  │rsync to   │  │owner;     │  │truth for the        │ │
│  │$TMP_DIR    │  │state dir; │  │hyprctl/   │  │state-dir file list, │ │
│  │            │  │walker+yazi│  │waybar/    │  │consumed by          │ │
│  │            │  │symlinks   │  │kitty/     │  │theme-doctor AND     │ │
│  │            │  │(D-07)     │  │swaync/gtk/│  │theme-parity so they │ │
│  │            │  │           │  │walker/    │  │can never drift      │ │
│  │            │  │           │  │vscodium   │  │                     │ │
│  └────────────┘  └───────────┘  └───────────┘  └────────────────────┘ │
└───────────────────────────┬─────────────────────────────────────────┘
                             │ renders into
                             ▼
┌───────────────────────────────────────────────────────────────────────┐
│  ~/.local/state/theme/  (generated, git-ignored — D-05/D-06)           │
│  hyprland.conf · waybar.css · kitty.conf · swaync.css · wlogout.css ·  │
│  gtk-3.0-colors.css · gtk-4.0-colors.css · walker-style.css ·          │
│  yazi.toml · vscodium.json · current-theme (metadata)                 │
└───────────────────────────┬─────────────────────────────────────────┘
                             │ consumed via @import / source / symlink
                             ▼
┌───────────────────────────────────────────────────────────────────────┐
│  STOWED APP CONFIGS (repo-tracked, never edited by the engine)         │
│  hyprland.conf `source =` · gtk.css/swaync/wlogout `@import url(...)`  │
│  · walker/yazi symlinked directly (no import syntax) · vscodium.json   │
│  merged into settings.json with jq                                    │
└───────────────────────────────────────────────────────────────────────┘
```

The rendering contract has two independent input modes feeding the **same** matugen templates (D-03 parity): `matugen json <palette>.json` (static preset, one hand-authored JSON per preset under `theme-engine/.config/theme-engine/palettes/`) or `matugen image <wallpaper>` (Material You, dynamic). Both write through `matugen -p "$TMP_DIR"`, and `commit.sh` is the only thing that ever touches the live `~/.local/state/theme/` tree.

### Component Responsibilities

| Component | Responsibility | Owns |
|-----------|----------------|------|
| `theme-engine/lib/generate.sh` | Render preset/dynamic palette through matugen into a scratch dir | matugen invocation only, never touches live state |
| `theme-engine/lib/commit.sh` | Atomic move of rendered tree into `~/.local/state/theme/`, wires the two apps with no `@import` mechanism (walker, yazi) via symlink | The only writer of the live state dir |
| `theme-engine/lib/reload.sh` | The single fan-out owner (D-04) — every `hyprctl reload`/`pkill -SIGUSR*`/`swaync-client -rs`/walker restart/vscodium merge lives here and nowhere else | Post-commit propagation to running processes |
| `theme-engine/lib/gtk.sh` | gsettings toggle, GTK4 accent-color hue mapping, GTK3 Thunar daemon restart (deferred-watcher pattern if a window is open) | GTK-specific reload subtleties |
| `theme-engine/contract.json` + `lib/contract.sh` | Declares the 10 output files + format tag per file; both `theme-doctor` and `theme-parity` read it so they can't drift | The state-dir output contract |
| `matugen/.config/matugen/config.toml` | One `[templates.X]` block per rendered file: `input_path` (repo template) → `output_path` (state-dir target, redirected via `-p`) | Template→output wiring, no post_hooks (stripped intentionally, D-04) |
| `theme-engine/palettes/*.json` | One hand-authored Material-You-role JSON per **static** preset name (`catppuccin`, `dracula`, `gruvbox`, `nord`, `rosepine`, `tokyonight`) — currently all dark, single `"default"` color set per role, no scheme/mode key | The actual live source of static presets |

## Critical Existing-Repo Fact That Changes the Plan

**`themes/.config/themes/{static,css,gtk,kitty,vscodium,yazi}/*` is dead code.** It is a separate stow package (still listed in `stow.sh`'s `PACKAGES` array and installed) containing a full second copy of hand-authored per-preset colors in five different formats. A repo-wide `grep -rn` across every script/toml/json/conf found **zero references** to any file under `themes/.config/themes/`. This predates the Milestone-1 theme-engine consolidation (the 2026-07-07 pre-implementation research still assumed this was the live static source — it is not, as of the shipped v1.0 pipeline) and was never removed. **Do not add new light presets here** — the live source of truth for static presets is `theme-engine/.config/theme-engine/palettes/*.json`, consumed by `generate.sh`. Treat `themes/` as a v2.0 cleanup candidate (delete or repurpose), not a place to extend.

## New vs Modified Components by Feature Group

### 1. New themed surfaces (hyprlock, swayosd, Zen browser, wallpaper-picker UI)

| Surface | Status | What's needed |
|---------|--------|----------------|
| **hyprlock** | **Already wired, MODIFY only** | `hyprlock.conf` already does `source = ~/.local/state/theme/hyprland.conf` (line 5) and already consumes `$primary`/`$secondary`/`$tertiary`/`$surface`/`$on_surface`/`$error`/`$image`. No new matugen template, no new contract entry. The "themed via shared pipeline" requirement is data-flow-complete today — the "redesigned look" work is pure `hyprlock.conf` editing (new `label`/`input-field` blocks, layout), reusing variables the pipeline already renders. If the redesign needs a role the current `hyprland-colors.conf` template doesn't emit (e.g. `tertiary_container`), extend that one existing template — still zero new contract entries. |
| **swayosd** | **NEW** | New stow package `swayosd/.config/swayosd/style.css` following the exact `@import url("../../.local/state/theme/swayosd.css");` pattern already used by `swaync/style.css` and `wlogout/style.css`. Requires: (a) new matugen template `matugen/.config/matugen/templates/swayosd-colors.css` + `[templates.swayosd]` block in `config.toml`, (b) new `contract.json` entry `{"name": "swayosd.css", "format": "gtk-css"}`, (c) `swayosd.service --user` enabled at install time (systemd unit ships with the package — an `install.sh` post-install `systemctl --user enable --now swayosd.service` step, not a stow concern), (d) no reload.sh change needed if swayosd hot-reloads its CSS; if it doesn't, add a restart/signal line to `reload.sh` mirroring the `pkill -SIGUSR2 waybar` pattern (verify swayosd's actual reload mechanism before wiring — flagged as an open question, not yet checked against upstream). |
| **Zen browser** | **NEW, structurally different** | Zen (Firefox-derived) reads `userChrome.css`/`userContent.css` from inside a **randomly-named profile directory** (`~/.zen/<hash>.default*`), which cannot be a fixed stow target. This breaks the "stow symlink to a fixed path" pattern used everywhere else in the repo. Needs a **profile-locator script** (new, e.g. `hypr/.config/hypr/scripts/zen-theme-link.sh`) that reads `profiles.ini` to resolve the live profile path and `ln -sf`s a rendered `zen-colors.css` (new matugen template + contract entry) into `<profile>/chrome/userChrome.css` (or `@import`s it, if a stow-owned `userChrome.css` can `@import file://` an absolute state-dir path — needs verification; Firefox-family browsers are stricter about `file://` imports in chrome CSS than GTK is). Add this as a new `reload.sh` step (`theme_engine_reload_zen`) that is a no-op if no Zen profile exists yet (same defensive style as the existing walker/elephant health gates) — Zen may not be installed/first-run on every machine. This is the riskiest new integration in the whole v2.0 set; treat it as needing its own research spike, not a roadmap-confident line item. |
| **Wallpaper-picker UI** | **MODIFY, likely a rewrite of the picker's front-end only** | Current `wallpaper-picker.sh` is a kitty-hosted `fzf` + `chafa` TUI — it has no CSS/GTK surface to theme at all (colors are hardcoded ANSI in the `fzf --color=` flags, not pipeline-driven). "Omarchy-level aesthetics" implies either (a) keep the fzf shape but derive its `--color=` flags from the live palette (cheap: source `~/.local/state/theme/kitty.conf`'s hex values in the script), or (b) replace it with a GTK4 layer-shell grid (bigger lift, would then need its own contract entry). Recommend (a) first — theming an existing terminal UI via the already-rendered kitty palette is a same-pattern extension, not a new pipeline component. The **restriction logic** (theme-aware wallpaper sets) is a separate, orthogonal change — see Data Flow Changes below. |

### 2. Utility scripts suite (screenshot, emoji, color picker, clipboard history, icon theme picker, nerd-font switcher)

**Location decision: extend `hypr/.config/hypr/scripts/`, do not create a new stow package**, unless a utility ships its own non-hypr config directory (swayosd is the only such case above). Rationale: every existing automation script in this repo already lives there (`theme-switch.sh`, `wallpaper-picker.sh`, `wallpaper-switch.sh`, `waybar-switch.sh`, `screenshot.sh`, `media-player.py`, `powermenu.sh`, `wlogout.sh`, `theme-init.sh`, `vscodium-extensions.sh`), `stow.sh` already `chmod +x`'s the whole directory on every stow run, and the "thin caller" convention (D-01) means these scripts don't need their own package boundary — they're not theming surfaces, they're actions.

| Utility | New or modify | Notes |
|---------|----------------|-------|
| Screenshot suite (capture/annotate/record) | **MODIFY** `screenshot.sh` (extend the existing `full/area/window` case) + **NEW** flags/functions for annotate (needs an external tool — `satty` or `swappy`, neither currently in `install.sh`) and record (`wf-recorder`, also not currently installed) | `grim`/`slurp` already in `PACMAN_PKGS`; annotate/record tools are net-new `install.sh` additions |
| Emoji picker | **Likely already solved** | `walker/config.toml` already enables `elephant-symbols` (prefix `.`) and `AUR_PKGS` already installs `elephant-symbols`. Verify this actually covers emoji, not just Unicode/math symbols, before treating this as a new build item — may just need a keybind/placeholder tweak rather than a new script |
| Color picker | **NEW** script wrapping `hyprpicker` (not currently in `install.sh` — net-new package dependency) | Simple: `hyprpicker -a` copies hex to clipboard; script only needs a `notify-send` wrapper matching this repo's UX convention |
| Clipboard history | **Already exists as an inline keybind**, not a script | `keybinds.conf` line 45: `bind = $mainMod, C, exec, cliphist list \| walker --dmenu \| cliphist decode \| wl-copy`. If v2.0 wants this as a dedicated walker menu/set instead of a bare `--dmenu` pipe, that's a `walker/config.toml` change (new `[sets.clipboard]`), not a new script |
| Icon theme picker (Thunar) | **NEW** script | Needs to enumerate `/usr/share/icons` + `~/.local/share/icons`, present via `walker --dmenu`, then `gsettings set org.gnome.desktop.interface icon-theme <name>` — same live-update mechanism `gtk.sh` already uses for `gtk-theme`/`color-scheme`, so this is additive to the existing GSettings pattern, not a new mechanism |
| Nerd-font switcher (vscodium/kitty/GTK/etc.) | **NEW** script, cross-cutting | Font is currently hardcoded per-app: `kitty.conf` (`font_family`), `gtk-3.0/settings.ini` + `gtk-4.0/settings.ini` (`gtk-font-name`), presumably waybar CSS `font-family` too. A font switcher needs to touch **multiple stowed static files** (not state-dir renders) or become a new contract-managed value. Recommend: treat font name as a new theme-engine-owned value (fold it into an existing render or add a small dedicated one) so switching font goes through the same render→commit→reload path instead of a bespoke sed-in-place-on-stowed-files script (sed-in-place would fight the "generated output never in git, static files never engine-written" boundary enforced since Phase 1). This is the one utility that actually touches the *pipeline*, not just adds a peripheral script. |

### 3. Omarchy-style Super-tap walker menu tree

Walker's `menus` provider (backed by `elephant-menus`, already installed and already listed in `walker/config.toml`'s `[providers] default` array) is the mechanism. **LOW confidence, websearch-only** — verify against `elephant generatedoc` output on this machine before committing to exact syntax in a plan:

- Custom menu definitions are files under (reported location, unverified on this install) `~/.config/elephant/menus/*.toml` — this needs a **new stow package** `elephant/.config/elephant/menus/` (elephant, not walker, owns this config surface — separate from `walker/.config/walker/config.toml`).
- Each menu file declares `name`/`name_pretty`/`icon` plus `[[entries]]` with `text`/`icon`/`actions`, and nests via a `submenu` field pointing at another menu's `dmenu:<name>` reference — this is how the tree (Utilities → screenshot/color-picker/emoji/... , AI dashboard → launchers + workspace jump, Game center, power, settings, keybind cheat-sheet) gets built: **one root menu + N leaf/branch menu files**, not one giant flat file.
- **Custom icons**: `icon` fields reference the system icon theme by name by default (per Walker docs) — supplying genuinely custom (non-icon-theme) icons needs either (a) a small local icon set installed into `~/.local/share/icons/hicolor/...` and referenced by name, or (b) absolute-path icon support if elephant-menus allows it (unverified — flag for the research spike).
- **Wiring the bare-$SUPER-tap trigger**: today, `keybinds.conf` line 33 binds `$mainMod, SUPER_L` (a bare Super tap) directly to `$app_launcher = walker` (the full multi-provider search). To make a bare tap open **the menu tree** instead, this bind must be repointed to a **new dedicated walker set** (e.g. `walker -s mainmenu`, following the exact same `[sets.runner]` pattern already in `walker/config.toml`) restricted to `providers = ["menus"]` with the root menu's `dmenu:` set as the entry point. App search (currently on the same bare-tap bind) needs to move fully onto the existing `$mainMod, R` (`$app_launcher_drun`) bind, which already exists and is unaffected.
- This is **MODIFY** `keybinds.conf` (repoint one bind) + **MODIFY** `walker/config.toml` (new `[sets.mainmenu]`) + **NEW** `elephant/` stow package with the menu tree, in that dependency order.

### 4. Waybar evolution

Waybar already has a proven 3-way layout-variant pattern: `config-{minimal,full,floating}.jsonc` + matching `style-{minimal,full,floating}.css`, switched at runtime by `waybar-switch.sh` (kills + relaunches `waybar -c ... -s ...`) and persisted via `~/.cache/current-waybar-layout`, read back by `waybar-launch.sh` on session start. **All three existing style files `@import` the exact same single rendered `~/.local/state/theme/waybar.css`** — meaning a new layout variant needs **zero matugen/contract.json changes**, only new config/style file pairs plus two small script edits.

| Item | Status | What's needed |
|------|--------|----------------|
| Vertical (left) layout | **NEW** `config-vertical.jsonc` + `style-vertical.css` (copy the `full` pair, change `"layer"`/anchor, rotate module groups, `@import` the same `waybar.css`) | **MODIFY** `waybar-switch.sh` (add `vertical` to `LAYOUT_LIST`/case) and `waybar-launch.sh` (add `vertical` to the validate-case) |
| Media-center module/popup (mpris) | **Already exists** — `config-full.jsonc` already has a built-in `"mpris"` module in `modules-center`. v2.0's "media center" ask is about expanding this to a **popup/expanded panel**, which waybar's built-in `mpris` module cannot do (inline text only) — this pushes toward the custom-`playerctl`-script-module path noted in this repo's STACK.md, i.e. **MODIFY→replace** the mpris entry with a `custom/mpris` module in `config-full.jsonc` (and any new vertical/OLED variant) whose `on-click` opens a themed GTK popover. Uses the already-installed `playerctl` and the already-present `hypr/.config/hypr/scripts/media-player.py` — check that script's current role before building a second popover | **MODIFY** `config-full.jsonc` (+ any new variant configs); possibly already partially built — verify `media-player.py` first |
| Notification-center button | **Already exists** — `custom/notification` module in `config-full.jsonc` already calls `swaync-client -swb`/`-t -sw`/`-d -sw`. v2.0 work here is replication into new layout variants, not new plumbing | **MODIFY** — copy the existing module block into vertical/OLED variants |
| OLED-safe behavior (auto-hide/transparency/pixel-shift) | **NEW mechanism, no precedent in repo** | None of Hyprland's config or waybar's own config currently does auto-hide or pixel-shift. Auto-hide is native waybar (`"layer": "top"` + a script toggling visibility, or a Hyprland `layerrule`); pixel-shift is unprecedented in this repo — likely a new lightweight timer script (via `hypridle` or a background loop) nudging bar margins by 1-2px periodically. This is genuinely new infrastructure, not a pattern extension — flag as needing its own design pass, not just a config edit. |

### 5. More static presets incl. light themes; theme-aware wallpaper sets

This is the data-flow-heaviest feature group — see the dedicated section below.

### 6. Bug-fix surfaces (wlogout, hyprlock timing, kitty startup)

None of these three touch the theme-engine pipeline structurally:

- **wlogout shutdown hang**: `wlogout.sh` toggles the wlogout layer-shell UI (`pkill`/launch with `--protocol layer-shell`); the actual shutdown action lives in `wlogout/.config/wlogout/layout` (not yet read in this pass — likely calls `systemctl poweroff` directly or via a wrapper). The redesign ("modern-rice standard") is a `layout`/`style.css` content change; `style.css` already `@import`s the state-dir `wlogout.css`, so re-theming after the redesign is free — this is a **MODIFY**, contained entirely inside the `wlogout/` package, no engine changes.
- **Hyprlock first-keystroke drop**: almost certainly a `hypridle.conf`/`hyprlock.conf` `grace`/focus-timing issue, unrelated to the theming pipeline (`hyprlock.conf`'s `general { grace = 5 }` is already set) — isolated fix inside `hyprlock.conf`/`hypridle.conf`.
- **Kitty slow startup**: `kitty.conf` is a stowed static file (not a theme-engine render target) — likely a shell-init cost (zshell/oh-my-posh) rather than a `kitty.conf` issue itself; profiling touches `zshell/` and possibly `kitty.conf`'s shell-integration settings, not the theme pipeline.

## Data Flow Changes

### A. Light/dark mode flag in theme presets

**Current state (verified):** `theme-engine/palettes/*.json` (e.g. `catppuccin.json`) have no scheme/mode key at all — every role is a single `"default": {"color": "#hex"}`, and all six existing presets are dark. Two independent places in the engine currently **hardcode dark unconditionally**, both of which must become mode-aware or light presets will render palettes correctly but the desktop chrome will stay dark regardless:

1. `theme-engine/lib/gtk.sh` lines 21-24 — unconditionally calls `gsettings set ... color-scheme "prefer-dark"` and `gsettings set ... gtk-theme "adw-gtk3-dark"`.
2. `gtk/.config/gtk-3.0/settings.ini` (stowed, static, **not** engine-rendered) — `gtk-application-prefer-dark-theme=1` is a hard client-side force that some GTK3 apps honor ahead of the live gsettings `color-scheme` value.

**This is the single most important data-flow addition for feature group 5.** Fixing only (1) without (2), or vice versa, will produce a "light preset that still looks dark" bug that is easy to mis-diagnose as a template problem. Both must move from static/hardcoded to mode-derived.

Two viable mechanisms for deriving mode, in order of recommendation:

- **(Preferred) Auto-detect from the rendered `surface`/`background` lightness**, the same technique `gtk.sh`'s existing `theme_engine_gtk4_accent()` already uses (Python `colorsys.rgb_to_hls`, HLS lightness channel) to map an arbitrary hex to a GNOME accent enum. Add a sibling `theme_engine_gtk_mode()` that reads the just-committed `gtk-4.0-colors.css` (or `hyprland.conf`) `surface`/`background` value, computes lightness, and picks `"prefer-dark"`/`"default"` + `"adw-gtk3-dark"`/`"adw-gtk3"` accordingly. This works uniformly for **both** static presets and Material You (a light wallpaper's dynamically-generated palette is correctly detected as light with zero manual annotation) — no new palette-JSON schema field needed at all.
- **(Fallback) Manual `"mode": "light"|"dark"` key** at the top of each palette JSON, read via `jq` in `gtk.sh` before the gsettings calls. Simpler to reason about per-preset but does nothing for Material You mode detection (would need its own separate luminance check anyway) — recommend only if the auto-detect approach proves unreliable on real palettes.

Either way, `gtk/.config/gtk-3.0/settings.ini`'s `gtk-application-prefer-dark-theme=1` line needs to stop being a static hardcode — either delete the line (let the portal/gsettings value be the sole authority, verify no GTK3 app regresses to light-by-default before doing this) or make `settings.ini` itself a new contract-managed render target (10th → 11th file), which is more invasive (breaks the "some GTK3 config is repo-static, only colors are engine-rendered" split held since Phase 1) — recommend the delete-and-verify path first as the minimal-diff fix.

New static presets themselves (e.g. `catppuccin-latte`) are added exactly like the existing six: **one new file under `theme-engine/palettes/`**, listed as a new case arm in `theme-switch.sh`'s `THEME_LIST`/`case` — zero `generate.sh`/`commit.sh`/`contract.json` changes needed, confirming this part of the pipeline already generalizes cleanly.

### B. Per-theme wallpaper metadata / wallpaper-picker restriction

**Current state (verified):** `wallpapers/Pictures/Wallpapers/` is a flat directory — `wallpaper-picker.sh` globs every image in it with no notion of which preset(s) a wallpaper "belongs to". The picker already reads `~/.local/state/theme/current-theme` (line 137) to decide whether to re-trigger Material You after a wallpaper change — this existing read is the hook point for restriction logic, not a new mechanism.

Two viable layouts, in order of recommendation:

- **(Preferred) Per-preset subdirectories**: `wallpapers/Pictures/Wallpapers/<preset-name>/*.jpg` (plus a top-level, unrestricted pool for Material You mode, since dynamic mode derives colors *from* the wallpaper — restriction is meaningless there and must stay disabled when `current-theme == materialyou`). `wallpaper-picker.sh`'s `find` glob changes from a single flat directory to `$WALLPAPER_DIR/$(cat "$STATE_FILE")` when in static-preset mode. Simple, filesystem-native, no new parsing dependency (this repo already avoids adding metadata-file parsers where a directory convention suffices, matching its general minimal-diff bias).
- **(Fallback) A manifest sidecar** (`wallpapers/Pictures/Wallpapers/manifest.json` mapping wallpaper filename → allowed preset name(s), for wallpapers that should be valid across multiple presets). More flexible (many-to-many) but adds a `jq` parse to a script that currently has zero JSON dependencies — only worth it if 1:1 directory-per-preset proves too rigid once real presets/wallpapers exist.

Either layout is a **pure `wallpapers/` package + `wallpaper-picker.sh` change** — it does not touch `theme-engine/` at all, since wallpaper selection happens *before* `theme-apply` is invoked (for Material You) or is independent of it (for static presets, where the wallpaper is decorative only).

### C. Menu-tree data flow (walker/elephant)

New, one-directional: `elephant/.config/elephant/menus/*.toml` (repo-tracked, stowed) → elephant daemon reads at query time → walker UI renders. This flow does **not** pass through `theme-engine` at all for its *content* — only its **appearance** (colors) comes from the pipeline, via the same `walker-style.css` (already a contract file, already symlinked by `commit.sh`) that themes the rest of walker. No new contract entry needed for the menu tree itself; it inherits walker's existing single stylesheet.

## Suggested Build Order

Ordered to put low-risk, pattern-confirming work first and to satisfy the two genuine hard dependencies in this set: **(a) light-mode plumbing must exist before light presets are added** (adding a light preset before fixing the two dark-hardcodes in `gtk.sh`/`settings.ini` produces a visibly broken feature), and **(b) the walker menu-framework/keybind repoint must exist before any submenu content is meaningful** (building Utilities/AI-dashboard/Game-center content against a menu system that isn't yet reachable from a keybind is untestable work).

1. **Cleanup + guardrail**: resolve the dead `themes/` package (delete or repurpose) before anyone accidentally edits it thinking it's live — pure risk-reduction, zero dependencies, do first.
2. **Bug fixes (wlogout shutdown, hyprlock keystroke, kitty startup)** — isolated, no dependency on anything else in this list, safe to parallelize with everything below, and de-risks the base before layering new surfaces on top.
3. **Light/dark mode plumbing** (`gtk.sh` mode detection or flag, `settings.ini` hardcode removal) — must land **before** step 4.
4. **New static presets incl. light themes** — depends on 3.
5. **Theme-aware wallpaper directories + wallpaper-picker restriction logic** — independent of 3/4 in mechanism, but only becomes *meaningful* once light presets (4) exist to restrict against; sequence after 4 for testability, though it could technically be built in parallel.
6. **New themed surfaces: hyprlock redesign (cheap, already wired), swayosd (new template+contract+package), Zen browser (spike first — LOW confidence)** — each is independent of the others; do hyprlock first (near-zero plumbing risk), swayosd second (proven `@import` pattern), Zen last (needs its own research spike before committing to a plan).
7. **Utility scripts suite** — independent of everything except the font-switcher item, which depends on deciding whether font becomes a contract-managed value (a mini version of step 3/4's pattern: pipeline change before the feature that depends on it). Screenshot/color-picker/icon-picker/emoji have no cross-dependencies and can be built in any order once `install.sh` package additions (hyprpicker, satty/swappy, wf-recorder) land.
8. **Walker menu framework**: `elephant/` stow package with the *root* menu + keybind repoint (`keybinds.conf` bare-Super rebind, new `[sets.mainmenu]` in `walker/config.toml`) — this is the dependency gate for step 9.
9. **Menu tree content** (Utilities, AI dashboard + workspace rules, Game center, power, settings, keybind cheat-sheet submenus) — depends on 8. Utilities submenu additionally depends on step 7 (it wraps the utility scripts as menu actions), so sequence Utilities after both 7 and 8 land; the other submenus (Game center, power, settings, cheat-sheet) only depend on 8.
10. **Waybar evolution**: vertical layout (near-zero risk, proven 3-way pattern) → OLED-safe behavior (genuinely new infra, no precedent — budget more time) → media-center popup upgrade (depends on deciding `media-player.py`'s current role first — check before planning). All three are independent of 1-9 and can run in parallel with the whole rest of this list.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Editing `themes/.config/themes/*` believing it's live

**What people do:** See six per-preset files already present under `themes/gtk/`, `themes/kitty/`, etc. and assume that's where a new preset or a light-mode variant belongs.
**Why it's wrong:** Verified zero references to this package anywhere in the repo's scripts/configs — it is dead weight from before the Milestone-1 theme-engine consolidation. Time spent editing it produces no visible effect and no error message to signal the mistake.
**Instead:** All static preset content lives in `theme-engine/.config/theme-engine/palettes/*.json`, consumed by `generate.sh`.

### Anti-Pattern 2: Fixing only one of the two dark-mode hardcodes

**What people do:** Add a light preset, notice `gtk.sh`'s `gsettings ... prefer-dark` call, fix that one line, ship it.
**Why it's wrong:** `gtk-3.0/settings.ini`'s `gtk-application-prefer-dark-theme=1` is a separate, static, non-engine-rendered hardcode that some GTK3 apps honor independent of the live `color-scheme` gsetting — leaves a "light preset that still renders dark in Thunar" bug that looks like a template/render problem but isn't.
**Instead:** Treat both hardcodes as one atomic change (see Data Flow Changes §A) and verify against an actual GTK3 app (Thunar), not just `gsettings get`.

### Anti-Pattern 3: Adding a new waybar layout by touching matugen/contract.json

**What people do:** See waybar has a `waybar.css` contract entry and assume a new layout variant needs its own new contract entry / matugen template.
**Why it's wrong:** All existing layout variants (`minimal`/`full`/`floating`) already `@import` the **same single** rendered `waybar.css` — a new layout is purely a new `config-*.jsonc`/`style-*.css` pair plus two switcher-script edits. Adding a redundant second contract entry would silently fork the palette between layouts and break `theme-parity`'s guarantees.
**Instead:** New layout = new config/style pair only, reusing the existing single waybar contract file.

### Anti-Pattern 4: Bespoke sed-in-place font/config switching outside the engine

**What people do:** Write a nerd-font-switcher script that directly `sed`s `kitty.conf`, `gtk-3.0/settings.ini`, waybar CSS, etc. in place.
**Why it's wrong:** Directly mutates repo-tracked (stow-owned) files at runtime, which fights the hard-won "generated output never in git, static config never engine-written" boundary enforced since Phase 1 (`git status` must stay clean after any theme action — this was a stress-tested invariant in the v1.0 milestone). A sed-based switcher would make `git status` dirty after every font change and desync from a fresh `stow --restow`.
**Instead:** Route font selection through the same render→commit→reload path as colors (new template variable or new contract file), exactly as recommended in the utility-scripts table above.

## Integration Points

### External daemons/services

| Component | Integration pattern | Notes |
|-----------|---------------------|-------|
| `elephant` (menus provider) | Config files under `~/.config/elephant/menus/*.toml`, read by the already-running `elephant` daemon at query time | Verify exact directory + schema via `elephant generatedoc` on this machine before planning (websearch-only confidence today) |
| `swayosd.service --user` | Systemd user service shipped by the `swayosd` package; theming via GTK-CSS `@import` from the state dir, same pattern as swaync/wlogout | Confirm whether swayosd hot-reloads its CSS or needs a restart signal in `reload.sh` |
| Zen browser profile | `profiles.ini`-mediated, randomly-named profile directory — cannot be a static stow target | Needs a locator script; treat as its own research spike |
| GSettings/dconf + `xdg-desktop-portal-gtk` | Already the live-update layer for dark/light + accent (per this repo's STACK.md findings) | Extend, don't replace — mode detection plugs into the exact same `gsettings set` calls already in `gtk.sh` |

### Internal boundaries

| Boundary | Communication | Notes |
|----------|----------------|-------|
| Trigger scripts ↔ `theme-engine` | Positional CLI arg (`theme-apply <name>`) only — D-01 thin-caller contract | Any new trigger (icon-theme-picker, font-switcher if pipeline-routed) must follow this exact shape, not reimplement render/reload |
| `theme-engine` ↔ stowed app configs | One-directional: engine writes `~/.local/state/theme/*`, app configs `@import`/`source`/symlink from it, engine never writes into a stowed repo path | Any new themed surface must add its own `@import`/`source` line in its own stowed config — the engine does not and should not know app-specific config syntax beyond the format tag in `contract.json` |
| `waybar-switch.sh`/`waybar-launch.sh` ↔ `theme-engine` | **None** — waybar layout switching is entirely independent of theme switching; both read the same rendered `waybar.css` but neither script calls the other | Keep this independence when adding the vertical layout — do not make layout switching call `theme-apply` or vice versa |

## Sources

- Direct repository inspection (HIGH confidence, ground truth) — read in full: `theme-engine/.config/theme-engine/{theme-apply,contract.json,lib/*.sh,palettes/catppuccin.json}`, `matugen/.config/matugen/config.toml`, `walker/.config/walker/config.toml`, `waybar/.config/waybar/{config-full.jsonc,style-*.css}`, `hypr/.config/hypr/{hyprland.conf,hyprlock.conf,config/keybinds.conf,config/autostart.conf,scripts/{theme-switch,waybar-switch,wallpaper-picker,screenshot,wlogout}.sh}`, `gtk/.config/gtk-{3,4}.0/{settings.ini,gtk.css}`, `swaync/.config/swaync/style.css`, `wlogout/.config/wlogout/style.css`, `themes/.config/themes/**` (confirmed dead via repo-wide grep), `install.sh` (PACMAN_PKGS/AUR_PKGS), `stow.sh` (PACKAGES array), `kitty/.config/kitty/kitty.conf`, `.planning/PROJECT.md`
- websearch: "walker elephant-menus provider config.toml custom menu submenu icon example" — confidence LOW
- webfetch (benz.gitbook.io/walker/customization/custom-menus): custom menu file format, `submenu` nesting field — confidence LOW, needs verification against `elephant generatedoc` on this machine before a plan is written against it

---
*Architecture research for: v2.0 Desktop Expansion integration into the existing theme-engine/stow architecture*
*Researched: 2026-07-09*
