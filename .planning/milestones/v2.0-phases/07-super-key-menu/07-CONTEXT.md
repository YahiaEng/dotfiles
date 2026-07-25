# Phase 7: Super-Key Menu - Context

**Gathered:** 2026-07-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Tapping $SUPER alone opens an Omarchy-style walker menu that wraps the existing desktop into a coherent drill-down hierarchy — Utilities, Settings, AI dashboard, Game center, Keybind cheat-sheet, Power — without breaking a single existing $SUPER+key combo (MENU-01..07).

The menu is a **wrapper, not a rewrite**: it launches the Phase 6 utility scripts, the existing theme/wallpaper/waybar pickers, and the existing `wlogout.sh` power surface. Two genuinely new capabilities are in scope because the requirements name them: the AI dashboard (launchers + a dedicated pre-configured Hyprland workspace, MENU-03) and the Game center (launchers + a gaming-mode toggle, MENU-04) — both of which add packages to `install.sh`.

**Not in scope:** waybar rework (Phase 8 — the gaming-mode waybar-hide must be a thin, re-pointable call); the wlogout→wleave migration (Phase 9 — Power delegates to `wlogout.sh`, so that swap stays invisible to the menu); any new theme render target (the menu reuses the existing `walker-style.css` contract target).

</domain>

<decisions>
## Implementation Decisions

### Super-tap binding & keybind safety (MENU-01)

- **D-01:** **$SUPER-tap opens the MENU only.** The app launcher moves off the tap to its **own dedicated bind (Super+Space)**. Today `bind = $mainMod, SUPER_L, exec, walker` puts the launcher on the tap — that bind is replaced, not shared. Rationale: a pure hierarchy beats a fused surface; the two are distinct tools. `Super+R` (runner set) stays as-is.
  - **⛔ Footnote (added during execution, 2026-07-13):** the closing clause rested on a false premise. 07-01's D-05 spike proved `walker -s runner` — the command `Super+R` actually runs — **panics walker 2.16.2 and kills the launcher service**; "as-is" was already broken, and had been. **D-01's intent is preserved** (Super+R remains the runner launcher, on the same key), but its command is repointed to `walker -m runner` in plan 07-02. There is no longer a "runner set"; `[sets.*]` is a dead mechanism on this binary. See 07-01-PLAN.md's `<spike_correction>`.
- **D-02:** **True tap-only behaviour must be researched and PROVEN**, not approximated. Hyprland has no native bare-modifier-tap bind, and a naive `bind = SUPER, SUPER_L` fires the menu on *every* Super+key combo. The researcher must find and validate a real tap-only mechanism (release-bind semantics, submap, or an input-layer tool such as keyd/interception-tools) and demonstrate it does not shadow existing binds. This is the phase's headline risk — treat it as such. A new package is acceptable if that's what a correct solution requires.
- **D-03 (safety — launch requirement, not a follow-up):** Before ANY Super-bind experiment: (a) reserve a **never-shadowed kill-bind** (e.g. `Super+Escape` → `pkill walker`) and test it in isolation first, and (b) have the **Phase 4-style second-TTY recovery procedure** open and documented (second TTY logged in, ready to `pkill`/restore keybinds.conf). Mirrors the Phase 6 hyprlock lockout-recovery mandate (06-CONTEXT D-14).
- **D-04:** MENU-01's "full keybind regression sweep" is discharged by a **rerunnable scripted gate + a human pass**, not a one-time manual checklist. The checker parses `keybinds.conf`, asserts every declared bind is actually registered in `hyprctl binds`, and flags shadowing/duplication. This matches the repo's `theme-doctor` / `theme-parity` posture: gates you can re-run — Phase 8 and 9 both touch binds again and inherit this gate.

### Menu engine & navigation (MENU-01)

