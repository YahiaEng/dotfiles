# Phase 7: Super-Key Menu - Research

**Researched:** 2026-07-13
**Domain:** Hyprland keybind engineering (bare-modifier-tap binds) + elephant/walker declarative menu provider + greenfield AI/gaming launcher integration
**Confidence:** HIGH on the two headline risks (RQ1/RQ2, both empirically proven live on this machine); MEDIUM-HIGH on secondary items (package landscape, Zen SSB windows, gaming-mode runtime toggles); LOW→flagged where training-only

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** $SUPER-tap opens the MENU only. App launcher moves to its own dedicated bind (Super+Space). `bind = $mainMod, SUPER_L, exec, walker` is replaced, not shared. `Super+R` (runner set) stays as-is.
- **D-02:** True tap-only behaviour must be researched and PROVEN. Find/validate a mechanism that fires ONLY on a bare Super press-and-release, demonstrated to not shadow existing binds. A new package is acceptable if correctness requires it.
- **D-03 (safety, launch requirement):** Before ANY Super-bind experiment: (a) reserve a never-shadowed kill-bind and test it in isolation first, (b) have the Phase 4-style second-TTY recovery procedure open and documented.
- **D-04:** MENU-01's regression sweep is a rerunnable scripted gate + human pass — parses `keybinds.conf`, asserts every declared bind is registered in `hyprctl binds`, flags shadowing/duplication.
- **D-05:** Walker's `menus` (elephant) provider is the target — SPIKED FIRST. Must prove it expresses submenus, actions, icons before committing; fallback is bash + `walker --dmenu` chain (Phase 5 exit-130 pattern).
- **D-06:** Drill-down in place; Esc/Backspace goes back a level; breadcrumb in placeholder. Global cross-submenu search is a bonus-if-free, NOT required.
- **D-07:** Icons are Nerd Font glyphs rendered as entry text, decoupled from the icon-theme picker. FiraCode NF verified to carry needed glyphs.
- **D-08:** Menu reuses existing `walker-style.css` (contract target). No dedicated menu skin, zero new contract targets, zero new parity fixtures.
- **D-09:** Every GUI launch from the menu goes through `uwsm app -- …`, exactly like `keybinds.conf`. Shell scripts invoked bare.
- **D-10:** Root = exactly six requirement groups, ordered by task frequency, Power LAST. No pinned flat quick-actions at root.
- **D-11:** Root order/wording/glyphs are Claude's discretion within D-10.
- **D-12:** Screenshot is a sub-submenu under Utilities (region/window/full/record-toggle). Utilities = Screenshot›, Emoji, Colour picker, Clipboard — existing Phase 6 scripts unchanged.
- **D-13:** Icon-theme picker and font switcher move to Settings, not Utilities (do vs configure split). Keybinds unchanged.
- **D-14:** Settings = Theme switch, Wallpaper, Icon theme, Font, Waybar layout, Network, Bluetooth, Audio, Display.
- **D-15:** Appearance entries reuse existing scripts as-is.
- **D-16:** Walker→floating-kitty transition is accepted and intentional for entries needing kitty-graphics previews. The menu is a launcher for pickers, not a replacement.
- **D-17:** Network = `nmtui` in a floating kitty window (Phase 5/6 pattern). Rejected: nm-connection-editor, impala/iwd.
- **D-18:** Bluetooth/Audio/Display: bluetooth manager (blueman or overskride — researcher's call), `pavucontrol`, `nwg-displays`.
- **D-19:** Power launches existing `~/.config/hypr/scripts/wlogout.sh` — same surface as Super+Shift+Q. Rejected: inline walker power list.
- **D-20:** `hypr/.config/hypr/scripts/powermenu.sh` is DELETED (unbound, unreferenced, drifted).
- **D-21:** AI dashboard = (1) Zen web-app windows for Claude/ChatGPT/Gemini/Perplexity with dedicated windowrule classes, (2) Claude Code/CLI agent in kitty, (3) ollama + TUI chat client in kitty.
- **D-22:** Local models stop at ollama + a TUI client. open-webui REJECTED. Exact TUI client Claude's discretion, official repo strongly preferred.
- **D-23:** install.sh installs/enables ollama but pulls NO model (unattended container gate).
- **D-24:** AI Workspace = reserved named workspace + windowrules + auto-layout, idempotent (picking twice = one set of windows). Must not collide with Super+1..0.
- **D-25:** Game Center launchers = Steam, Lutris, Heroic, ProtonUp-Qt. Steam requires multilib enabled explicitly by install.sh. Heroic is AUR.
- **D-26:** Gaming mode toggle: eye-candy off via `hyprctl keyword` runtime-only (never rewrite config files); idle/lock inhibit; gamemode+mangohud wired per-launch (not global toggle); waybar hide as a thin, single-call, re-pointable abstraction.
- **D-27:** Gaming mode surfaced as one toggle entry + notification + state file (no waybar indicator this phase).
- **D-28:** Gaming mode is session-scoped — resets to OFF on session start.
- **D-29:** Keybind cheat-sheet has two surfaces (walker searchable list + kitty "View all" table) sharing one parser.
- **D-30:** Descriptions come from `keybinds.conf` trailing `# comments`; every bind lacking one gets back-filled. No side-car file.
- **D-31:** Cheat-sheet generated live on open (parse `keybinds.conf` each time).
- **D-32:** Cheat-sheet must include the new Phase 7 binds.
- **D-33:** ~10 new packages. Official repos strongly preferred; every AUR package gets a human legitimacy check at execution time.
- **D-34:** Container gate must stay green — nothing interactive/network-heavy added to unattended install.

### Claude's Discretion

- Root menu ordering within D-10; exact entry wording; exact Nerd Font glyph per entry.
- Ordering of entries within each submenu.
- Ollama TUI chat client choice; bluetooth manager choice (blueman vs overskride).
- AI workspace number/layout (must not collide with Super+1..0; idempotent).
- Exact tap-only mechanism (D-02), including whether it warrants a new package.
- Kill-bind's exact chord (D-03) and Super+Space launcher bind's exact form (D-01).
- Cheat-sheet table formatting/grouping; shared parser's implementation.
- Gaming-mode state-file location and notification wording.
- Whether menu definitions live in one file or several (if `menus` provider wins).

### Deferred Ideas (OUT OF SCOPE)

- Waybar gaming-mode indicator — Phase 8.
- Global cross-submenu search — bonus-only, not required.
- A dedicated walker menu skin — rejected (drift/parity cost).
- open-webui / local web AI UI — rejected.
- Auto-pulling a default ollama model on install — rejected.
- Native AI desktop clients (AUR electron wrappers) — rejected in favor of Zen web-app windows.
- Pinned flat quick-actions at the menu root — rejected.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MENU-01 | Tapping $SUPER alone opens main walker menu, all $SUPER+key combos keep working, verified by regression sweep | RQ1: `bindr = $mainMod, SUPER_L, exec, …` with default (non-transparent) shadowing — VERIFIED against the installed Hyprland 0.55.4 binary's own bind-flag semantics + official wiki example. D-04 gate design below. |
| MENU-02 | Utilities submenu invokes utility scripts | RQ2 GO on `menus` elephant provider — TOML entries with `actions` map wired to existing Phase 6 scripts. Submenu nesting for Screenshot. |
| MENU-03 | AI dashboard: launcher submenu + dedicated Hyprland AI workspace | Zen `--new-window` + WM_CLASS caveat (below); named-workspace idempotent pattern (`workspace name:ai`). |
| MENU-04 | Game center: launcher submenu (Steam etc.) | Package legitimacy audit below; multilib enable requirement confirmed absent from current install.sh. |
| MENU-05 | Power menu: lock/logout/suspend/reboot/shutdown | D-19 delegates to existing `wlogout.sh` — zero new research needed, confirmed unchanged file. |
| MENU-06 | Settings menu: theme switch/wallpaper/network/etc. | `menus` provider `actions` map invoking existing scripts + new `nmtui` floating-kitty wrapper (follows `wallpaper-switch.sh` pattern, confirmed live). |
| MENU-07 | Searchable keybind cheat-sheet generated from keybinds.conf | `keybinds.conf` comment convention confirmed (some binds already carry `# desc`, others don't — D-30 backfill required). Shared-parser design below. |
</phase_requirements>

## Summary

Both headline risks resolve to a **GO with a native, package-free mechanism**, verified directly against the binaries installed on this machine (not from training data or the currently-outdated live wiki, which is now Lua-only as of Hyprland 0.55).

**RQ1 (tap-only Super bind):** Hyprland's own `hyprlang` bind-flag system already has exactly the mechanism this phase needs: a **release bind that targets its own modifier is shadowed (suppressed) by default whenever a combo bind consumes the same modifier first** — shadowing is Hyprland's *default* behavior; the `t` (transparent) flag is what you'd add to *opt out* of it. The syntax `bindr = SUPER, SUPER_L, exec, <cmd>` is the officially wiki-documented "modkey-only binding" pattern (0.54 wiki, still the correct reference since hyprlang itself hasn't changed — only the *default* config syntax moved to Lua in 0.55, hyprlang remains fully supported and is what this repo already uses). No input-layer tool (keyd/interception-tools/xremap) is required.

**RQ2 (elephant `menus` provider):** Fully capable. Live-verified on the installed `elephant 2.21.0` binary: TOML menu files under `~/.config/elephant/menus/*.toml` register as distinct providers (`menus:<name>`), support submenus (`submenu = "childname"` on an entry — auto-gets an `open` action that requests the child provider), multiple named actions per entry (a plain string command run via `sh -c`, or a map of named actions), free-text `icon`/`text` fields (Nerd Font glyphs work as plain text), and a documented `Parent`/`menus:parent` back-navigation action. **Critical operational finding not in the phase's decision log:** `~/.config/elephant/` does not currently exist on this machine, and elephant only scans its `menus/` subdirectory **once at daemon startup** — new/changed TOML files are invisible to the running daemon until elephant itself is restarted. This must be an explicit step in the plan (a small `elephant-relaunch` step alongside the existing walker-relaunch pattern), not an assumption.

**Primary recommendation:** Ship the tap-only bind as a plain hyprlang `bindr` (no third-party package), ship the menu tree as `elephant-menus` TOML files consumed by walker's existing `[providers]`/`[sets]` mechanism (a new `[sets.menu]` block scoped to `providers = ["menus:main"]`, mirroring the already-working `[sets.runner]` pattern), and correct two assumptions baked into CONTEXT.md before planning: **`protonup-qt` is AUR-only** (not official-repo, contradicting D-25/D-33's assumption), and **Zen gives every window the same WM_CLASS regardless of URL** (D-21's "dedicated windowrule class per AI app" needs a title-regex fallback, not class matching).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tap-only Super detection | Compositor (Hyprland keybind engine) | — | Hyprland's own `bindr`+shadowing already solves this; no user-space daemon needed |
| Menu tree state/navigation | Backend daemon (elephant `menus` provider) | Frontend (walker GTK4 UI, rendering only) | elephant owns menu definitions, drill-down state, and action dispatch; walker is a thin display+input layer over elephant's socket protocol |
| Menu action execution | Backend daemon (elephant, `sh -c` exec) | — | Actions run as `sh -c` subprocesses spawned by elephant itself, not by walker |
| Picker hand-off (wallpaper/font/icon/nmtui/cheat-sheet table) | Floating kitty (separate process) | Backend daemon (menu action that launches it) | elephant's action is just `uwsm app -- kitty …`; the picker itself is Phase 5/6's existing fzf-in-kitty machinery, untouched |
| Keybind regression gate | Shell script (theme-engine-style rerunnable gate) | Hyprland (`hyprctl binds` as ground truth) | Parses `keybinds.conf` (declared intent) and cross-checks against `hyprctl binds -j` (compositor's actual registered state) — same "check the installed binary, not the file" discipline as `theme-doctor` |
| Gaming-mode toggles | Compositor (`hyprctl keyword`, runtime-only) | Shell script (state file + notification) | Never touches config files on disk (D-26); state file is a session-scoped probe only, not a config source of truth |
| AI/Game launcher windows | Application (Zen, kitty, Steam, etc.) | Compositor (windowrules for placement) | Menu only execs; placement/class matching is windowrules, not menu logic |

## Standard Stack

### Core

| Component | Version (installed, verified) | Purpose | Why Standard |
|-----------|-------------------------------|---------|---------------|
| Hyprland | 0.55.4 (`hyprctl version`) | Compositor; owns tap-only bind via `bindr` | Already the project's compositor; `bindr`+default-shadow is Hyprland's own documented mechanism, zero new dependency |
| elephant | 2.21.0 (`elephant version` / `pacman -Qi`) | Backend data/menu daemon behind walker | Already running (`exec-once = uwsm app -- elephant`), already the walker backend for every other provider in this repo |
| elephant-menus | 2.21.0 (`pacman -Qi elephant-menus`) | The `menus` provider plugin (`/usr/lib/elephant/menus.so`) | Already installed since 2026-07-09 per `pacman -Qi` install date; simply unconfigured (`~/.config/elephant/` doesn't exist yet) |
| walker | 2.16.2 (`walker --version`) | GTK4 frontend, renders elephant's menu items via `[providers]`/`[sets]` | Already the project's launcher; `walker -s <name>` set-scoping is the exact mechanism already used for `$app_launcher_drun` (`walker -s runner`) |

### Supporting (new packages this phase)

| Package | Repo | Purpose | Verified |
|---------|------|---------|----------|
| steam | multilib | Game launcher | `pacman -Si steam` → `Repository: multilib`, `1.0.0.87-1` [VERIFIED: pacman -Si, local] |
| lutris | extra | Game launcher | `0.5.22-1` [VERIFIED: pacman -Si, local] |
| heroic-games-launcher-bin | **AUR** | Epic/GOG launcher | `2.22.0-1`, AUR URL confirmed, upstream `heroicgameslauncher.com` [VERIFIED: paru -Si, local] — matches D-33's own AUR flag |
| protonup-qt | **AUR (not official — corrects D-25/D-33)** | Proton-GE version manager | `2.15.1-1`, AUR URL confirmed, upstream `davidotek.github.io/protonup-qt` [VERIFIED: paru -Si, local] |
| ollama | extra | Local LLM runtime | `0.31.2-1` [VERIFIED: pacman -Si, local] |
| aichat | extra | Ollama-capable TUI chat client (D-22 pick) | `0.30.0-3`, Rust, MIT/Apache-2.0, Arch official packager [VERIFIED: pacman -Si, local] |
| gamemode | extra | Per-launch game perf daemon | `1.8.2-3` [VERIFIED: pacman -Si, local] |
| mangohud | extra | Per-launch perf overlay | `0.8.4-1` [VERIFIED: pacman -Si, local] |
| pavucontrol | extra | Audio settings GUI | `1:6.2-1` [VERIFIED: pacman -Si, local] |
| nwg-displays | extra | Monitor arrangement, writes Hyprland monitor config | `0.4.3-1` [VERIFIED: pacman -Si, local] |
| blueman | extra (D-18 pick — see rationale below) | Bluetooth manager | `2.4.6-2` [VERIFIED: pacman -Si, local] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native `bindr` shadowing (RQ1) | keyd / interception-tools / xremap (all present in official `extra`, e.g. `keyd 2.6.0-5` [VERIFIED: pacman -Si]) | Only needed if live regression testing (D-03/D-04 gate) proves default shadowing insufficient on this exact binary/kernel combo. Adds a second input-layer daemon, root-level udev/systemd config, and a new failure class outside Hyprland's own config — reject unless the native path empirically fails. |
| `elephant menus` provider (RQ2) | bash + `walker --dmenu` chain (Phase 5 exit-130 pattern) | Fallback only. Every submenu becomes a separate script + separate walker invocation; no shared drill-down state, breadcrumb must be hand-rolled into placeholder text per script. More code, more drift surface — reject unless the D-05 spike (see Verification Architecture) fails on the actual daemon. |
| blueman (D-18 pick) | overskride | overskride is AUR-only (`0.6.6-1`, GTK4/libadwaita, more modern look) [VERIFIED: paru -Si, local]; blueman is official-repo, GTK3 (matches this repo's existing GTK3-class utility pattern, e.g. nm-connection-editor precedent explicitly rejected in D-17 for being "heavy GUI"), and needs no AUR legitimacy gate. D-33's "official repos strongly preferred" is decisive here — **blueman recommended.** |
| aichat (D-22 pick) | oterm | oterm is AUR-only, Python/Textual, purpose-built for Ollama specifically. aichat is official-repo, Rust, multi-provider (openai-compatible endpoint config covers Ollama's `localhost:11434/v1`), matches this repo's "official repo strongly preferred" bias — **aichat recommended.** Both are genuine terminal TUIs (kitty-themed for free); oterm remains a documented fallback if aichat's Ollama integration proves unsatisfactory at execution time. |

**Installation (illustrative — plan owns exact PACMAN_PKGS/AUR_PKGS placement):**
```bash
sudo pacman -S steam lutris ollama aichat gamemode mangohud pavucontrol nwg-displays blueman
paru -S heroic-games-launcher-bin protonup-qt   # AUR — human legitimacy gate required (D-33)
```

**Version verification:** All versions above confirmed via `pacman -Si <pkg>` / `paru -Si <pkg>` run live against this machine's configured repos (core/extra/multilib/AUR) on 2026-07-13, not training data.

## Package Legitimacy Audit

> `gsd-tools query package-legitimacy check` only supports `npm|pypi|crates` ecosystems — not applicable to pacman/AUR. The table below is the manual-verification equivalent the tool would otherwise perform, run directly against `pacman -Si`/`paru -Si` on this machine (D-33's "human package-legitimacy check").

| Package | Registry | Age/Evidence | Source Repo | Verdict | Disposition |
|---------|----------|---------------|--------------|---------|-------------|
| steam | multilib (official) | Long-standing official Arch package | n/a (proprietary) | OK | Approved — requires multilib enabled (see Pitfall below) |
| lutris | extra (official) | Long-standing official Arch package | github.com/lutris/lutris | OK | Approved |
| ollama | extra (official) | Long-standing official Arch package | github.com/ollama/ollama | OK | Approved |
| aichat | extra (official) | Official Arch packager (Carl Smedstad), MIT/Apache-2.0 | github.com/sigoden/aichat | OK | Approved |
| gamemode | extra (official) | Long-standing official Arch package (Feral Interactive) | github.com/FeralInteractive/gamemode | OK | Approved |
| mangohud | extra (official) | Long-standing official Arch package | github.com/flightlessmango/MangoHud | OK | Approved |
| pavucontrol | extra (official) | Long-standing official Arch package | freedesktop.org/software/pavucontrol | OK | Approved |
| nwg-displays | extra (official) | Official Arch package | github.com/nwg-piotr/nwg-displays | OK | Approved |
| blueman | extra (official) | Long-standing official Arch package | github.com/blueman-project/blueman | OK | Approved |
| heroic-games-launcher-bin | AUR | Well-known project, matches upstream `heroicgameslauncher.com` exactly | github.com/Heroic-Games-Launcher/HeroicGamesLauncher | OK (AUR) | Approved — `checkpoint:human-verify` required per D-33 before install.sh gains it |
| protonup-qt | AUR | Well-known project, matches upstream `davidotek.github.io/protonup-qt` | github.com/DavidoTek/ProtonUp-Qt | OK (AUR) | Approved — `checkpoint:human-verify` required per D-33; **also corrects CONTEXT.md's assumption that this was an official-repo candidate — it is AUR-only** |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none — every AUR candidate resolves to a well-known, actively-maintained upstream matching its AUR description. Both AUR packages still require the standard `checkpoint:human-verify` gate before `install.sh` is updated, per D-33's blanket policy (not because of any specific red flag found here).

## Architecture Patterns

### System Architecture Diagram

```
 Super key (bare tap)                    Super+<key> combo (existing)
         │                                          │
         ▼                                          ▼
 ┌───────────────────┐                    ┌──────────────────────┐
 │ Hyprland           │                    │ Hyprland              │
 │ bindr = SUPER,      │◄── shadowed if ───│ bind = $mainMod,<key>  │
 │ SUPER_L, exec,      │    combo fired      │ exec, <existing cmd>  │
 │ walker -s menu      │    during press     │ (168 existing binds)  │
 └─────────┬───────────┘                    └───────────────────────┘
           │ (only on a clean tap)
           ▼
 ┌────────────────────────┐   query "menus:main"   ┌───────────────────────┐
 │ walker (GTK4 frontend)  │────────────────────────▶│ elephant (daemon)      │
 │ [sets.menu] providers = │◄────query results───────│ menus provider          │
 │  ["menus:main"]         │                          │ reads ~/.config/       │
 └───────────┬─────────────┘                          │ elephant/menus/*.toml  │
             │ select "Utilities ›"                   └───────────┬────────────┘
             ▼ (menus:open action)                                 │
 ┌────────────────────────┐   ProviderUpdated: "menus:utilities"   │
 │ walker list swaps to    │◄────────────────────────────────────────┘
 │ Utilities submenu        │
 └───────────┬───────────────┘
             │ select leaf entry (e.g. "Region")
             ▼
 ┌────────────────────────┐
 │ elephant Activate():     │  run = entry.Actions["region"] or menu.Action
 │ sh -c "<action string>"  │  e.g. ~/.config/hypr/scripts/capture-region.sh
 └────────────────────────┘
             │
             ▼
 Existing Phase 6 script (unchanged) OR uwsm app -- <GUI app> (D-09)
```

### Recommended Project Structure

```
elephant/                          # NEW stow package — creates ~/.config/elephant/
└── .config/elephant/menus/
    ├── main.toml                  # root: 6 entries, each `submenu = "<child>"`
    ├── utilities.toml             # Screenshot›, Emoji, Colour picker, Clipboard
    ├── screenshot.toml            # sub-submenu: region/window/full/record-toggle
    ├── settings.toml              # 9 entries (theme/wallpaper/icon/font/waybar/network/bt/audio/display)
    ├── ai-dashboard.toml          # Claude/ChatGPT/Gemini/Perplexity/Claude Code/Local models/AI Workspace
    └── game-center.toml           # Steam/Lutris/Heroic/ProtonUp-Qt/Gaming mode toggle

walker/.config/walker/config.toml  # EXISTING — add [sets.menu] providers = ["menus:main"]
hypr/.config/hypr/config/
├── keybinds.conf                  # EDIT: remove SUPER_L press-bind, add bindr tap + Super+Space + kill-bind
└── autostart.conf                 # EDIT: gaming-mode reset-to-OFF hook

hypr/.config/hypr/scripts/
├── keybind-doctor                 # NEW — D-04 rerunnable regression gate
├── nmtui-launch.sh                # NEW — D-17 floating-kitty nmtui wrapper (wallpaper-switch.sh pattern)
├── cheat-sheet-parser.sh          # NEW — D-29/30/31 shared keybinds.conf parser (sourced by both surfaces)
├── cheat-sheet-view-all.sh        # NEW — kitty "View all" table launcher
├── gaming-mode-toggle.sh          # NEW — D-26/27/28
├── ai-workspace.sh                # NEW — D-24 idempotent workspace launcher
└── powermenu.sh                   # DELETE (D-20)
```

### Pattern 1: Tap-only Super via default bind shadowing

**What:** A release-bind on the modifier key itself, using the modifier as BOTH the target modmask and the activating key, with no `t` (transparent) flag.
**When to use:** Any "bare modifier tap" requirement in hyprlang.
**Example (source: Hyprland 0.54 wiki, confirmed still-valid syntax for hyprlang — this repo has not migrated to Lua config):**
```conf
# Binding modkeys only — official pattern (wiki: "To only bind modkeys, you
# need to use the TARGET modmask (with the activating mod) and the r flag")
bindr = SUPER, SUPER_L, exec, uwsm app -- walker -s menu

# Official wiki's own canonical demonstration of this exact pattern:
# "Open wofi on first press, closes it on second"
# bindr = SUPER, SUPER_L, exec, pkill wofi || wofi
```
**Why it works without shadowing every combo:** the `t` (transparent) bind flag's documented purpose is "cannot be shadowed by other binds" — its existence proves the DEFAULT (flag absent) is shadowable. Hyprland's `KeybindManager` internally tracks a per-keybind `shadowed`/`releasePending` state (confirmed present in the installed `hyprland` package's own shipped C++ headers, `/usr/include/hyprland/src/managers/KeybindManager.hpp`) specifically to suppress a pending release-bind once a combo has consumed the modifier during the press phase.

### Pattern 2: elephant `menus` provider — TOML menu + submenu + action

**What:** A declarative menu tree, one TOML file per menu, submenus reference other menus by name.
**When to use:** All six Phase 7 root submenus.
**Example (source: `elephant-menus` package's own bundled README, read directly from the installed package's build source `~/.cache/paru/clone/elephant-menus/v2.21.0.tar.gz` → `elephant-2.21.0/internal/providers/menus/README.md`):**
```toml
# ~/.config/elephant/menus/main.toml
name = "main"
name_pretty = "Menu"

[[entries]]
text = " Utilities"          # glyph as plain text (D-07) — no `icon` field needed
submenu = "utilities"          # auto-gets the `open` action; Enter drills down

[[entries]]
text = " Power"
actions = { "open" = "~/.config/hypr/scripts/wlogout.sh" }  # D-19: not a submenu at all
```
```toml
# ~/.config/elephant/menus/utilities.toml
name = "utilities"
name_pretty = "Utilities"
parent = "main"                # enables the menus:parent back-navigation action

[[entries]]
text = " Screenshot"
submenu = "screenshot"

[[entries]]
text = " Emoji"
actions = { "open" = "~/.config/hypr/scripts/emoji-picker.sh" }
```
**Verified live on this machine (2026-07-13):** created a throwaway `~/.config/elephant/menus/test.toml` with `name = "test"`; `elephant listproviders` (which does its own fresh `providers.Load(false)` + `common.LoadMenus()` in-process, not a query to the running daemon) printed `menus:test`, proving the TOML schema, the `~/.config/elephant/menus/` directory convention, and the `menus:<name>` provider-identifier format are all correct against the actual installed 2.21.0 binary. Test artifact removed after verification.

### Anti-Patterns to Avoid

- **Assuming `~/.config/elephant/` already exists:** it does not on this machine as of 2026-07-13. `common.ConfigDirs()` (in elephant's own source) only appends `$XDG_CONFIG_HOME/elephant` to its scan list if the directory already exists via `os.Stat` — an absent directory silently yields zero menu files loaded, with no error. The stow package that lays down `menus/*.toml` must itself create the parent `~/.config/elephant/` directory (stow does this automatically when the package tree includes it).
- **Assuming new/edited menu TOML files are picked up live:** `LoadMenus()` runs exactly once, inside `providers.Load(setup=true)`, at elephant daemon startup (`cmd/elephant/elephant.go` service path). elephant is currently started via a bare `exec-once = uwsm app -- elephant` in `autostart.conf` (**not** a systemd unit, confirmed via `systemctl --user list-unit-files | grep elephant` returning nothing beyond a transient scope) — so it will NOT restart itself when files change. The plan must add an explicit elephant-restart step (e.g. `pkill elephant` then re-exec, mirroring the existing `walker-relaunch.sh`/health-gate pattern already documented in `theme-engine/.config/theme-engine/lib/reload.sh`) at least once after the menu files first land, and again any time a `.toml` menu definition changes. `RefreshOnChange` (per-menu file-watch, enables `Cache=true` + fsnotify) only helps a menu that is *already loaded* watch its *own* declared files for content changes — it does not discover brand-new menu files.
- **Using Zen's `class:` in windowrules to distinguish AI web-app windows (D-21):** confirmed live — `hyprctl clients -j` shows a running Zen window's `class` as `zen` regardless of the URL loaded, and Zen's own `.desktop` file declares `StartupWMClass=zen` unconditionally. `zen-browser --help` exposes no `--class`/`--name`/app-id override flag. **Use `title:` regex matching in windowrules instead** (each Zen window's title reflects the loaded page, e.g. a Claude tab title contains "Claude"), OR test the Mozilla-toolkit-inherited `MOZ_APP_REMOTINGNAME=<name>` env var (Firefox 124+ documented mechanism for exactly this, [CITED: Mozilla Firefox release notes via WebSearch, not verified live against this Zen build] — the executor must confirm this env var actually changes Zen's Wayland `app_id` before relying on it for windowrule class-matching; if it doesn't, title-regex is the guaranteed-working fallback).
- **Adding an input-layer daemon (keyd etc.) before proving native shadowing insufficient:** would introduce a second privileged input-consuming process, udev rules, and a new failure class, for a problem the compositor already solves by design. Reserve as a fallback only if the D-04 regression gate empirically fails after the native `bindr` approach ships.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Bare-modifier-tap detection | A custom evdev/libinput tap-timing daemon | Hyprland's native `bindr` + default shadowing | Already solves it; zero new process, zero new failure surface, wiki-documented pattern |
| Menu drill-down/back-navigation state | A bash script tracking "current menu level" in a state file | elephant `menus` provider's `submenu`/`Parent`/`menus:parent` mechanism | The daemon already tracks this per-query; hand-rolling it in bash duplicates logic that breaks on concurrent walker instances or crashed sessions |
| Keybind regression detection | A human manually pressing every one of 30+ chords each time keybinds.conf changes | A scripted `hyprctl binds -j` vs `keybinds.conf` diff (D-04) | This is exactly the class of problem `theme-doctor`/`theme-parity` already solve for the theme pipeline — same house pattern, same rerunnable-gate philosophy |
| Gaming-mode eye-candy toggle | Editing/regenerating hyprland.conf decoration blocks | `hyprctl keyword decoration:blur:enabled 0` etc. (confirmed live-settable via `hyprctl getoption`) | Runtime-only, D-26's own explicit constraint; editing config files risks desync with the theme pipeline's own config ownership |

**Key insight:** every "hard" problem in this phase (tap detection, hierarchical menu state, regression proof) already has a first-class mechanism in the installed binaries. The research risk was never "can this be built" — it was "does the installed binary actually support the documented behavior," which is exactly what this session verified empirically rather than trusting training-data assumptions.

## Common Pitfalls

### Pitfall 1: `bindr = SUPER, SUPER_L` written with an EMPTY modifier field

**What goes wrong:** `bindr = , SUPER_L, exec, …` (empty first field) is a well-documented historical footgun — GitHub issue #6946 (2024, Hyprland v0.41.2 era) shows multiple users hitting exactly this non-working form, and the maintainer's own fix was "drop the modifier" from the *wiki text*, but the wiki now shows the WORKING form is `bindr = SUPER, SUPER_L, …` (target modmask = SUPER, activating key = SUPER_L) — the empty-modifier form remained broken per later comments in the same thread.
**Why it happens:** Confusion between "no modifier required" (empty field) and "the modifier IS the key" (modifier field = SUPER, key = SUPER_L) — they are NOT equivalent for release binds.
**How to avoid:** Always write `bindr = SUPER, SUPER_L, exec, …` (or `bindr = $mainMod, SUPER_L, …` using this repo's existing `$mainMod = SUPER` variable) — matches the "Binding modkeys only" section of the official wiki verbatim.
**Warning signs:** Bind registers in `hyprctl binds -j` (syntax accepted) but never fires on a bare tap — check `"release": true` is present in the JSON and re-verify the modifier field is non-empty.

### Pitfall 2: Steam installed without multilib enabled

**What goes wrong:** `pacman -S steam` fails outright, or (worse, if multilib was enabled manually mid-session on a dev box but never in `install.sh`) works on the dev machine but fails on every fresh install — exactly the class of bug this project's fresh-install container gate exists to catch.
**Why it happens:** `install.sh` currently has **zero** references to `multilib` or `pacman.conf` editing (confirmed via `grep -n "multilib\|pacman.conf" install.sh` → no matches). The `[multilib]` block IS enabled in `/etc/pacman.conf` on this dev machine already, which would silently mask the gap during local testing.
**How to avoid:** `install.sh` must explicitly uncomment/append the `[multilib]` section of `/etc/pacman.conf` (idempotently — check first) and run `pacman -Sy` before the `steam` install, BEFORE the container-gate `--core-only` path runs (D-25's own explicit mandate). Since the container gate strips hardware-specific steps, this must live in `section_core_rice`, not `section_hardware`.
**Warning signs:** Container gate (`verify/container-run.sh`) passes but a genuinely fresh bare-metal install fails at the `steam` line — exactly Phase 3's INST-03 two-tier gate rationale for why container-only testing isn't sufficient (this is a config-file-state gap, not a hardware gap, so it WILL reproduce in a container — catch it there).

### Pitfall 3: elephant config directory doesn't exist / stale menu cache

**What goes wrong:** Menu TOML files stowed correctly, but the menu shows empty or shows an old version, because elephant's directory scan is startup-only.
**Why it happens:** Confirmed live (see Pattern 2 above) — `ConfigDirs()` requires `~/.config/elephant` to already exist via `os.Stat`, and `LoadMenus()` runs once at daemon start.
**How to avoid:** Ensure the new `elephant/` stow package's directory tree creates `~/.config/elephant/menus/` (stow handles directory creation automatically from symlink targets), and add an elephant restart step to whatever install/first-boot flow lays down menu definitions — do not assume `stow.sh` alone is sufficient.
**Warning signs:** `elephant listproviders` (a fresh in-process load, always correct) shows the menu but the LIVE walker session (talking to the already-running daemon over its socket) does not — this discrepancy is the tell that the daemon itself needs restarting, not the config.

### Pitfall 4: Zen web-app windows share one WM_CLASS

**What goes wrong:** Windowrules written against `class:^(zen)$` match ALL Zen windows (main browsing window included), not just the intended AI web-app window — D-21's "dedicated windowrule class so it can be placed" silently fails to discriminate.
**Why it happens:** Confirmed live via `hyprctl clients -j` — every Zen window (regardless of which URL was opened with `--new-window`) reports `class: "zen"`. Firefox-family browsers set WM_CLASS/app_id at the toolkit level, not per-window-content.
**How to avoid:** Match on `title:` regex instead (title reflects the loaded page and IS distinct per AI service), or have the executor test `MOZ_APP_REMOTINGNAME=<distinct-name> zen-browser --new-window <url>` against a live `hyprctl clients -j` check before committing to a class-based windowrule design.
**Warning signs:** A windowrule intended for just the "Claude" web-app window also floats/places the user's regular Zen browsing window.

## Code Examples

### Kill-bind (D-03) — tested FIRST, in isolation, before any tap-bind experiment

```conf
# Reserved, never-shadowed escape hatch — bind form (not release), fires
# immediately on press, cannot collide with anything since Escape carries
# no other $mainMod meaning in this file (confirmed via grep of keybinds.conf).
bind = $mainMod, Escape, exec, pkill walker
```

### Full tap-only + launcher-relocation diff shape (D-01/D-02)

```conf
# ── REMOVE ──
# bind = $mainMod, SUPER_L, exec, $app_launcher

# ── ADD ──
bind = $mainMod, Escape, exec, pkill walker           # D-03 kill-bind, verify FIRST
bind = $mainMod, SPACE, exec, $app_launcher            # D-01 relocated launcher
bindr = $mainMod, SUPER_L, exec, uwsm app -- walker -s menu   # D-02 tap-only menu
```

### walker `[sets.menu]` scoping (mirrors the already-working `[sets.runner]` block)

```toml
# Source: walker/.config/walker/config.toml (existing pattern, confirmed live)
[sets.menu]
providers = ["menus:main"]
placeholder = { input = "Menu", list = "No entries" }
```

### D-04 regression-gate skeleton (house pattern from `theme-doctor`, confirmed via direct read of `theme-engine/.config/theme-engine/theme-doctor`)

```bash
#!/usr/bin/env bash
set -uo pipefail
PASS=0; FAIL=0
check() { [[ "$2" == "0" ]] && { echo "  [PASS] $1"; PASS=$((PASS+1)); } || { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }; }

# 1. Every declared `bind*` combo in keybinds.conf must appear in hyprctl binds -j
# 2. No two DIFFERENT dispatcher targets share the same (modmask, key, release) tuple
#    unless intentionally chained (e.g. submap multi-dispatch)
# 3. The new tap bind (release=true, key=SUPER_L) and kill-bind (Escape) are present
DECLARED=$(grep -oP '^\s*bind[a-z]*\s*=\s*\K.*' hypr/.config/hypr/config/keybinds.conf)
LIVE=$(hyprctl binds -j)
# ... cross-reference logic (plan owns exact implementation)
echo "keybind-doctor: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|-------------------|---------------|--------|
| hyprlang `.conf` bind syntax (`bind = MODS, key, dispatcher, params`) | Lua config (`hl.bind(keys, dispatcher)`) | Hyprland 0.55 (documented on the LIVE wiki: "Since Hyprland 0.55, hyprlang is deprecated in favor of lua") | This repo intentionally stays on hyprlang (PROJECT.md constraint: "fixes and extends the existing setup, not a rewrite") — confirmed hyprlang is still fully functional on the installed 0.55.4 binary (`hyprctl binds -j` correctly reflects every `.conf`-declared bind). All syntax examples in this document use hyprlang, matching the existing `keybinds.conf`. |
| Omarchy's own SUPER-tap pattern | Omarchy's actual shipped default binds `omarchy-menu` to **`SUPER + SPACE`** (a chord), not a bare tap — confirmed by fetching `basecamp/omarchy`'s live `config/hypr/bindings.lua` | Omarchy has also migrated to Lua config (`bindings.lua`, `hyprland.lua`) | This project's explicit reference (Omarchy) sidesteps the exact hard problem D-02 sets out to solve — Omarchy uses a chord, this repo deliberately chooses the harder bare-tap UX. There is no Omarchy prior-art to copy for the tap mechanism itself; the wiki's own "wofi toggle" example is the closest sanctioned precedent. |

**Deprecated/outdated:** none within this phase's scope — all mechanisms used (hyprlang binds, elephant menus provider) are current and actively shipped in the exact versions installed on this machine.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | `MOZ_APP_REMOTINGNAME` env var changes Zen's Wayland app_id the same way it's documented to for upstream Firefox 124+ | Anti-Patterns / Pitfall 4 | If it doesn't work on this Zen build, class-based windowrules for AI web-apps silently fail to discriminate windows; mitigated by the title-regex fallback already documented as the guaranteed-working alternative |
| A2 | Default (non-transparent) `bindr` shadowing on Hyprland 0.55.4 behaves the same as the historically-documented default (issue #423's "shadowing regression" era, and #6946's fixed-by-mid-2024 resolution) | RQ1 / Pattern 1 | This is the phase's single highest-impact assumption. If wrong, some combo binds could still leak a spurious menu-open on release. Directly mitigated by the mandatory D-04 scripted regression sweep + D-03 safety protocol below — this assumption is NOT to be treated as fully closed until that gate passes live on this machine. |
| A3 | `Setsid: true` process isolation in elephant's `Activate()` (confirmed in source) is sufficient for menu-launched GUI apps to behave equivalently to `uwsm app --`-launched ones for D-09's "systemd scope isolation" requirement | D-09 / Architecture | If elephant's raw `sh -c` + `Setsid` doesn't achieve the same systemd scope as `uwsm app --`, menu-launched GUI apps won't get clean `uwsm stop` behavior. Mitigation: every menu action string for a GUI app should itself invoke `uwsm app -- <app>` (the action IS the uwsm-wrapped command, elephant is just the process that forks `sh -c "uwsm app -- app.desktop"` — this is already how the existing dmenu-fallback pattern would work too) rather than relying on elephant's own process isolation. |

## Open Questions

1. **Does walker's `-s <set>` scoping survive a `ProviderUpdated` broadcast to a DIFFERENT provider (e.g. `menus:utilities`) than the set's declared `providers = ["menus:main"]`?**
   - What we know: `elephant`'s `Activate()` sends `handlers.ProviderUpdated <- "menus:<submenu>"` on drill-down, and walker's `[sets.runner]`-style scoping is confirmed to work for the single-provider case (`walker -s runner` already ships and works in this repo today).
   - What's unclear: whether a `[sets.menu]` locked to `providers = ["menus:main"]` still receives and renders results from `menus:utilities` after a submenu transition, or whether the set's provider allowlist needs to be broadened (e.g. `providers = ["menus:main","menus:utilities","menus:screenshot", …]` listing every menu file by name) for drill-down to actually display.
   - Recommendation: this is the FIRST thing the D-05 spike must empirically prove, before any submenu content is authored — a two-file main→child test menu (deliberately not this phase's real content) validates the wiring cheaply.

2. **Does the `menus:parent` back-navigation action bind to Esc/Backspace automatically, or does it require a walker-side keybind/modifier config this research didn't locate?**
   - What we know: the `menus` provider's `State()` function returns `Actions: []string{ActionGoParent}` when a menu has a `Parent` set — this is elephant's half of the contract.
   - What's unclear: walker's own consumption of provider `State()` actions (which UI gesture triggers them) wasn't found in the parts of the source tree fetched this session (elephant-menus' own repo does not contain walker's GTK4 frontend code — that's a separate `abenz1267/walker` repository not fetched in this session).
   - Recommendation: spike this specifically — open a two-level test menu, confirm empirically whether Esc naturally goes up one level (matching D-06's contract) or whether the plan needs an explicit walker keybind config addition.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| Hyprland | MENU-01 tap bind | ✓ | 0.55.4 | — |
| elephant + elephant-menus | MENU-02..07 (menu provider) | ✓ (elephant running; elephant-menus installed but unconfigured) | 2.21.0 | bash + `walker --dmenu` chain (D-05 fallback) |
| walker | All menu surfaces | ✓ | 2.16.2 | — |
| steam/multilib | MENU-04 | ✗ (package not installed; multilib repo IS enabled on this dev box but not via install.sh) | — | none — must be added to install.sh (Pitfall 2) |
| ollama | MENU-03 local models | ✗ (not installed) | target 0.31.2 | none — D-23 explicitly scopes to install+enable, no model pull |
| Zen browser | MENU-03 AI web-apps | ✓ | 1.21.6b | — |
| gh CLI (research tool only) | This research session | ✓ | — | curl to raw.githubusercontent.com (used as a fallback when `gh api`/WebFetch hit transient DNS issues) |

**Missing dependencies with no fallback:**
- steam+multilib, ollama, aichat, gamemode, mangohud, pavucontrol, nwg-displays, blueman, heroic-games-launcher-bin, protonup-qt — all require `install.sh` PACMAN_PKGS/AUR_PKGS additions (D-33). None have a "skip if missing" fallback since they're the literal deliverables of MENU-03/04.

## Validation Architecture

> `workflow.nyquist_validation` is `false` in `.planning/config.json`. This project has no unit-test framework (bash/dotfiles repo) — its equivalent is the rerunnable-gate + container/VM two-tier verification pattern (`theme-doctor`, `theme-parity`, `verify/container-run.sh`). Per this phase's explicit research mandate (headline-risk safety), the sections below substitute for a conventional test-framework map.

### Phase 7's own required gates (from ROADMAP success criteria + D-04)

| Requirement | Verification mechanism | Automated? |
|---|---|---|
| Every existing $SUPER+key combo still works after the tap-bind change | `keybind-doctor` (new, D-04): diff `keybinds.conf`-declared binds against `hyprctl binds -j` | Yes — rerunnable |
| Kill-bind fires and is never shadowed | Manual isolated test, FIRST, before any other bind change (D-03) | No — human, by design (keyboard safety) |
| Tap-only bind fires on bare tap, NOT on any combo release | Human regression pass across a sample of combo binds (e.g. Super+Return, Super+1, Super+Q) immediately followed by releasing Super alone | No — human, this is exactly what A2 in the Assumptions Log flags as unverifiable by static analysis alone |
| Menu drill-down/back-nav/icons render correctly | D-05 spike: two-file test menu (main→child), opened live, before any real content is authored | Manual visual + `elephant listproviders` automated check that the provider registers |
| Gaming mode toggles are reversible and leave no config-file diff | `git status` clean check after toggle-on/toggle-off cycle (matches existing project convention: "generated theme output lives in state dir, never git — enforced by git-clean invariant in stress test") | Yes — trivial to script |
| Container gate stays green with new packages | `verify/container-run.sh --core-only` (existing two-tier gate) | Yes — existing infrastructure, D-34 |

### Safety protocol for the D-02/D-03 bind experiment (MANDATORY, read before executing)

This research explicitly did NOT perform a live keypress test of the tap-bind (no physical/synthetic key-event capability was exercised against the live session, consistent with the SAFETY MANDATE). The evidence for RQ1 is the strongest available without live keypress testing: the installed binary's own compiled-in bind-flag semantics (`t`=transparent proves default=shadowable), the official wiki's own canonical worked example using this exact syntax, and the historical bug-report record treating shadowing as Hyprland's intended default behavior. **The executor MUST still empirically confirm this before considering D-02 closed**, using the following sequence, adapted directly from the Phase 4 hyprlock lockout-recovery procedure (`.planning/phases/04-reliability-fixes-tech-debt/04-02-SUMMARY.md`):

1. **Log into a second TTY first** (`Ctrl+Alt+F2`, sign in with normal credentials). Keep it open and authenticated for the entire test.
2. **Add ONLY the kill-bind** (`bind = $mainMod, Escape, exec, pkill walker`) and reload (`hyprctl reload`). Test it in isolation: manually open walker any other way, confirm Super+Escape closes it. Do this BEFORE touching the SUPER_L binds at all.
3. **Add the `bindr` tap bind** alongside the EXISTING `bind = $mainMod, SUPER_L, exec, walker` press-bind (do not delete the old one yet) and reload. This is additive-only — cannot break any existing bind, since it only adds a new release-triggered action on a key that already has a press-triggered action.
4. **Test the shadowing claim directly:** press-and-release several existing combos (Super+Return, Super+1, Super+Q) one at a time; after each, confirm the tap-menu does NOT also open when Super is released. Then test a bare tap alone; confirm the menu DOES open.
5. **Only after step 4 passes clean**, remove the old `bind = $mainMod, SUPER_L, exec, walker` line and add `bind = $mainMod, SPACE, exec, $app_launcher` (D-01's relocation).
6. **Run `keybind-doctor` (D-04)** as the final automated cross-check, then do one full human pass over every bind in `keybinds.conf`.
7. If at any point Super becomes unresponsive: switch to the second TTY (`Ctrl+Alt+F2`) using the already-authenticated session and run `pkill walker` and/or revert `keybinds.conf` + `hyprctl reload`.

## Security Domain

> `security_enforcement: true`, `security_asvs_level: 1` in `.planning/config.json`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | Menu has no auth surface; Power delegates to unchanged `wlogout.sh` |
| V3 Session Management | No | No new session concept introduced |
| V4 Access Control | No | Single-user desktop, no privilege boundary crossed by menu actions themselves |
| V5 Input Validation | Yes | Menu actions are fixed strings authored in TOML by the repo owner, not user-supplied at runtime — no injection surface from the menu itself. The one dynamic-input surface is the keybind cheat-sheet's live parse of `keybinds.conf` (D-31) — must not `eval`/execute parsed content, only display it |
| V6 Cryptography | No | Not applicable |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| A malicious/malformed `keybinds.conf` line causes the cheat-sheet parser to execute rather than display content | Tampering / Elevation of Privilege | Parser must treat every parsed field as display-only text (printf/echo, never `eval`/`source`) — same discipline as the existing `theme-doctor` which only ever reads and reports, never executes parsed config content |
| gaming-mode toggle script run with elevated/unexpected privileges via a crafted menu action | Elevation of Privilege | All menu actions and toggle scripts run as the invoking user (elephant's `Activate()` spawns `sh -c` with the daemon's own uid — the daemon itself runs unprivileged under `uwsm app --`, confirmed via the existing `exec-once` autostart entry) — no `sudo`/privilege escalation anywhere in this phase's scope |
| AUR package supply-chain risk (heroic-games-launcher-bin, protonup-qt) | Tampering | D-33's mandatory `checkpoint:human-verify` gate before `install.sh` gains either package — already satisfied by this research's Package Legitimacy Audit table, but the human gate remains required at execution time per project policy |
| Kill-bind (`pkill walker`) as an unauthenticated local DoS vector | n/a (physical-access-only, single-user desktop) | Out of scope — requires local keyboard access, which already implies full session control on a single-user personal desktop; consistent with this project's existing threat model (no remote-access surface introduced) |

## Sources

### Primary (HIGH confidence — verified live against installed binaries on this machine)

- `hyprctl version`, `hyprctl binds -j`, `hyprctl -j getoption <keyword>`, `hyprctl -j clients` — Hyprland 0.55.4 live state
- `elephant version`, `elephant listproviders`, `elephant menu --help`, `elephant generate --help` — elephant 2.21.0 live CLI
- `pacman -Qi elephant-menus`, `/usr/lib/elephant/menus.so`, `/var/lib/pacman/local/elephant-menus-*` — installed package facts
- `~/.cache/paru/clone/elephant-menus/v2.21.0.tar.gz` extracted → `elephant-2.21.0/internal/providers/menus/{README.md,setup.go}`, `pkg/common/menucfg.go`, `pkg/pb/menu.proto`, `internal/providers/load.go`, `cmd/elephant/elephant.go` — the actual source of the exact binary installed on this machine (elephant-menus PKGBUILD confirms it's built from the same upstream `abenz1267/elephant` monorepo tag)
- `/usr/include/hyprland/src/managers/KeybindManager.hpp` — Hyprland's own shipped C++ header, confirms `shadowed`/`releasePending` per-keybind state exists in the compiled binary
- `zen-browser --help`, `/usr/share/applications/*zen*.desktop` (StartupWMClass=zen), live `hyprctl clients -j` showing a real Zen window's class
- `pacman -Si` / `paru -Si` for every package in the Standard Stack and Package Legitimacy tables (run 2026-07-13)
- Live test: created and verified `~/.config/elephant/menus/test.toml` → `elephant listproviders` → `menus:test` appeared; artifact removed
- `theme-engine/.config/theme-engine/theme-doctor`, `theme-engine/.config/theme-engine/lib/reload.sh`, `hypr/.config/hypr/scripts/{wallpaper-switch.sh,emoji-picker.sh}`, `hypr/.config/hypr/config/{keybinds.conf,autostart.conf}`, `walker/.config/walker/config.toml`, `theme-engine/.config/theme-engine/contract.json` — this repo's own current state, read directly
- `install.sh` — grepped for multilib/pacman.conf handling (confirmed absent)

### Secondary (MEDIUM confidence — official docs / official repos, fetched this session)

- wiki.hypr.land 0.54.0 Binds page (fetched via curl, HTML→text extraction) — official archived hyprlang documentation, explicitly still the reference for hyprlang users per the live wiki's own banner ("Looking for the old hyprlang syntax? Check the 0.54 wiki pages")
- `gh issue view 6946 --repo hyprwm/Hyprland` (full thread) — official GitHub issue tracker
- `gh issue view 423 --repo hyprwm/Hyprland` — official GitHub issue tracker, "Keybind shadowing regression" title independently corroborates shadowing-by-default
- `basecamp/omarchy` live `config/hypr/bindings.lua`/`bindings.conf` (fetched via curl/gh api) — the project's own named reference implementation

### Tertiary (LOW confidence — WebSearch only, flagged for validation)

- `MOZ_APP_REMOTINGNAME` env var behavior on Zen specifically (only verified for upstream Firefox 124+ via WebSearch, not tested live against this Zen build) — see Assumption A1
- Community consensus on `bindr = SUPER, SUPER_L` post-#6946 fix stability across Hyprland versions since (no single authoritative changelog entry located confirming permanent fix vs. this specific machine's 0.55.4 behavior — hence the mandatory live D-03/D-04 verification protocol above, not treated as fully closed by search alone)

## Metadata

**Confidence breakdown:**
- RQ1 (tap-only bind mechanism): HIGH — verified via installed binary's own compiled headers + official wiki's canonical example + historical issue-tracker corroboration; residual empirical-verification requirement documented explicitly in Validation Architecture (not a confidence gap, a stated safety requirement)
- RQ2 (elephant menus provider): HIGH — verified via live test against the installed daemon binary (TOML loaded, provider registered) plus direct source read of the exact shipped package version
- Package landscape: HIGH — every version/repo claim verified via `pacman -Si`/`paru -Si` live on this machine
- Zen SSB windowrule mechanism: MEDIUM — the problem (shared WM_CLASS) is HIGH-confidence verified live; the fix (`MOZ_APP_REMOTINGNAME`) is MEDIUM/tertiary, with a HIGH-confidence fallback (title-regex) documented
- Gaming-mode runtime toggles: HIGH — `hyprctl getoption` confirms every keyword path is live and settable on this exact binary
- Waybar hide signal: HIGH — Arch manual page (`man.archlinux.org/man/waybar.5`) confirms `on-sigusr1` default action is `toggle`

**Research date:** 2026-07-13
**Valid until:** ~30 days for the package-version table (Arch rolling release); RQ1/RQ2 architectural findings are stable until the next Hyprland/elephant major version bump (monitor via `hyprctl version`/`elephant version` at plan-execution time, per this project's own "verify against installed binary" standing policy)
