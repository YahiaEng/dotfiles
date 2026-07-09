# Phase 1: Root-Cause Fix & Consolidated Theme Engine - Research

**Researched:** 2026-07-07
**Domain:** Linux desktop theming pipeline consolidation (matugen + GTK3/GTK4 + Walker/elephant + waybar/swaync), Arch Linux + Hyprland + uwsm, GNU Stow-managed dotfiles
**Confidence:** MEDIUM-HIGH (HIGH for everything directly verified on this machine/repo/matugen binary/walker source this session; MEDIUM for community-doc-sourced ecosystem claims)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Engine shape & interface**
- **D-01:** Single entrypoint `theme-apply <name>` (e.g. `theme-apply catppuccin`, `theme-apply materialyou`) handles static and dynamic internally and owns the reload fan-out. The walker dmenu picker and login init become thin callers — picker only picks a name, init only reads the state file.
- **D-02:** The engine lives in its own new stow package (`theme-engine/` or similar), not in `hypr/.config/hypr/scripts/`. Theming becomes a first-class component decoupled from the hypr package.
- **D-03:** **One rendering path:** static presets become palette definitions fed into the same matugen template fan-out used by wallpaper themes — parity by construction. Research MUST verify matugen 4.1 supports preset-palette input cleanly; if not, fall back to dual paths writing an identical, contract-enforced output structure.
- **D-04:** The engine owns ALL reload fan-out (PIPE-02). Strip every `post_hook` from `matugen/.config/matugen/config.toml`; `theme-apply` runs one ordered reload step after rendering completes — reloads never fire on partially-rendered state.

**Generated output location & wiring**
- **D-05:** Generated output lands in `~/.local/state/theme/` (XDG_STATE_HOME — survives cache wipes, outside the repo). The saved-theme state file moves there too (replacing `~/.cache/current-theme`).
- **D-06:** Output contract is **per-app files** (hyprland.conf, waybar.css, kitty.conf, gtk.css, …) with shared variable names across CSS files. Phase 2 will diff this structure for parity.
- **D-07:** Apps consume via **native imports where they exist** (waybar/swaync CSS `@import`, hyprland `source=`, kitty `include` — all pointing at `~/.local/state/theme/`); apps with no include mechanism (yazi theme.toml, walker style.css) get direct writes/symlinks to their config path, gitignored.
- **D-08:** GTK: the stowed `~/.config/gtk-{3,4}.0/gtk.css` becomes a static file that `@import`s the state-dir palette, followed by the base rules. No `cat colors.css gtk-base.css` concatenation anywhere. Research must verify GTK CSS `@import` path semantics (relative vs absolute).
- **D-09:** One-time wiring, no per-login hacks: the walker rice-theme dir dance in theme-init.sh (delete stow symlink, mkdir, rm style.css symlink every login) is replaced by wiring established once by the engine/stow setup. `.stow-local-ignore` excludes what must not be symlinked.
- **D-10:** First boot: `theme-init` (login) calls `theme-apply` with the saved theme, falling back to **Catppuccin Mocha** when no state exists. Repo tracks zero generated color files; install.sh needs no pre-generation step.
- **D-11:** Wofi is never added to the new engine (no template, no target). Physical removal of wofi configs stays in Phase 3.
- **D-12:** Fan-out targets: all ten as today — Hyprland, waybar, kitty, swaync, wlogout, GTK3 (Thunar), GTK4/libadwaita, walker, yazi, vscodium.
- **D-13:** `GTK_THEME`'s single source of truth is the uwsm env file (`~/.config/uwsm/env`) (PIPE-05). Scripts stop exporting it ad hoc; the engine only propagates via `dbus-update-activation-environment` / `systemctl --user import-environment` when needed.
- **D-14:** Theme application is **atomic (render-then-commit):** render everything to a temp dir, move into `~/.local/state/theme/` only on full success, then reload. A failed render leaves the desktop untouched.

**Switch UX & disruption**
- **D-15:** Thunar: restart only the background `thunar --daemon` — never kill visible windows. Open windows may keep the old palette until closed; the next window opens themed. Research checks whether the adw-gtk-theme fix + gsettings gtk-theme toggle re-themes *running* GTK3 windows live (GTK3 follows `gtk-theme-name` changes), which would make even open windows update.
- **D-16:** Walker: prefer `hotreload_theme` (research verifies it works on walker 2.16); fall back to a hardened restart that also checks elephant health (ties into SCAN-02). Prefer the lightest mechanism that is 100% reliable.
- **D-17:** **Dark-only for v1.** Hardcoded `prefer-dark` / `adw-gtk3-dark` is acceptable. Engine design leaves a seam for a per-theme dark/light attribute but builds/tests no light support. Light themes are a v2 THEMES item.
- **D-18:** Feedback: keep success toast (theme name) + loud error notifications. With render-then-commit, error messages should state the desktop was left unchanged.
- **D-19:** Wallpaper setting is owned by the engine/picker: set `set = false` (or remove `[config.wallpaper]`) in matugen config; `awww` is called only by the wallpaper picker and theme-init. Matugen only renders templates.
- **D-20:** An explicit wallpaper pick while Material You is active re-runs `theme-apply materialyou` — wallpaper and palette always match in dynamic mode. In static mode, picking a wallpaper changes only the wallpaper. (Re-theme on wallpaper auto-cycle remains out of scope.)
- **D-21:** Latency: **visible surface flips in <1s** (Hyprland borders, waybar, kitty, swaync, wallpaper — the signal-reload set). Restart-based targets (Thunar daemon, walker restart fallback, vscodium) may finish 1–2s later in the background, guaranteed correct by next interaction. Soft target — no correctness trade-offs to chase it; it must not displace render-then-commit or reliability.

**Audit format & fix policy**
- **D-22:** Audit deliverable is a single `AUDIT.md` in the phase directory: findings grouped by component (theme pipeline, hyprland/keybinds, uwsm, stow, install scripts), each with severity (critical/major/minor), evidence (`file:line`), and disposition (`fix-in-phase-1` / `fix-in-phase-2` / `fix-in-phase-3` / `wontfix`).
- **D-23:** Fix policy: **fix everything found in Phase 1, except findings explicitly owned by Phase 2/3 requirements** (parity stress → P2; install.sh packages, stow guards, dead-config removal → P3). Deferred findings carry their phase assignment in AUDIT.md so nothing waits without an owner. Roadmap phase boundaries stay intact.
- **D-24:** Sequencing: **audit first, then fix.** Complete the full-repo audit and write AUDIT.md before building the engine — findings inform engine design. Exception: the trivially-verified root cause (install `adw-gtk-theme`) lands immediately alongside the audit.
- **D-25:** Regression protection is scripted: a rerunnable check script (e.g. `theme-doctor`) verifies the invariants — adw-gtk-theme installed, gsettings values correct, elephant running and version-matched with walker, state-dir files present, no stow conflicts. Phase 2's stress test and Phase 3's VM verification reuse it.

### Claude's Discretion
- Exact name/layout of the new stow package and script names (`theme-apply`, `theme-doctor` are working names).
- Internal engine structure (single script vs script + sourced lib), argument parsing, logging.
- Per-app reload mechanics beyond the decisions above (signals vs client commands), ordering of the reload step.
- How theme-init and the pickers pass through to the engine (exec vs source).
- Whether vscodium-theme.sh gets absorbed into the engine or stays a called helper.