- **D-05:** **Walker's `menus` (elephant) provider is the target — but it gets SPIKED FIRST.** The provider is already enabled in `walker/.config/walker/config.toml` and currently empty. The researcher must prove walker 2.16.2's menu feature actually expresses submenus, actions, and icons **before** the plan commits to it; if it can't, fall back to the proven **bash + `walker --dmenu` chain** (Phase 5's exit-code-130 cancel pattern). Rationale is a hard-won project Key Decision: Phase 4 shipped dead hyprlock config because an installed binary silently rejected unknown options — *verify against the installed binary before relying on it*. Six submenus and the cheat-sheet all hang off this choice.
- **D-06:** **Drill-down in place.** Picking "Utilities" swaps the same walker window's list to the submenu; Esc/Backspace goes back a level; a breadcrumb sits in the placeholder (`Menu › Utilities`). Cross-submenu global search is a *bonus if walker's matcher gives it for free* — it is explicitly NOT a requirement, because it is the most likely thing the provider cannot express and chasing it drags toward hand-rolling.
- **D-07:** **Icons are Nerd Font glyphs rendered as entry text** — same call as Phase 6 D-10 (wlogout SVGs deleted). Sharp at any scale, CSS-themed for free, no assets in the repo, and — decisively — **decoupled from the Phase 6 icon-theme picker**, so switching Papirus→Tela can never silently blank the menu's icons. FiraCode NF is already verified to carry the needed glyphs.
- **D-08:** **The menu reuses the existing walker theme (`rice` / `walker-style.css`).** No dedicated menu skin. `walker-style.css` is already contract target #18, so the menu re-themes through the pipeline on day one with **zero new contract targets and zero new parity fixtures** across the 22 palettes. A second walker stylesheet is a second thing that can drift — rejected on the project's consistency-is-core-value ground.
- **D-09:** **Every GUI launch from the menu goes through `uwsm app -- …`**, exactly like `keybinds.conf` does. Preserves systemd scope isolation (which is what makes `uwsm stop` and the power actions clean) and means a menu-launched app behaves identically to a keybind-launched one. Shell scripts are invoked bare.

### Root menu shape