### Deferred Ideas (OUT OF SCOPE)
- **Light theme support (per-theme dark/light attribute)** — engine leaves a seam (D-17); actual support is a v2 THEMES item.
- None other — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| THEME-01 | Walker follows theme switches (static and dynamic) — no more stuck-white launcher | **Critical correction below:** `hotreload_theme` does not exist in walker 2.16.2 (verified against source). Plan must design the hardened-restart path as primary, not a fallback. See State of the Art + Pitfall W1. |
| THEME-02 | Thunar follows theme switches with full GTK3 palette (adw-gtk-theme installed and applied) | Root cause confirmed live: `adw-gtk-theme` still not installed on this machine. Package is in official `extra` repo (not AUR) — see Standard Stack + Package Legitimacy Audit. |
| THEME-03 | GTK4/libadwaita apps follow dark/light mode + accent color, best-effort `gtk-4.0/gtk.css` overrides | Architecture Pattern 4 (GTK Chrome vs Palette Separation) — ceiling documented, scope accordingly. |
| THEME-04 | Waybar re-themes correctly, static + dynamic | Standard signal reload (`SIGUSR2`) already wired; verify end-to-end once D-04's single-owner reload is built. |
| THEME-05 | Swaync re-themes correctly, static + dynamic | Standard `swaync-client -rs` already wired; same verification note as THEME-04. |
| THEME-06 | One theme switch updates every visible app live, no relogin | GTK_THEME propagation mechanism (`systemctl --user import-environment` + `dbus-update-activation-environment`) verified present and correct pattern; live-session check below shows the value already reaches systemd today. See Pitfall G1. |
| PIPE-01 | One shared theme engine, no duplicated orchestration | **New finding:** duplication is 3-way, not 2-way — `wallpaper-picker.sh` is a third independent reimplementation of apply+reload logic, not just `theme-switch.sh`/`theme-init.sh`. See Architecture Patterns. |
| PIPE-02 | Reload fan-out owned by exactly one place | Verified matugen `-p/--prefix` mechanism (below) makes "strip all post_hooks, single reload script" cleanly implementable alongside D-14's atomicity. |
| PIPE-03 | Matugen output lives outside stowed git tree | Confirmed via `git log` that generated files are still committed under old paths; migration must `git rm --cached` them, not just redirect future output. See Runtime State Inventory. |
| PIPE-05 | GTK_THEME single source of truth | uwsm/env is correct target per existing pattern (D-13); Hyprland `env.conf` duplicate + `gtk-reload.sh` runtime re-export are the two to remove. |
| SCAN-01 | Full-repo bug audit documented | This document surfaces several **new, previously undocumented** findings beyond the project-level research (wallpaper-picker.sh triple duplication, elephant provider package gaps, matugen crash bug) — feed directly into Plan 01-01's audit. |
| SCAN-02 | Walker/elephant functional health verified | **New finding:** `elephant listproviders` currently returns only 4 of the 5 installed provider packages, and walker's config.toml references 3 providers (`runner`, `websearch`, `files`) with **no corresponding elephant-* package anywhere in install.sh**. See Pitfall W2. |
</phase_requirements>

## Summary

This phase consolidates an already-correct five-layer architecture (trigger → generate → distribute → reload → state) rather than inventing new architecture — that finding from the project-level research is reconfirmed. What this phase-level research adds is empirical verification of the specific mechanisms Plan 01-02 and 01-03 depend on, several of which turned out **not to work the way CONTEXT.md's decisions assumed**, and one previously undiscovered class of bug (missing elephant provider packages).

The single most important correction: **Walker's `hotreload_theme` config key, which D-16 explicitly plans to "prefer," does not exist anywhere in walker's source code** — verified directly against the exact installed tag (`v2.16.2`) on GitHub. Walker's theme CSS is loaded exactly once, at startup, via `setup_css()`, with no file-watcher and no config-gated hot-reload path. This means Plan 01-03 should design the hardened kill/relaunch restart (bounded process-exit poll + elephant health check, per PITFALLS.md Pitfall 3/4) as the **primary and only mechanism**, not a fallback behind a feature that isn't there.

The second major finding validates D-03's riskiest assumption instead of refuting it: matugen 4.1.0 has an undocumented-in-the-wiki but fully functional `matugen json <path>` subcommand plus `-p/--prefix <PATH>` flag, both empirically tested against the installed binary this session. `matugen json` accepts a hand-built JSON file structured as `{"colors": {"<role>": {"default": {"color": "#hex"}}}}` and renders it through the **exact same templates** used for Material You mode — with zero algorithmic color derivation — achieving true parity-by-construction for D-03. Two caveats were also found and must be designed around: (1) any template referencing `{{colors.image}}` (only `hyprland-colors.conf`, feeding `hyprlock.conf` — out of scope this milestone) throws a hard `ResolveError` unless the JSON supplies a (blank-is-fine) `colors.image` key; (2) leaving `[config.wallpaper]` with `set = true` in `matugen/config.toml` while running `matugen json` (no image) **crashes matugen with an unhandled panic** — this makes D-19's "disable `[config.wallpaper]`" a hard correctness requirement, not a style preference. The `-p/--prefix` flag transparently redirects every configured `output_path` under a given directory, which is the exact primitive D-14's atomic render-then-commit design needs (render to a temp prefix, verify exit 0, then move into `~/.local/state/theme/`).

A third finding narrows GTK's `@import` semantics for D-08: a GTK core developer confirmed on GNOME Discourse that GTK CSS `@import url(...)` does **not** expand `~`, `$HOME`, or any environment variable — but relative paths from the CSS file's own directory do work and resolve correctly (`../../.local/state/theme/...`), which is portable across users without hardcoding a literal home directory into a stowed, committed file.

A fourth finding extends SCAN-02 beyond what the project-level research found: `elephant listproviders` on this exact machine returns only `clipboard, calc, symbols, desktopapplications` — missing `menus` (whose package **is** installed) and never able to return `runner`, `websearch`, or `files` (whose packages are **not in `install.sh` at all**, despite `walker/.config/walker/config.toml` listing `runner` and `websearch` in its default provider set and `files` as a prefix provider). This is a real, concrete, previously-undocumented functional gap for Plan 01-01's audit to record.

**Primary recommendation:** Build the engine around the two now-verified matugen primitives (`json` subcommand for static presets, `-p/--prefix` for atomic staging), design Walker's reload as restart-only (no hotreload attempt), and add the elephant provider-package gap plus the wallpaper-picker.sh triple-duplication finding to Plan 01-01's audit scope before Plan 01-02 begins.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Theme trigger (pick a theme/wallpaper) | Browser/Client analogue: Walker (GTK4 launcher) dmenu | Hyprland keybind | User-facing selection UI; collects intent only, never touches app configs (Pattern 1) |
| Color generation (static copy or matugen render) | Local generation engine (`theme-apply`, new `theme-engine/` stow package) | matugen binary (external process) | This is the "business logic" tier of a desktop-local system — the engine owns the algorithm choice (static vs Material You) and the atomic commit |
| Distribution (canonical color files) | Local generation engine, writing to `~/.local/state/theme/` (XDG_STATE_HOME) | — | Equivalent to a "backend API" producing a canonical data contract other components read; deliberately placed outside the stow-managed (git) tree |
| Application consumption (Hyprland, waybar, kitty, swaync, wlogout, GTK3/4, walker, yazi, vscodium) | Each app's own config (stowed, in git) | — | Each app is its own "frontend" that imports/sources the canonical files; app configs never embed literal colors (Pattern 1) |
| Reload orchestration (signals, restarts, gsettings toggles) | Local generation engine (single reload step) | Per-app native mechanism (hyprctl, SIGUSR2, swaync-client, gsettings) | Reload must have exactly one owner (D-04/PIPE-02) — currently split between matugen `post_hook`s and 3 separately-duplicated orchestrator scripts |
| State persistence (which theme is active) | `~/.local/state/theme/current-theme` (XDG_STATE_HOME) | — | Read once at login by `theme-init`; not a "database" in the traditional sense but the same architectural role — single source, single writer |
| Package/dependency correctness (adw-gtk-theme, elephant providers) | `install.sh` (official repo + AUR arrays) | `theme-doctor` runtime health check (D-25) | Root-cause tier: a missing/misnamed package here silently breaks every tier above it with no error surfaced anywhere else |

## Standard Stack

### Core (already installed, verified live on this machine)

| Component | Version (verified) | Purpose | Why Standard |
|-----------|---------------------|---------|---------------|
| matugen-bin | 4.1.0 `[VERIFIED: matugen --version, this machine]` | Material You color generation + arbitrary template rendering | De facto standard in the 2025/2026 Hyprland rice ecosystem `[ASSUMED — training/websearch, uncorroborated by a second independent source]`. Already deployed; this phase does not replace it. |
| walker | 2.16.2 `[VERIFIED: walker --version, this machine]` | GTK4 launcher frontend | Chosen per PROJECT.md; confirmed Rust-based (not the older Go implementation some tutorials describe) via direct GitHub source inspection `[VERIFIED: github.com/abenz1267/walker Cargo.toml + src/, tag v2.16.2]` |
| elephant | 2.21.0 `[VERIFIED: elephant version, this machine]` | Walker's backend data-provider daemon over a Unix socket | Confirmed running (`/run/user/$UID/elephant/elephant.sock` live) `[VERIFIED: this machine]` |
| waybar | 0.15.0 | Status bar | Already chosen; `SIGUSR2` reload confirmed wired |
| swaync | 0.12.6 | Notification daemon | Already chosen; `swaync-client -rs` reload confirmed wired |

### The one package this phase installs

| Package | Version | Repo | Purpose |
|---------|---------|------|---------|
| `adw-gtk-theme` | 6.5-1 `[VERIFIED: pacman -Si adw-gtk-theme, this machine]` | **official `extra`** (NOT AUR) | GTK3 port of the libadwaita look; the theme every config in this repo already references by name (`adw-gtk3-dark`) but that is not installed |

**Correction to install.sh placement:** `adw-gtk-theme` belongs in `install.sh`'s `PACMAN_PKGS` array (official repo, no AUR helper needed), not `AUR_PKGS` where the misnamed `adw-gtk3` currently sits `[VERIFIED: pacman -Si adw-gtk-theme reports Repository: extra]`. This is a small but concrete correction: the fix is not just "rename the AUR package," it's "move it out of the AUR array entirely."

### Version compatibility (reconfirmed this session)

| Package A | Compatible With | Notes |
|-----------|------------------|-------|
| walker 2.16.2 | elephant 2.21.0 | Both running via `uwsm app --`, independently versioned by the same upstream author; no version-pin mechanism exists in this repo's `install.sh` today (AUR arrays install "latest" for both) `[VERIFIED: this machine]` |
| gtk3 3.24.52 | adw-gtk-theme 6.5-1 | Provides the `adw-gtk3-dark` theme name already referenced by `settings.ini`/gsettings — no other config change needed once installed `[CITED: pacman -Si output]` |

## Package Legitimacy Audit

> Only one new package is installed by this phase (`adw-gtk-theme`), and it is a pacman-managed official-repo package, not an npm/PyPI/crates package — the ecosystem-specific `gsd-tools query package-legitimacy check` seam does not apply to pacman/AUR packages. The equivalent verification was performed directly against the Arch package database.

| Package | Registry | Age (this release) | Source Repo | Verdict | Disposition |
|---------|----------|---------------------|--------------|---------|-------------|
| `adw-gtk-theme` | pacman `extra` (official) | Built 2026-04-15 `[VERIFIED: pacman -Si]`; upstream project since ~2020 | github.com/lassekongo83/adw-gtk3 `[VERIFIED: pacman -Si URL field]` | OK | Approved — install via `pacman -S adw-gtk-theme`, not AUR |

**Packages removed due to SLOP verdict:** none.
**Packages flagged as suspicious (SUS):** none.
**Note:** `adw-gtk3` (the currently-listed AUR package name) does not exist under that name in the AUR or official repos `[VERIFIED: pacman -Si adw-gtk3 → error, this machine, both this session and in the prior project-level research]`. This is not a suspicious/malicious package — it is a nonexistent one, which is the actual root cause under investigation.

## Architecture Patterns