- **D-10:** Root = **exactly the six requirement groups, ordered by task frequency, Power LAST** (it is destructive and must not sit under the default cursor position). Every root item is a drill-down — **no pinned flat quick-actions** mixed in at the root (they'd muddy the hierarchy, and each already has a keybind).
- **D-11:** Root order and exact entry wording/glyphs are Claude's discretion within D-10's constraints.

### Utilities submenu (MENU-02)

- **D-12:** **Screenshot is a sub-submenu.** Utilities = `Screenshot ›` (region / window / full / record-toggle), `Emoji`, `Colour picker`, `Clipboard`. Four clean concepts instead of seven flat entries; capture's four variants nest where they belong. All entries invoke the **existing Phase 6 scripts unchanged** (`capture-region.sh`, `capture-window.sh`, `capture-full.sh`, `record-toggle.sh`, `emoji-picker.sh`, `color-picker.sh`, and the Super+C cliphist flow) — Phase 6 deliberately built them CLI-invokable with no interactive prerequisites for exactly this.
- **D-13:** Icon-theme picker and nerd-font switcher **move to Settings, not Utilities** (see D-15) despite MENU-02's literal wording. Split rationale: Utilities = things you **do** (transient actions); Settings = things you **configure** (persistent desktop state). Their keybinds (Super+Shift+Z / Super+Shift+X) are unchanged.

### Settings submenu (MENU-06)

- **D-14:** Settings contains: **Theme switch, Wallpaper, Icon theme, Font, Waybar layout, Network, Bluetooth, Audio, Display.**
- **D-15:** Appearance entries reuse the **existing scripts as-is** — `theme-switch.sh`, `wallpaper-switch.sh`/`wallpaper-picker.sh`, `icon-theme-switch.sh`, `font-switch.sh`, `waybar-switch.sh`.
- **D-16:** **The walker→floating-kitty transition is accepted and intentional.** Several Settings entries close the menu and open a floating kitty+fzf picker — identical to what pressing the keybind does today. The kitty pickers render **kitty-graphics previews** (wallpaper thumbnails, live font specimens, icon grids) that walker fundamentally cannot draw; rebuilding them as walker submenus would be a downgrade. **The menu is a launcher for the pickers, not a replacement.**
- **D-17:** **Network = `nmtui` in a floating kitty window** (the Phase 5/6 floating-kitty pattern). Themed by kitty for free, no new GUI package, and NetworkManager already manages the network. Rejected: nm-connection-editor (heavy GUI on a keyboard-driven desktop); impala/iwd (implies a network-stack change, not a menu decision).
- **D-18:** Bluetooth, Audio, Display get entries: bluetooth manager (blueman or overskride — researcher's call), `pavucontrol` for audio (complements Phase 6 SwayOSD), and `nwg-displays` for monitor arrangement (writes Hyprland monitor config directly).

### Power submenu (MENU-05)

- **D-19:** **Power launches the existing `~/.config/hypr/scripts/wlogout.sh`** — the same surface `Super+Shift+Q` opens. ONE power surface, ONE set of uwsm-correct actions (`hyprshutdown --post-cmd`, etc.), and Phase 6's WLOG-01 center-bar design stays the thing you see. Critically, **Phase 9's wlogout→wleave swap then becomes invisible to the menu.** Rejected: an inline walker power list — it would duplicate the power-action logic in two places and make Phase 6's redesign redundant.
- **D-20:** **`hypr/.config/hypr/scripts/powermenu.sh` is DELETED.** It is unbound, unreferenced, and already drifted (no hibernate; its own copy of the hyprshutdown calls). v1.0 set the precedent for removing dead configs, and keeping it would recreate the "duplicated orchestrators" problem the theme-engine consolidation exists to kill.

### AI dashboard (MENU-03) — greenfield, nothing AI-related is installed

- **D-21:** Three launcher classes, all three in scope:
  1. **Zen web-app windows** for **Claude, ChatGPT, Gemini, Perplexity** — dedicated Zen windows (`--new-window`/SSB-style) with Hyprland windowrules giving each its own class so it can be placed. Zero new packages, already pipeline-themed via Phase 6's Zen userChrome work (THM-05), and unbreakable by app updates.
  2. **Claude Code / CLI agent in kitty** — a terminal AI window. This repo is literally built with Claude Code, and kitty+fish starts in 33.9ms.
  3. **Local models: `ollama` + a TUI chat client** in kitty.
- **D-22:** **Local models stop at ollama + a TUI client.** **open-webui is rejected** — a Python/Docker-class dependency with its own service, port, and update surface, and it cannot be themed by the pipeline. A TUI chat client fits the existing stack and is kitty-themed for free. The exact TUI client is Claude's discretion (researcher picks; official repo strongly preferred).
- **D-23:** **`install.sh` installs and enables ollama but pulls NO model.** A multi-GB download would wreck the unattended container gate and fresh-install time. Model acquisition is a manual user step (optionally surfaced as a "pull a model" menu entry, or a first-run hint). Reproducibility stays honest.
- **D-24:** The "**dedicated pre-configured Hyprland AI workspace**" is a **reserved named workspace + windowrules + auto-layout**. Picking "AI workspace" from the menu switches to it and launches whatever isn't already running. **It must be idempotent** — picking it twice yields one set of windows, not two. Workspace number and layout are Claude's discretion (must not collide with existing Super+1..0 semantics).

### Game center (MENU-04) — greenfield, nothing gaming-related is installed

- **D-25:** Launcher submenu = **Steam, Lutris, Heroic (Epic/GOG), ProtonUp-Qt**. Steam requires **multilib enabled — `install.sh` must handle that explicitly, not assume it**. Heroic is AUR (`heroic-games-launcher-bin`) and falls under the package gate (D-29).
- **D-26:** A **"Gaming mode" toggle** ships alongside the launchers (user chose this over launchers-only). It toggles, all reversibly:
  - **Hyprland eye-candy off** — blur, animations, shadows, rounding disabled via **`hyprctl keyword` at runtime only**. **Never rewrite the Hyprland config files** — runtime-only keeps it impossible to corrupt config or desync the theme pipeline.
  - **Idle/lock inhibit** — hypridle/hyprlock suppressed so the screen can't lock mid-game.
  - **gamemode + mangohud** — installed (both official repo), but **wired into the Steam/Lutris launch commands as env/wrappers**, not as global toggle state (they're per-launch concerns).
  - **Waybar hide** — ⚠ **Phase 8 is about to rework waybar entirely** (OLED auto-hide, vertical layout). Implement this as a **thin, single-call abstraction** (waybar's own hide signal) that Phase 8 can *re-point*, rather than a bespoke hiding mechanism it would have to tear out.
- **D-27:** Gaming mode is surfaced as **one toggle entry + a notification confirming ON/OFF + a state file**, so the menu entry can display current status (`Gaming mode: ON`). **No waybar indicator this phase** — Phase 8 can add one later, exactly as Phase 6 left a status probe for the recorder (06-CONTEXT code_context).
- **D-28:** **Gaming mode is session-scoped: it RESETS TO OFF on session start.** The state file is cleared at startup and a fresh Hyprland session always begins with the full theme intact. This deliberately forecloses the classic persistent-runtime-override failure mode — a stale ON state means a silently ugly desktop and an hour lost debugging the theme pipeline.

### Keybind cheat-sheet (MENU-07)

- **D-29:** **Two surfaces.** (a) A **walker searchable list** for quick lookup (`Super+Z — Emoji picker`) — stays inside the menu, themed for free, and search *is* the feature. (b) A **"View all" entry opening a formatted, column-aligned, section-grouped table in a floating kitty window** (the Phase 5/6 rich-picker pattern) for browsing everything at once. Both read the same parsed data — keep the parser shared so they cannot diverge.
- **D-30:** **Descriptions come from `keybinds.conf` trailing `# comments`, and EVERY bind that lacks one gets back-filled.** Today only some binds carry descriptions (movefocus, workspaces, resize, media keys have none). Back-filling makes `keybinds.conf` fully self-describing and **the single source of truth** — no side-car description file (that's the exact drift pattern this project keeps removing). Phase 6 already wrote its binds this way deliberately, anticipating MENU-07.
- **D-31:** **Generated live on open** — parse `keybinds.conf` each time the entry is picked. Always truthful, can never go stale, nothing to regenerate or forget. A ~170-line file parses instantly. No caching at theme-apply or install time.
- **D-32:** The cheat-sheet must include the **new Phase 7 binds** (Super-tap → menu, Super+Space → launcher, the reserved kill-bind) — they land in `keybinds.conf` like everything else and are picked up automatically by D-31.

### Packages & reproducibility

- **D-33:** This phase adds roughly ten packages. **Official repos are strongly preferred; every AUR package gets a human package-legitimacy check at execution time** before `install.sh` gains it — the established Phase 4/6 precedent. Known AUR candidate: `heroic-games-launcher-bin` (plus possibly the ollama TUI client and any input-layer tool D-02 requires). Official-repo candidates: `steam` (+ multilib), `lutris`, `protonup-qt`, `ollama`, `gamemode`, `mangohud`, `pavucontrol`, `nwg-displays`, a bluetooth manager.
- **D-34:** The **container gate must stay green**. Nothing in this phase may add an interactive or network-heavy step to an unattended install (D-23 exists specifically for this). Menu definitions and scripts are stow-managed like everything else — no host-only state.

### Claude's Discretion

- Root menu ordering within D-10's constraints; exact entry wording; exact Nerd Font glyph per entry.
- Ordering of entries within each submenu.
- The ollama TUI chat client choice (official repo preferred) and the bluetooth manager choice (blueman vs overskride).
- AI workspace number and window layout (must not collide with Super+1..0 semantics; must be idempotent per D-24).
- The exact tap-only mechanism (D-02) — chosen on research evidence, including whether it warrants a new package.
- The reserved kill-bind's exact chord (D-03) and the Super+Space launcher bind's exact form (D-01).
- Cheat-sheet table formatting/grouping; the shared parser's implementation.
- Gaming-mode state-file location and notification wording.
- Whether the menu definitions live in one file or several (if the `menus` provider path wins, D-05).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — MENU-01..07 definitions
- `.planning/ROADMAP.md` — Phase 7 goal + 5 success criteria (note the explicit "exit-bind tested first in isolation" and "full keybind regression sweep" mandates)
- `.planning/PROJECT.md` — Key Decisions table; especially "verify options against the installed binary schema before relying on them" (the direct rationale for D-05's mandatory spike) and the Out-of-Scope line "Custom AI assistant widgets/sidebars — v2.0's AI dashboard is launchers + a workspace, not built-in assistant UI"

### Prior phase context (binding decisions carried forward)
- `.planning/phases/06-themed-surfaces-utility-suite/06-CONTEXT.md` — D-10 (Nerd Font glyphs, not SVGs), D-20 (fzf-in-floating-kitty rich-picker pattern), D-32 (the locked utility chords this cheat-sheet documents), and the explicit hand-off note: *"Phase 7 consumes everything: utility scripts become Utilities submenu entries; keybind choices feed the MENU-07 cheat-sheet; keep scripts CLI-invokable with no interactive prerequisites"*
- `.planning/phases/05-light-mode-pipeline-theme-presets/05-CONTEXT.md` — the walker-dmenu exit-code-130 cancel pattern (needed if D-05 falls back to the dmenu chain)
- Phase 4 lockout-recovery procedure — `.planning/phases/04-reliability-fixes-tech-debt/` (04-02 plan/summary). **Mandatory reading before any Super-bind experiment (D-03).**

### The surfaces under change
- `hypr/.config/hypr/config/keybinds.conf` — 169 lines. The Super-tap bind to replace is `bind = $mainMod, SUPER_L, exec, $app_launcher` (D-01). Every bind gets a back-filled description (D-30). This file is the cheat-sheet's single source of truth.
- `walker/.config/walker/config.toml` — the `menus` provider is **already enabled and empty**; `[sets.runner]` shows the set pattern; `close_when_open` / `click_to_close` / `selection_wrap` are set
- `hypr/.config/hypr/scripts/powermenu.sh` — **DELETE** (D-20)
- `hypr/.config/hypr/scripts/wlogout.sh` — the Power entry's target (D-19); do not modify
- `hypr/.config/hypr/scripts/` — the Phase 6 utility scripts the menu wraps unchanged: `capture-{region,window,full}.sh`, `record-toggle.sh`, `emoji-picker.sh`, `color-picker.sh`, `clipboard-wipe.sh`, `icon-theme-switch.sh`, `font-switch.sh`, `theme-switch.sh`, `wallpaper-switch.sh`, `waybar-switch.sh`
- `hypr/.config/hypr/config/autostart.conf` — where the gaming-mode reset-to-OFF-on-start hook lands (D-28)

### Theming (read to confirm nothing new is needed)
- `theme-engine/.config/theme-engine/contract.json` — **18 render targets today, including `walker-style.css`.** Phase 7 adds ZERO new targets (D-08).
- `matugen/.config/matugen/templates/walker-style.css` + `matugen/.config/matugen/config.toml` `[templates.walker]` — the menu inherits this styling for free
- `theme-engine/.config/theme-engine/theme-parity` — the light+dark parity gate across 22 palettes; must stay green (it should be untouched, since no new targets)

### Reproducibility
- `install.sh` — PACMAN_PKGS / AUR_PKGS arrays gain ~10 packages (D-33); **multilib must be explicitly enabled for Steam** (D-25); **no model auto-pull** (D-23)
- `stow.sh` — new state files (gaming-mode state, D-27/D-28) follow its seeding pattern
- `verify/` container gate — must stay green and unattended (D-34)

### External reference
- Omarchy (github.com/basecamp/omarchy) — the explicit aesthetic and architecture reference for the menu's shape and drill-down feel, as it was for Phase 6's capture stack. Adapt, don't reinvent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`walker-style.css` is already contract target #18** — the menu is pipeline-themed on day one with no new render target, no new parity fixtures, no new template. This is the single biggest cost saving in the phase.
- **The `menus` elephant provider is already enabled** in `walker/.config/walker/config.toml` and sitting empty — the intended home for the menu definitions, pending the D-05 spike.
- **Every Phase 6 utility script is already CLI-invokable with no interactive prerequisites** — Phase 6 built them that way *specifically* for this phase. The Utilities submenu is wiring, not new code.
- **`wlogout.sh` already encapsulates the uwsm-correct power actions** (`hyprshutdown --post-cmd`, `uwsm stop`) — Power is a one-line delegation (D-19).
- **Phase 5's exit-code-130 walker-dmenu cancel pattern** (in `theme-switch.sh`) — the fallback path's cancel handling if D-05's spike fails.
- **Phase 5/6's fzf-in-floating-kitty stack** (kitty-graphics previews, floating launcher, pipeline-themed `fzf-colors.conf`) — the cheat-sheet's "View all" table (D-29b) and the `nmtui` window (D-17) both reuse it.
- **`zen-userchrome.css` render target (Phase 6 THM-05)** — the AI web-app windows are Zen windows, so they are already pipeline-themed.

### Established Patterns
- **`uwsm app --` for every GUI launch** (keybinds.conf convention) — the menu must not create a second class of launched app (D-09).
- **Single source of truth, no side-car files** — the theme-engine consolidation, the `palettes/*.json` dynamic enumeration, and `contract.json` all exist because duplicated/drifting definitions bit this project. Directly drives D-20 (delete powermenu.sh), D-30 (no side-car descriptions), D-31 (live parse, no cache).
- **Verify against the installed binary before relying on it** (Phase 4 hyprlock Key Decision) — directly drives D-05's mandatory spike.
- **Rerunnable gates, not one-time manual checklists** (theme-doctor / theme-parity / theme-stress-test) — drives D-04's scripted keybind sweep.
- **Runtime-only state overrides, never config rewriting** — drives D-26's `hyprctl keyword` constraint.
- **Headless guards / unattended container gate** — drives D-23 and D-34.

### Integration Points
- `keybinds.conf` — the Super-tap replacement (D-01), the kill-bind (D-03), and back-filled descriptions (D-30) all land here; it becomes the cheat-sheet's data source.
- `walker/.config/walker/config.toml` — menu definitions (D-05); the launcher's new Super+Space bind changes nothing here.
- `autostart.conf` — gaming-mode reset-to-OFF hook (D-28).
- `install.sh` — ~10 packages + multilib (D-25, D-33).
- **Phase 8 (waybar)** — the gaming-mode waybar-hide (D-26) is a deliberate thin abstraction so Phase 8 can re-point it; Phase 8 may also add a gaming-mode indicator, reading the D-27 state file.
- **Phase 9 (wleave)** — D-19's delegation to `wlogout.sh` means the wleave swap requires **no menu change at all**.

</code_context>

<specifics>
## Specific Ideas

- **Omarchy remains the explicit reference** for the menu's shape and drill-down feel — as it was for Phase 6's capture stack. Adapt its architecture, don't reinvent it.
- **"The menu is a launcher for the pickers, not a replacement"** (D-16) — the user explicitly wants the walker→kitty transition, because the kitty-graphics previews (wallpaper thumbnails, live font specimens, icon grids) are worth more than a seamless single-surface feel.
- **Utilities vs Settings is a "do" vs "configure" split** (D-13), knowingly overriding MENU-02's literal wording, which lists the icon/font pickers as utilities.
- **The tap-only bind is treated as the phase's headline risk** (D-02/D-03) — the user chose the hardest, highest-fidelity option and paired it with the strongest safety net, rather than descoping to a chord.
- **Deliberate anti-drift bias throughout:** delete the dead powermenu.sh, no side-car description file, no cached cheat-sheet, no second walker stylesheet, no persistent gaming-mode state. Every one of these is the user choosing "one source of truth" over "slightly more convenient."

</specifics>

<deferred>
## Deferred Ideas

- **Waybar gaming-mode indicator** — Phase 8 (waybar is Phase 8's scope). Phase 7 leaves the D-27 state file as its probe, exactly as Phase 6 left a status probe for the recorder.
- **Global cross-submenu search** (type at root, match any leaf action anywhere) — explicitly a *bonus if free*, not a requirement (D-06). Revisit if walker's matcher turns out to support it cheaply.
- **A dedicated walker menu skin** (narrower/icon-led, distinct from the launcher) — rejected for now on drift/parity cost (D-08). Revisit only if the shared theme proves visually inadequate.
- **open-webui / a local web AI UI** — rejected (D-22) as an unthemeable Python/Docker-class dependency. Revisit only if the TUI client proves inadequate.
- **Auto-pulling a default ollama model on install** — rejected (D-23) to keep the container gate unattended. A "pull a model" menu entry is the sanctioned alternative.
- **Native AI desktop clients (AUR electron wrappers)** — rejected in favour of Zen web-app windows: unofficial wrappers are a supply-chain and maintenance liability for something a browser tab does (D-21).
- **Pinned flat quick-actions at the menu root** — rejected (D-10); they'd muddy the hierarchy and each already has a keybind.

</deferred>

---

*Phase: 7-Super-Key Menu*
*Context gathered: 2026-07-13*