### System Architecture Diagram (target state after this phase)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ TRIGGER LAYER                                                           │
│  Walker theme picker (dmenu)   Wallpaper picker (fzf)   Login (uwsm)    │
│         │                            │                       │          │
│         └──────────────┬─────────────┴───────────┬───────────┘          │
│                         ▼                         ▼ (materialyou only)  │
│              theme-apply <name>          theme-apply materialyou        │
│              (theme-engine/ package — the ONLY entrypoint, D-01/D-02)   │
└─────────────────────────┬─────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ GENERATION (branches on mode, D-14 atomic)                              │
│  tmp=$(mktemp -d)                                                       │
│  static:  matugen json  themes/palettes/<name>.json  -p "$tmp"          │
│  dynamic: matugen image <wallpaper> --source-color-index 0 -p "$tmp"    │
│  [ both invoke the SAME templates + SAME config.toml — parity by        │
│    construction, D-03. config.toml has ZERO post_hooks (D-04) and       │
│    [config.wallpaper] REMOVED (mandatory — see matugen panic finding) ] │
│  on exit 0 → mv "$tmp"/* ~/.local/state/theme/   (atomic commit)        │
│  on exit ≠0 → notify-send error, desktop untouched (D-14/D-18)          │
└─────────────────────────┬─────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ DISTRIBUTION — ~/.local/state/theme/ (XDG_STATE_HOME, outside git, D-05)│
│  hyprland.conf  waybar.css  kitty.conf  swaync.css  wlogout.css         │
│  gtk-3.0-colors.css  gtk-4.0-colors.css  walker-style.css  yazi.toml    │
│  vscodium.json                                    current-theme (state)│
└─────────────────────────┬─────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ APPLICATION LAYER — each stowed config imports, never embeds colors     │
│  hyprland.conf: source = ~/.local/state/theme/hyprland.conf             │
│  waybar/swaync/wlogout CSS: @import url("../../.local/state/theme/…")   │
│  gtk-{3,4}.0/gtk.css: @import url('../../.local/state/theme/…') (D-08,  │
│    RELATIVE — GTK does not expand ~ or $HOME, verified this session)    │
│  walker/yazi: no import mechanism → engine writes/symlinks directly     │
│    into config path (gitignored, D-07)                                  │
└─────────────────────────┬─────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ RELOAD (single owner: theme-apply's reload step, D-04)                  │
│  hyprctl reload · pkill -SIGUSR2 waybar · pkill -SIGUSR1 kitty ·         │
│  swaync-client -rs · gsettings toggle (dark-mode + theme-name) ·         │
│  thunar --daemon hardened restart (bounded poll, not sleep) ·           │
│  walker hardened restart (kill, poll gone, verify elephant, relaunch —  │
│    NO hotreload path exists, see Walker finding below) ·                │
│  vscodium-theme.sh (jq merge into settings.json)                        │
└─────────────────────────┬─────────────────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ STATE — ~/.local/state/theme/current-theme, read by theme-init at login │
│  (falls back to "catppuccin" if absent — D-10)                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

```
theme-engine/                         # NEW stow package (D-02)
├── .config/theme-engine/
│   ├── theme-apply                   # entrypoint: theme-apply <name|materialyou> (D-01)
│   ├── theme-doctor                  # health-check script (D-25)
│   ├── lib/
│   │   ├── generate.sh               # matugen json|image -p <tmp>, static→JSON palette lookup
│   │   ├── commit.sh                 # atomic mv tmp → ~/.local/state/theme (D-14)
│   │   ├── reload.sh                 # single fan-out (D-04)
│   │   └── gtk.sh                    # gsettings toggle + GTK_THEME propagation
│   └── palettes/                     # NEW: static presets as matugen-json-compatible files
│       ├── catppuccin.json           # {"colors": {"primary": {"default": {"color": "#.."}}, ...}}
│       ├── dracula.json
│       ├── gruvbox.json
│       ├── nord.json
│       ├── rosepine.json
│       └── tokyonight.json
matugen/.config/matugen/
├── config.toml                       # post_hooks stripped (D-04); [config.wallpaper] REMOVED (mandatory)
└── templates/                        # UNCHANGED — same templates serve both modes (D-03)
themes/                                # per-app static leftovers (kitty/, yazi/, vscodium/) either
                                        # folded into matugen templates or kept as a parallel static
                                        # generation path per app — see Open Questions
hypr/.config/hypr/
├── config/keybinds.conf              # theme picker binds call theme-engine/theme-apply
├── config/autostart.conf             # theme-init calls theme-engine/theme-apply <saved>
└── scripts/                          # theme-switch.sh, theme-init.sh, gtk-reload.sh,
                                        # walker-restart.sh, walker-theme-gen.sh RETIRED —
                                        # logic moves into theme-engine/ (thin callers remain
                                        # only if kept for keybind ergonomics, D-01)
gtk/.config/gtk-{3,4}.0/
├── gtk.css                           # static: @import url('../../.local/state/theme/gtk-N.0-colors.css');
│                                      # then base rules — no more `cat` concatenation (D-08)
└── gtk-base.css                      # unchanged, hand-written override rules
```

### Pattern 1: Static presets as matugen JSON input (verified this session)

**What:** `matugen json <path>` renders the exact same templates as `matugen image`, using literal colors from a hand-built JSON file — **zero Material You algorithmic derivation**. This was empirically verified against the installed matugen 4.1.0 binary, not assumed from docs.

**When to use:** Every static preset (D-03's parity-by-construction requirement).

**Verified JSON schema** (note: `.color`, not `.hex` — matugen's template engine derives `.hex`/`.hex_stripped`/`.rgb`/etc. from this one field at render time):
```json
{
  "colors": {
    "image": "",
    "primary": { "default": { "color": "#cba6f7" } },
    "on_primary": { "default": { "color": "#1e1e2e" } },
    "background": { "default": { "color": "#1e1e2e" } }
  }
}
```
```bash
# Source: empirical test against matugen 4.1.0, this session
matugen json ~/.config/theme-engine/palettes/catppuccin.json -c ~/.config/matugen/config.toml -p "$tmpdir"
# → renders every [templates.*] entry using the literal colors above, into $tmpdir/<output_path>
```

**Two verified caveats that change the plan:**
1. Any template referencing `{{colors.image}}` throws `ResolveError: Value does not exist in the context` unless the JSON supplies `"colors": {"image": "..."}` (empty string is fine — confirmed it renders as a blank value with no error). Only `hyprland-colors.conf` references this, feeding `$image` into `hyprlock.conf`'s background path — hyprlock theming is out of scope this milestone, so a blank placeholder is sufficient for Phase 1.
2. **`[config.wallpaper]` with `set = true` in `matugen/config.toml` crashes matugen** (`internal error: entered unreachable code`, `src/helpers.rs:262`) when running `matugen json` without an image. This is a real panic in the installed binary, verified by direct reproduction. **D-19's "remove/disable `[config.wallpaper]`" is therefore mandatory for the static path to work at all**, not just a design preference for who owns wallpaper-setting.

**Role-name gap found:** the 6 existing `themes/.config/themes/css/<name>.css` files (the natural source for building the new palette JSONs) are missing exactly one role that `kitty-colors.conf`'s template requires: `tertiary_container` (used for kitty's ANSI color5/color13 slots). All 19 other roles referenced across all 9 templates (`hyprland`, `waybar`/`wofi`/`swaync`/`wlogout` share one CSS template family, `kitty`, `gtk3`/`gtk4` share one template, `walker`, `yazi`, `vscodium`) are already present in the existing static CSS files `[VERIFIED: diff of grep'd role sets, this session]`. Plan 01-02 needs one small decision (Claude's Discretion or a quick user check): derive `tertiary_container` per preset (e.g., a muted/darker variant of `tertiary`, matching how matugen derives *_container tones from their parent role) when building the 6 new palette JSON files.

### Pattern 2: Atomic render via `matugen -p/--prefix` (verified this session)

**What:** matugen's `-p, --prefix <PATH>` flag transparently prepends a directory to every configured `output_path`, auto-creating subdirectories as needed — without touching `config.toml` at all.

**Verified:**
```bash
# Source: empirical test against matugen 4.1.0, this session.
# config.toml has output_path = "/some/deep/output/colors.txt" (any absolute path)
matugen json palette.json -c config.toml -p "$(mktemp -d)"
# → writes to $tmpdir/some/deep/output/colors.txt, NOT the real path.
# exit code reflects render success/failure cleanly.
```
This is the exact primitive D-14 needs: render into a fresh `mktemp -d`, check `matugen`'s exit code, then `mv "$tmp"/* ~/.local/state/theme/` only on success. No per-invocation config rewriting required. Combined with D-04 (all `post_hook`s stripped from `config.toml`), nothing fires against half-rendered output — reload only happens after the engine's own atomic commit succeeds.

### Pattern 3: GTK CSS `@import` — relative paths only (verified this session)

**What:** GTK3/GTK4 CSS `@import url(...)` does not support `~`, `$HOME`, or any environment-variable expansion — a GTK core developer confirmed this directly ("No, it's not possible") on GNOME Discourse. Relative paths *do* work, resolved relative to the importing CSS file's own directory.

**When to use:** D-08's stowed `gtk-{3,4}.0/gtk.css` needs to reference `~/.local/state/theme/` without hardcoding a literal home directory (which would break portability across machines/users of this same repo).

```css
/* Source: GTK CSS @import semantics, GNOME Discourse (GTK dev reply), corroborated
   by GTK3 CSS Overview docs.gtk.org — relative-path form verified working in that
   thread's reported use case. [CITED: discourse.gnome.org/t/home-directory-variable-in-gtk-css/7780] */
@import url('../../.local/state/theme/gtk-3.0-colors.css');
/* base rules below, unchanged */
```
**Caveat:** this only resolves correctly if `XDG_STATE_HOME` is the default `~/.local/state` (true for this machine and any unmodified Arch install) — if a user overrides `XDG_STATE_HOME`, the relative path breaks silently. Acceptable, documented limitation for a personal dotfiles repo; not worth solving generically.

### Anti-Patterns to Avoid (reconfirmed + one new instance)

- **Reimplementing the apply+reload sequence per entrypoint (Anti-Pattern 1, ARCHITECTURE.md):** confirmed still true, and **the duplication is 3-way, not 2-way.** `hypr/.config/hypr/scripts/wallpaper-picker.sh` independently calls `matugen image`, rebuilds `gtk.css` via `cat`, and re-fires the full reload sequence (`hyprctl reload`, `pkill -SIGUSR2 waybar`, `gtk-reload.sh`, `walker-restart.sh`, `vscodium-theme.sh`) on wallpaper confirm when Material You is active `[VERIFIED: hypr/.config/hypr/scripts/wallpaper-picker.sh:122-157, this session]`. D-01's "walker picker and login init become thin callers" must explicitly include `wallpaper-picker.sh` as a third thin caller (D-20 already implies this by requiring it to re-run `theme-apply materialyou`, but D-01's own wording only names two callers — flag this for the planner).
- **Assuming a documented-sounding config key exists without checking source:** `hotreload_theme` was carried into this phase's own locked decisions (D-16) from the project-level research, which cited walkerlauncher.com and a community doc. Neither this session's fetch of the official `walkerlauncher.com/docs/configuration` page, nor a direct search of walker's Rust source at the exact installed tag (`v2.16.2`), found any such field. See State of the Art below for the full trail.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Atomic render-then-commit for template output | A custom matugen-config-rewriter that swaps `output_path`s per invocation | `matugen ... -p "$(mktemp -d)"` | Verified this session: the `-p/--prefix` flag already does exactly this, natively, with zero config duplication |
| Static-preset color derivation matching Material You's role set | A bespoke "generate a fake Material scheme from 6 curated colors" algorithm | `matugen json <palette>.json` with hand-authored `.color` values per role | Verified this session: this is a first-class matugen mode ("use matugen as a templating engine," skips generation entirely) — not a workaround |
| Process-exit waiting for Thunar/Walker restart | Fixed `sleep 0.5` | Bounded poll loop (`until ! pgrep -x thunar; do sleep 0.1; done`, capped) | Already flagged in PITFALLS.md Pitfall 3 — reconfirmed, no new tooling needed, just discipline |
| Walker "did the theme apply" health check | Ad-hoc `sleep` after relaunch | `elephant listproviders` / socket-existence poll before declaring the restart complete | `elephant` exposes a real CLI (`elephant version`, `elephant listproviders`) suitable for `theme-doctor` (D-25) — verified this session |

**Key insight:** Every "custom solution" temptation in this phase turned out to already have a first-class, verified primitive in the existing toolchain (matugen's `json`/`-p` modes, elephant's CLI). The risk in this domain is not under-tooling, it's *not knowing the tool already does it* — exactly the failure pattern SUMMARY.md's "8+ failed fix commits" already diagnosed at the meta level.

## Runtime State Inventory

> Included because this phase is a structural rename/refactor: output paths move from stow-managed `~/.config/<app>/colors.*` into `~/.local/state/theme/`, the state file moves from `~/.cache/current-theme`, and orchestration logic moves out of `hypr/.config/hypr/scripts/` into a new `theme-engine/` package.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | `~/.cache/current-theme` (bare theme name, e.g. `catppuccin`) is the only "stored" runtime datum in this pipeline. No database, no keyed records. | No migration needed — D-10 already decided the new engine falls back to `catppuccin` when `~/.local/state/theme/current-theme` doesn't exist. The old `~/.cache/current-theme` becomes orphaned (harmless leftover; candidate for `.gitignore`/cleanup note, not a Phase 1 blocker). |
| **Live service config** | `walker` and `elephant` are long-running daemons (`uwsm app --`, confirmed live via `pgrep`) that read `config.toml` **once at process start**. Neither watches its config file for changes. | Any change to `walker/.config/walker/config.toml` (e.g. adding missing provider entries per SCAN-02, or changing `theme = "rice"`) requires killing/relaunching `walker --gapplication-service` (and possibly `elephant`) to take effect — this is exactly what the hardened-restart mechanism in Plan 01-03 must already do, so no *additional* action beyond what's planned, but the planner should know config edits don't self-apply. |
| **OS-registered state** | No systemd user units, timers, or OS-level task registrations reference the theme scripts by path — verified via `find /run/user/$UID/systemd/units` (only `walker`/`elephant` app-scopes exist, both generic `uwsm app --` scopes, not theme-specific). Hyprland's own `autostart.conf`/`keybinds.conf` reference script paths **textually**, and those are ordinary stowed config files this phase edits directly (not "OS-registered" state outside the repo). | None — verified: nothing outside this repo's own git-tracked files needs re-registration when scripts move into `theme-engine/`. Just update the path strings in `keybinds.conf`/`autostart.conf` as part of the same commit that creates the new package. |
| **Secrets/env vars** | `GTK_THEME=adw-gtk3-dark` is hardcoded in 3 places (`uwsm/.config/uwsm/env`, `hypr/.config/hypr/config/env.conf`, and re-exported at runtime inside `gtk-reload.sh`) — not a secret, but a plaintext env var subject to the same "single source of truth" discipline (D-13/PIPE-05). No SOPS keys, no encrypted secrets exist anywhere in this pipeline. | Consolidate to `uwsm/.config/uwsm/env` only (D-13); remove the `env.conf` duplicate and the ad-hoc runtime `export` in `gtk-reload.sh`'s successor. Verified live this session: `systemctl --user show-environment` already reports `GTK_THEME=adw-gtk3-dark` correctly on the current session — the propagation mechanism works, it's the triplication that needs fixing, not the mechanism. |
| **Build artifacts / installed packages** | (1) `adw-gtk3` (wrong AUR name) → `adw-gtk-theme` (correct, official repo) — genuine missing package, confirmed absent via `pacman -Q` both in prior research and freshly this session. (2) Generated theme output files are **currently git-tracked** at their old in-repo locations (`gtk/.config/gtk-3.0/colors.css`, `walker/.config/walker/themes/rice/style.css`, etc.) — confirmed via `git log` showing 8 historical commits touching these exact "auto-generated, do not edit" files. | (1) `pacman -S adw-gtk-theme` (official repo, no AUR helper). (2) Once output moves to `~/.local/state/theme/` (D-05), the **old in-tree generated files become orphaned but still git-tracked** — they must be explicitly `git rm --cached` (or fully `git rm` if the new stowed file is a static `@import`-only stub, per D-08) as part of Plan 01-02's implementation, not left for Phase 3's `CLEAN-02`. Phase 3's `CLEAN-02` is about *future* switches staying clean; the *existing* tracked generated content from before this phase is Phase 1's own cleanup responsibility, since Phase 1 is what changes the contract. |

## Common Pitfalls

> PITFALLS.md (project-level research) already documents 8 pitfalls with HIGH confidence, all reconfirmed live this session (adw-gtk-theme still absent, generated files still git-tracked, `stow.sh`'s unconditional `mv` still unguarded, GTK_THEME still triplicated). This section adds **new pitfalls discovered during phase-level verification** — read PITFALLS.md first, this extends it.

### Pitfall W1: `hotreload_theme` does not exist in walker 2.16.2 — CONTEXT.md's D-16 premise is false

**What goes wrong:** D-16 says "prefer `hotreload_theme` (research verifies it works on walker 2.16)." No such config key exists. If Plan 01-03 is written expecting to set `hotreload_theme = true` and skip the restart path, it will either silently no-op (unknown TOML keys are typically ignored) or the plan will need an unplanned rewrite mid-execution.

**Why it happens:** The claim originated from project-level web research (STACK.md/PITFALLS.md cite `walkerlauncher.com/docs` and general websearch, both LOW confidence per their own source hierarchy) that was never checked against the actual installed binary's source or the exact tag in use.

**Verification performed this session:**
1. Fetched `https://walkerlauncher.com/docs/configuration` directly — no `hotreload_theme` or any theme-hot-reload key listed at all.
2. A separate community doc (`parnoldx/omarchy-config-agent`) does describe a `hotreload_theme` key with default `true` — but this could not be corroborated against the actual source.
3. Fetched `abenz1267/walker`'s `src/config.rs` at the **exact installed tag `v2.16.2`** via GitHub — the `Walker` config struct is fully enumerated (30 fields) and contains no `hotreload_theme` field, nor any `hot_reload`/`watch`/`live_reload` field under any name.
4. Fetched `src/theme/mod.rs` — CSS is loaded once via `setup_css()`, called from `main.rs` at startup only; no `notify` crate (file-watcher, present as a Cargo dependency for other purposes) usage anywhere in `theme/mod.rs`, `main.rs`, or `config.rs`.

**How to avoid:** Design Plan 01-03's Walker reload step as **restart-only**: hardened kill/relaunch (bounded poll for process exit, verify `elephant` socket/health before declaring success, per PITFALLS.md Pitfall 3/4's existing recommendations). Do not spend implementation time attempting to enable a `hotreload_theme` key — it will not do anything.

**Confidence:** HIGH `[VERIFIED: github.com/abenz1267/walker, ref=v2.16.2, src/config.rs + src/theme/mod.rs + src/main.rs, this session]`

---

### Pitfall W2: Walker's configured providers include three with no installable elephant package in this repo

**What goes wrong:** `walker/.config/walker/config.toml`'s `[providers] default = ["desktopapplications", "calc", "runner", "websearch", "menus"]` and its prefix table (`/` → `files`, `;` → `providerlist`) reference 7 distinct providers. Live verification (`elephant listproviders`) on this machine returns only 4: `clipboard, calc, symbols, desktopapplications`. Cross-checked against installed packages (`pacman -Qs elephant`): only `elephant, elephant-calc, elephant-clipboard, elephant-desktopapplications, elephant-menus, elephant-symbols` are installed — 5 provider packages, but `elephant listproviders` doesn't even list the installed `menus` provider as active. `elephant-providerlist` (listed in `install.sh`'s `AUR_PKGS`) is **not installed** — same silent-AUR-failure class as Pitfall 1 (adw-gtk3). And `elephant-runner`, `elephant-websearch`, `elephant-files` — confirmed to be real, separately-installable AUR packages `[CITED: websearch corroborated by aur.archlinux.org/packages/elephant-websearch listing]` — **are not in `install.sh` at all**, in either array.

**Why it happens:** `install.sh`'s `AUR_PKGS` elephant block was assembled by hand and never cross-checked against `walker/.config/walker/config.toml`'s actual provider references — the same "config says X, install script doesn't guarantee X" class of bug as the adw-gtk3 root cause, just in a different subsystem.

**Consequences:** Walker's default search (no prefix) is silently missing "run a shell command" (`runner`) and "web search" (`websearch`) results — a user typing a command-runner query gets no results and no error, indistinguishable from "walker is broken" (matches the UX Pitfall pattern already documented in PITFALLS.md: silent failure modes that look like theming bugs). The `/` files prefix and `;` provider-switcher prefix are similarly non-functional.

**How to avoid:** This is a SCAN-02 finding, not necessarily a Phase 1 *fix* obligation by itself (D-23's fix policy: fix everything found in Phase 1 unless explicitly owned by Phase 2/3) — but since it's a straightforward `install.sh` package-array addition (same file, same fix shape as the adw-gtk-theme root cause), Plan 01-01 should record it in `AUDIT.md` with a `fix-in-phase-1` disposition alongside the trivially-verified root cause (D-24's stated exception), or explicitly disposition it `fix-in-phase-3` (since `install.sh` package-array hardening is INST-01, a Phase 3 requirement) with a clear rationale either way — don't leave it undecided.

**Confidence:** HIGH `[VERIFIED: live pacman -Qs elephant + elephant listproviders + walker config.toml inspection, this session]` for the machine-state facts; MEDIUM `[CITED: AUR package listing via websearch]` for `elephant-runner`/`elephant-websearch`/`elephant-files` package existence — verify with `paru -Si elephant-runner elephant-websearch elephant-files` before finalizing the audit entry.

---

### Pitfall G1: `[config.wallpaper]` + `matugen json` = unhandled panic

**What goes wrong:** Running `matugen json <path>` (no image argument) while `matugen/config.toml` still has `[config.wallpaper]` with `set = true` (the current, unmodified state of this repo's config) crashes the matugen process entirely: `The application panicked (crashed). Message: internal error: entered unreachable code. Location: src/helpers.rs:262`. This is not a graceful error — no templates render, no partial output, the process aborts.

**Why it happens:** matugen's wallpaper-setting code path assumes an image is always available when `[config.wallpaper].set = true` is configured; the `json` subcommand has no image, and matugen 4.1.0 doesn't guard this combination.

**How to avoid:** D-19 already decided to remove/disable `[config.wallpaper]` from `matugen/config.toml` — this finding upgrades that decision from "the engine should own wallpaper-setting for cleanliness" to **"the static/JSON rendering path will crash matugen outright if this isn't done."** Plan 01-02 must remove `[config.wallpaper]` (or set `set = false`) as a hard prerequisite before the `matugen json` static-preset path can be exercised at all, not as an independent nice-to-have.

**Warning signs:** `matugen json ...` exits non-zero with a Rust panic backtrace instead of a normal matugen error message (matugen's normal error path — like the `ResolveError` for missing `colors.image` — prints a clean, colored diagnostic; a panic looks completely different and will look like a much scarier bug than it is if not anticipated).

**Confidence:** HIGH `[VERIFIED: direct reproduction against matugen 4.1.0, this session]`

---

### Pitfall G2: One missing color role (`tertiary_container`) breaks kitty rendering for all 6 static presets

**What goes wrong:** If the 6 new `theme-engine/palettes/<name>.json` files are built by mechanically converting `themes/.config/themes/css/<name>.css`'s existing `@define-color` lines, they will be missing `tertiary_container` — the only role referenced by any of the 9 template families that isn't already present in those CSS files. `kitty-colors.conf`'s `color5`/`color13` lines reference `{{colors.tertiary_container.default.hex}}`. Since matugen's `ResolveError` behavior aborts the entire template render on a missing key (verified this session via the `colors.image` case), the kitty template — and only the kitty template — will fail to render for every static preset unless this gap is closed.

**Why it happens:** The existing static CSS files were hand-authored before the kitty matugen template was added (or before `tertiary_container` was added to it), and no automated check compares role-set completeness across static presets vs. matugen templates.

**How to avoid:** When building the 6 palette JSON files, add a `tertiary_container` entry per preset. A reasonable default (consistent with how matugen derives *_container tones from their parent color in the dynamic path) is a muted/darker variant of that preset's `tertiary` value — this is a small design decision Plan 01-02 should make explicitly (or flag as a `checkpoint:human-verify` if visual accuracy matters), not silently skip.

**Confidence:** HIGH `[VERIFIED: diff of role sets grepped from all 9 template files vs. themes/css/catppuccin.css, this session]`

## Code Examples

### Convert an existing static CSS preset into a matugen-json palette (illustrative, not yet built)

```bash
# Source: derived from verified matugen json schema, this session.
# Existing: themes/.config/themes/css/catppuccin.css has lines like:
#   @define-color primary #cba6f7;
# Target:  theme-engine/.config/theme-engine/palettes/catppuccin.json

awk -F'[ ;]' '/@define-color/{printf "  \"%s\": {\"default\": {\"color\": \"%s\"}},\n", $2, $3}' \
    themes/.config/themes/css/catppuccin.css
# → hand-wrap the output in { "colors": { "image": "", ...roles..., "tertiary_container": {...} } }
```

### Atomic apply skeleton (verified primitives composed, illustrative)

```bash
# Source: composition of two empirically-verified matugen behaviors, this session.
set -euo pipefail
STATE_DIR="$HOME/.local/state/theme"
tmp="$(mktemp -d)"

if [[ "$1" == "materialyou" ]]; then
    matugen image "$WALLPAPER" --source-color-index 0 -c "$MATUGEN_CFG" -p "$tmp"
else
    matugen json "$PALETTES_DIR/$1.json" -c "$MATUGEN_CFG" -p "$tmp"
fi
# matugen exits non-zero on real render errors (ResolveError, panic) — set -e catches it.

# Atomic commit: only reached if matugen succeeded.
mkdir -p "$STATE_DIR"
rsync -a --delete "$tmp"/ "$STATE_DIR"/   # or: rm -rf "$STATE_DIR" && mv "$tmp" "$STATE_DIR"
echo "$1" > "$STATE_DIR/current-theme"
rm -rf "$tmp"

# Single reload owner (D-04) — runs only after successful commit.
lib/reload.sh
```

### GTK3/4 stowed gtk.css using a relative @import (verified path semantics)

```css
/* Source: GTK CSS @import path semantics verified this session (GNOME Discourse,
   GTK dev reply). File: gtk/.config/gtk-3.0/gtk.css, resolved live path after
   stow: ~/.config/gtk-3.0/gtk.css → relative to ~/.local/state/theme/ is ../../.local/state/theme/ */
@import url('../../.local/state/theme/gtk-3.0-colors.css');

/* hand-written overrides below, unchanged from today's gtk-base.css content */
```

## State of the Art

| Old Approach / Assumption | Verified Current Reality | When Found | Impact |
|---|---|---|---|
| Walker's `hotreload_theme = true` skips the restart need (D-16's stated premise, sourced from project-level websearch) | **No such config key exists** in walker 2.16.2's source (`src/config.rs`, exact installed tag) | This session, via direct GitHub source inspection | Plan 01-03 must design Walker's reload as restart-only from the start, not a fallback path |
| Static presets need a separate rendering pipeline from Material You (dual-path fallback anticipated by D-03 if matugen "doesn't support preset-palette input cleanly") | matugen 4.1.0's `json` subcommand + `-p/--prefix` flag **fully support** literal-palette rendering through the same templates, verified by direct reproduction | This session | D-03's primary (single-pipeline) design is achievable as originally hoped — no fallback needed, just two caveats to design around (blank `colors.image`, remove `[config.wallpaper]`) |
| `[config.wallpaper]` disable is a cleanliness/ownership preference (D-19) | It is a **hard correctness requirement** — leaving it enabled crashes matugen's `json` subcommand outright | This session, direct reproduction of the panic | Elevates D-19 from "nice to have" to "blocking prerequisite" for D-03's static path |
| Theme-orchestration duplication is 2-way (`theme-switch.sh` vs `theme-init.sh`) per project-level ARCHITECTURE.md | It is **3-way** — `wallpaper-picker.sh` independently reimplements the same apply+reload sequence | This session, direct code read | D-01's "thin callers" scope must explicitly include the wallpaper picker |
| GTK_THEME propagation without relogin is unverified ("debug.txt contradicts PROJECT.md's promise") | `systemctl --user show-environment` **already reports the correct value live**, on the current session, without a fresh relogin having just occurred | This session, live check | Increases confidence that D-13's consolidation + existing `systemctl --user import-environment`/`dbus-update-activation-environment` pattern is sufficient; still worth a full end-to-end recheck once GTK_THEME is consolidated to one source, since this observation doesn't isolate *which* of the three current sources produced the live value |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | `tertiary_container` should be derived as a "muted/darker variant" of each preset's `tertiary` color | Pitfall G2 | Low — cosmetic only; wrong value just makes kitty's color5/color13 look slightly off, doesn't break the pipeline. Easy to eyeball-correct during Plan 01-02's implementation. |
| A2 | `elephant-runner`, `elephant-websearch`, `elephant-files` exist as installable AUR packages under those exact names | Pitfall W2 | Medium — if the exact package names are wrong, `install.sh`'s fix for SCAN-02 would need the correct names. Verify with `paru -Si elephant-runner elephant-websearch elephant-files` before writing the audit entry or install.sh edit. |
| A3 | Relative `@import` path `../../.local/state/theme/...` correctly resolves from `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` after stow symlinking | Architecture Pattern 3, Code Examples | Low-Medium — GTK resolves `@import` relative to the *file's own path*, and stow symlinks preserve the file's apparent location under `~/.config/gtk-N.0/`, so the relative path math should hold; not independently re-verified with a real running GTK3/4 app in this research session (only sourced from a GNOME Discourse maintainer statement, not reproduced locally). Recommend a quick live check during Plan 01-02/01-03 execution. |
| A4 | matugen's own documented-but-unfetched wiki pages don't contradict the `json`/`-p` behavior verified via direct binary reproduction | Architecture Pattern 1 & 2 | Low — behavior was reproduced directly against the exact installed 4.1.0 binary, which is authoritative for this machine regardless of what the docs say. |

**If this table is empty:** N/A — see rows above.

## Open Questions

1. **Do the `themes/kitty/*.conf`, `themes/yazi/*.toml`, `themes/vscodium/*.json` static files fold into the matugen template fan-out too, or stay as a separate parallel static path?**
   - What we know: D-03 says static presets become "palette definitions fed into the same matugen template fan-out." The matugen templates already cover kitty, yazi, and vscodium (all three have `[templates.*]` entries and Tera template files).
   - What's unclear: whether Plan 01-02 retires `themes/.config/themes/{kitty,yazi,vscodium}/` entirely (fully served by `matugen json` + the existing templates) or keeps them as a legacy fallback for any per-app quirk not expressible in the Material-role JSON schema (e.g., vscodium's `"workbench.colorTheme": "Default Dark Modern"` literal string, which isn't a color role at all and would need to live in the JSON's custom/non-`colors.*` namespace via `--import-json-string` or a second template variable).
   - Recommendation: Plan 01-02 should decide this explicitly — likely "fold in," since the templates already produce equivalent output, but the vscodium `colorTheme` string needs a home (either a literal in the template itself, unchanged, since it's not palette-derived, or a small custom JSON key alongside `colors`).

2. **Does GTK3's `gtk-theme-name` live-reload (via gsettings toggle) also refresh the separately-loaded user `gtk.css` provider on already-running windows, or only the named theme's own chrome?** (D-15's explicit research ask)
   - What we know: community sources confirm GTK3 apps *can* pick up a `gtk-theme-name` change live if `gnome-settings-daemon`'s xsettings component or the portal is running and the app is listening — this repo's `gtk-reload.sh` already does the gsettings toggle-empty-then-back trick. What's not confirmed from documentation alone is whether that same "theme changed" notification also causes GTK3 to re-parse the **separate** `~/.config/gtk-3.0/gtk.css` user-override provider on windows that are already open, or only the named theme's own bundled CSS.
   - What's unclear: this is an *implementation-detail* question about GTK3's internal StyleContext provider-invalidation behavior that isn't authoritatively documented anywhere found this session, and testing it destructively (killing/relaunching Thunar, or leaving a window open across a real theme switch) is an execution-time action, not appropriate for a research agent to perform on the live desktop session mid-research.
   - Recommendation: treat as a 5-minute empirical check for Plan 01-03's execution step (open Thunar, trigger `theme-apply` on a *different* theme without restarting Thunar, observe whether the open window re-colors). If yes, D-15's "open windows may keep the old palette" caveat can be relaxed. If no, D-15's current design (open windows stay stale until closed) stands as-is and needs no further work.

3. **Exact behavior of `matugen json` when a JSON supplies only *some* roles a given template needs (partial coverage) vs. the all-or-nothing `ResolveError` observed for a single fully-missing key.**
   - What we know: a completely absent key causes a hard `ResolveError` that aborts that template's render (verified this session with `colors.image`).
   - What's unclear: whether providing e.g. `default` but omitting `dark`/`light` sub-keys (which none of this repo's templates reference — they all use `.default.hex` only) would matter; this doesn't block Phase 1 since no template needs `dark`/`light` variants, but is worth knowing if a future phase (light theme support, explicitly deferred) revisits this.
   - Recommendation: no action needed for Phase 1; note for whichever future phase implements light-theme support.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| matugen-bin | All template rendering (both modes) | ✓ `[VERIFIED]` | 4.1.0 | — |
| walker | THEME-01 | ✓ `[VERIFIED]` running | 2.16.2 | — |
| elephant | THEME-01, SCAN-02 | ✓ `[VERIFIED]` running | 2.21.0 | — |
| elephant-runner, elephant-websearch, elephant-files | Walker's configured `runner`/`websearch`/`files` providers | ✗ `[VERIFIED]` not installed, not in install.sh | — | Provider silently returns no results for those queries; no functional fallback exists until installed (see Pitfall W2) |
| elephant-providerlist | Walker's `;` prefix (provider switcher) | ✗ `[VERIFIED]` listed in install.sh but not actually installed | — | Same silent-failure pattern as adw-gtk3; `;` prefix queries return nothing |
| adw-gtk-theme | THEME-02 (root cause) | ✗ `[VERIFIED]` not installed | — (target: 6.5-1, official `extra`) | None — this is the fix itself; blocks THEME-02 until installed |
| gsettings / dconf / xdg-desktop-portal-gtk | THEME-02, THEME-03, THEME-06 | ✓ `[VERIFIED]` service active, values already correct | dconf 0.49.0 (per prior project research) | — |

**Missing dependencies with no fallback:**
- `adw-gtk-theme` — this phase's own deliverable installs it; no workaround exists until then.
- `elephant-runner` / `elephant-websearch` / `elephant-files` / `elephant-providerlist` — SCAN-02 finding; disposition (fix-in-phase-1 vs fix-in-phase-3) needs an explicit planner decision per Pitfall W2.

**Missing dependencies with fallback:**
- None beyond the above — this is a personal-machine dotfiles repo with few external service dependencies; most "environment" here is package presence, already covered above.

## Security Domain

> Included per `security_enforcement: true` (`security_asvs_level: 1`) in `.planning/config.json`. This is a single-user, local-machine desktop configuration pipeline with no network-facing surface, no authentication, and no multi-tenant data — most ASVS web-application categories do not apply. The relevant categories are scoped to shell-script and local-privilege hygiene.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|-------------------|
| V2 Authentication | No | No auth surface — local single-user desktop session |
| V3 Session Management | No | No session concept beyond the Hyprland/uwsm compositor session itself |
| V4 Access Control | No | Single local user; no privilege boundary crossed by the theming pipeline |
| V5 Input Validation | Partial | Theme name selected from a fixed, hardcoded `walker --dmenu` list (`theme-switch.sh`) — not free-form user input, so injection surface is minimal. The new `theme-apply <name>` entrypoint should still validate `$1` against the known palette-file list before using it to construct a file path (`$PALETTES_DIR/$1.json`), to avoid a typo'd or malicious argument doing directory traversal if the entrypoint is ever invoked outside the fixed picker (e.g. from a keybind or future scripted context). |
| V6 Cryptography | No | No secrets, no crypto operations in this pipeline |
| V12 File & Resources | Yes | Generated output moving to `~/.local/state/theme/` (D-05) — ensure the engine creates this directory with standard user-only permissions (no `chmod 777`/world-writable anywhere), consistent with XDG_STATE_HOME conventions. Not currently a finding of concern, just a design-time reminder for Plan 01-02. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Notification content injection (`notify-send` embedding raw command output, e.g. `cat /tmp/matugen-error.log`) | Tampering (of displayed info, low severity) | Already flagged in PITFALLS.md's Security Mistakes table — truncate/sanitize error text before passing to `notify-send`; keep full detail in a log file only. Reconfirmed applicable to this phase's `theme-apply` error-notification path (D-18). |
| Unvalidated theme-name argument used to build a file path (`$PALETTES_DIR/$1.json`) | Tampering / path traversal (low severity — single-user local machine, not a real attacker boundary, but still good hygiene) | Validate `$1` against a known-good list (`compgen`/`case` match against the palette directory's actual filenames) before use, rather than trusting it blindly — cheap to add while building the new entrypoint. |
| Blind `--noconfirm` AUR installs in `install.sh` (pre-existing, out of this phase's direct scope but touches the same file this phase edits for the adw-gtk-theme fix) | Tampering (supply-chain, AUR packages are user-submitted) | Already flagged in PITFALLS.md's Security Mistakes table as a Phase 3 (`INST-01`) concern; not this phase's fix, but worth a one-line note in `AUDIT.md` since this phase touches `install.sh` anyway. |

## Sources

### Primary (HIGH confidence — direct verification this session)
- `matugen --help`, `matugen json --help`, `matugen color --help` — CLI schema, this machine's installed 4.1.0 binary
- Direct empirical reproduction: `matugen json <hand-built-colors.json> -c <config.toml>` rendering literal colors through a real template (3 separate test cases: basic role substitution, `colors.image` ResolveError, `[config.wallpaper]` panic)
- Direct empirical reproduction: `matugen ... -p <tmpdir>` prefix-redirection behavior
- `github.com/abenz1267/walker` — `src/config.rs`, `src/theme/mod.rs`, `src/main.rs`, `Cargo.toml`, fetched at exact installed tag `v2.16.2` via `gh api`
- Live machine state, this session: `pacman -Q/-Si adw-gtk-theme adw-gtk3`, `pacman -Qs elephant`, `elephant version`, `elephant listproviders`, `systemctl --user show-environment`, `gsettings get org.gnome.desktop.interface {gtk-theme,color-scheme}`, `find /run/user/$UID` (socket topology), `pgrep -fa Hyprland thunar walker elephant`
- Direct repo inspection, this session: `theme-switch.sh`, `theme-init.sh`, `gtk-reload.sh`, `walker-restart.sh`, `walker-theme-gen.sh`, `wallpaper-picker.sh` (full read, revealing the 3rd duplication site), `vscodium-theme.sh`, `matugen/config.toml`, all 9 `matugen/templates/*`, `gtk-3.0`/`gtk-4.0` config files, `walker/config.toml`, `uwsm/env*`, `hypr/config/{autostart,env,keybinds}.conf`, `stow.sh`, `install.sh`, `.stow-local-ignore`, `themes/.config/themes/{css,gtk,static,kitty,yazi,vscodium}/*`, `git log` on generated-file paths, `debug.txt`
- `.planning/research/{SUMMARY,STACK,PITFALLS,ARCHITECTURE}.md` — project-level research, treated as primary prior-work input for this project

### Secondary (MEDIUM confidence)
- GNOME Discourse thread (GTK developer reply confirming no `~`/`$HOME`/env-var expansion in GTK CSS `@import`) — `discourse.gnome.org/t/home-directory-variable-in-gtk-css/7780`
- `parnoldx/omarchy-config-agent` community doc describing a `hotreload_theme` key — **contradicted by direct source verification this session**, kept in Sources for the record but should not be trusted going forward for this repo
- AUR package listing for `elephant-websearch` (existence corroborated via websearch, not independently confirmed with `paru -Si` this session — see Assumption A2)

### Tertiary (LOW confidence)
- `walkerlauncher.com/docs/configuration` — fetched directly this session; notably did NOT list `hotreload_theme`, which is itself evidence (absence), but the page may simply be incomplete/outdated documentation rather than authoritative
- General websearch results on matugen ecosystem conventions, uncorroborated by a second independent source (carried over from project-level research, not re-verified this session)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every version/presence claim directly verified against this machine this session
- Architecture: HIGH — target-state diagram composed entirely from empirically-verified matugen/GTK behaviors, not assumption
- Pitfalls: HIGH for the 4 new pitfalls (all directly reproduced or source-verified this session); HIGH (reconfirmed) for the 8 carried over from project-level PITFALLS.md
- Walker hotreload correction: HIGH — verified against the exact installed source tag, not inferred

**Research date:** 2026-07-07
**Valid until:** 14 days (fast-moving: this research is pinned to exact installed binary versions — matugen 4.1.0, walker 2.16.2 — and their behavior; any `pacman -Syu` that bumps these before Plan 01-02/01-03 execute should trigger a quick reconfirmation of the `matugen json`/`-p` and walker-source findings above)
