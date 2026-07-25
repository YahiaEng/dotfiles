# Phase 6: Themed Surfaces & Utility Suite - Research

**Researched:** 2026-07-12
**Domain:** Hyprland/Wayland desktop utility tooling (screenshot/record/OSD/pickers) + GTK3/CSS/DSL theming pipeline extension
**Confidence:** MEDIUM (HIGH on package/registry facts verified directly against AUR RPC + archlinux.org this session; MEDIUM on tool-specific config-key names, verified via docs/WebSearch but not run on this machine; LOW/ASSUMED flagged individually below)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Screenshot suite (SHOT-01/02/03)**
- D-01: Capture backend is **hyprshot** (region/window/full via grim+slurp, window geometry from hyprctl). Freeze-on-select enabled (`-z`). Old bare `screenshot.sh` is replaced.
- D-02: Every capture pipes **straight into satty** — satty owns save+copy+notify. Instant-out: Enter (or Ctrl+C) = copy + save to `~/Pictures/Screenshots` + exit. Default pre-selected tool: **arrow**.
- D-03: Recorder is **gpu-screen-recorder** (AUR/official — see Package Legitimacy Audit) — NVENC hardware encode on the RTX 3070. wl-screenrec and wf-recorder rejected (no working NVIDIA hardware path). Omarchy's `omarchy-capture-screenrecording` is the reference implementation.
- D-04: GIF export is a **notification action** (Open / Export GIF) on the recording-saved notification; conversion is an ffmpeg palette-pass next to the `.mp4`.
- D-05: Keybinds move to the **Omarchy-style Print-key family**: Print = region, Shift+Print = window, Ctrl+Print = full, Alt+Print = record toggle. Super+X/Z are freed.
- D-06: Record start opens a **pipeline-themed walker `--dmenu` audio picker** (silent / desktop audio / desktop+mic) before region select — reuse Phase 5's exit-code-130 cancel pattern.
- D-07: Recording feedback is notification on start + same-key toggle to stop. No waybar indicator this phase (Phase 8).
- D-08: Save locations unchanged: screenshots → `~/Pictures/Screenshots`, recordings → `~/Videos`, timestamped filenames.

**wlogout redesign (WLOG-01)**
- D-09: Layout: **minimal center bar** — compact horizontal row of icon buttons floating over the blurred/dimmed desktop, label on hover/focus. All six actions kept.
- D-10: Icons are **Nerd Font glyphs rendered as button text** — SVG assets deleted; colors come from the existing `wlogout.css` pipeline target.

**hyprlock redesign (LOCK-01)**
- D-11: **Info-rich lock screen**: user avatar, now-playing (playerctl, hidden when nothing plays), battery + caps-lock indicators, failed-attempts counter.
- D-12: Avatar is a **themed initial** — styled circle rendering the user's initial in palette colors. No photo asset, no `~/.face` dependency.
- D-13: Background stays the **blurred current wallpaper** (`$image`), blur/dim re-tuned for the busier layout.
- D-14 (safety): All hyprlock testing follows Phase 4's documented lockout-recovery procedure (second TTY logged in, `pkill hyprlock`) — a launch requirement, not a follow-up.

**Utility pickers (UTIL-01..05)**
- D-15: Clipboard (UTIL-03): **cap ~100 entries + wipe on logout** (session-end hook) + a manual "wipe now" entry in the picker. Existing Super+C walker dmenu flow stays.
- D-16: Icon themes bundled (UTIL-04): **Papirus + Tela + Colloid**, Adwaita remains fallback.
- D-17: **Folder accent colors track the theme**: when Papirus is active, theme-apply runs `papirus-folders` toward the palette's primary hue; Tela/Colloid use nearest fixed variant.
- D-18: Nerd fonts bundled (UTIL-05): **rice classics 5-pack** — JetBrains Mono, CaskaydiaCove, Hack, Iosevka, Meslo (all official-repo `ttf-*-nerd`) alongside existing FiraCode/FiraMono. Picker enumerates installed `ttf-*-nerd` dynamically.
- D-19: Font choice is an **independent axis** from theme: its own state file, survives theme switches; templates reference the font variable and theme-apply re-renders with the current font.
- D-20: Icon-theme picker and font switcher use **fzf-in-floating-kitty with rich previews** (wallpaper-picker pattern, NOT walker dmenu).
- D-21: Emoji (UTIL-01): walker + elephant-symbols (locked); selection is **typed directly into the focused app** (wtype/ydotool) AND copied to clipboard as backup.
- D-22: Color picker (UTIL-02): hyprpicker → hex copied, with a notification showing hex value + swatch.

**SwayOSD (OSD-01)**
- D-23: Trigger wiring: **Hyprland media-key binds calling `swayosd-client` + the libinput backend service** (systemd user unit, enabled via install.sh) so caps-lock OSD works without a keybind. Mute AND mic-mute both route through `swayosd-client`.
- D-24: Look: **bottom-center rounded pill** with icon + progress bar, themed via a new matugen template + contract.json entry.
- D-25: Brightness scope (desktop, no backlight): volume + caps-lock are the deliverable; researcher evaluates a **ddcutil → swayosd custom-progress wrapper** for monitor DDC brightness — include if straightforward, descope with evidence if flaky.

**Zen browser (THM-05)**
- D-26: Profile chicken-and-egg (confirmed live: zen-browser-bin installed, `~/.zen` absent): **lazy self-heal** — theme-apply resolves the default profile from `~/.zen/profiles.ini` on each run, skips gracefully (logged, non-fatal) when absent, and auto-wires the userChrome symlink the first time a profile appears.
- D-27: Theming depth: **chrome colors only** — toolbar, tabs, sidebar, URL bar; no new-tab page or deep element styling.
- D-28: Restart policy: **notify only**. Never kill the browser.
- D-29: theme-parity validates the **rendered state-dir CSS only**; profile symlinking is the reload step's job, skipped gracefully headless.

**Contract & parity wiring**
- D-30: contract.json grows — see Reconciliation Note in Assumptions Log (UI-SPEC's own recount flags 13→18, not 17; the exact new-file list is authoritative, not the headline number).
- D-31: Satty annotation colors are pipeline-themed: default = palette primary, standard palette row incl. a true red still available.

**Keybinds**
- D-32: Print family owns capture (D-05). Freed Super+X/Z go to utilities — exact chord assignment is Claude's discretion, resolved in UI-SPEC (see below).

### Claude's Discretion
- Exact chord assignment for the four utility binds on the X/Z families — **resolved in 06-UI-SPEC.md**: `SUPER+Z` emoji, `SUPER+SHIFT+Z` icon-theme, `SUPER+X` color picker, `SUPER+SHIFT+X` font switcher.
- Satty toolbar/config details beyond D-02/D-31; exact ffmpeg GIF palette-pass flags; notification wording (**resolved in UI-SPEC Copywriting Contract**).
- Emoji injection tool choice (wtype vs ydotool) — **researched below: wtype recommended**.
- Exact variable sets per new matugen template; hyprlock target's variable naming.
- cliphist wipe-hook wiring (uwsm session-end vs Hyprland exit dispatcher) — **researched below: no native session-end hook exists; wire into wlogout's own logout/shutdown/reboot action commands**.
- GTK font-name key mapping for the font switcher's GTK surface; vscodium settings.json font update mechanics.
- wlogout hover-label mechanics and bar sizing/margins; hyprlock element positioning and typography (**mostly resolved in UI-SPEC**).
- Record-start walker picker option labels/ordering (**resolved in UI-SPEC**).
- AUR additions follow the Phase 4 precedent (human package-legitimacy gate at execution) — **see Package Legitimacy Audit: most of these packages turned out to be official-repo, not AUR, correcting this assumption.**

### Deferred Ideas (OUT OF SCOPE)
- Waybar recording-indicator module — Phase 8. Record script exposes a status probe (`pgrep -f gpu-screen-recorder`) for it.
- Utility keybinds inside the Super-key menu + searchable cheat-sheet — Phase 7 (MENU-02, MENU-07).
- ICON-BROWSE (discover/install new icon themes from the picker) — deferred beyond v2.0.
- Zen new-tab page / deep chrome styling — rejected for update-resilience (D-27).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-------------------|
| WLOG-01 | wlogout redesigned, sharp assets, shared pipeline | wlogout layout JSON format confirmed (`text` field renders as button label — Nerd Font glyph rendering pattern below); existing `wlogout.css` contract target reused, no new contract entry |
| LOCK-01 | hyprlock redesigned, shared pipeline, documented lockout-recovery | Current `hyprlock.conf` read in full (FIX-02 hardening block identified — MUST be preserved verbatim); new dedicated `hyprlock-colors.conf` template pattern designed below |
| OSD-01 | SwayOSD bound to media keys, themed via new matugen template + contract.json entry | Binary/service names verified from the installed `extra/swayosd` file list; upstream `style.scss` selector structure fetched; ddcutil custom-progress wrapper pattern found and cited |
| THM-05 | Zen follows theme switches, chrome-colors-only, restart-based reload | `profiles.ini`/`installs.ini` resolution order researched; `userChrome.css` activation mechanism (pref toggle vs new backend) researched with a version caveat |
| SHOT-01 | Region/window/full capture, freeze, save+copy, notification | hyprshot flags verified against upstream README (`-m`, `-z`, `-r`, `-c`, `-s`) |
| SHOT-02 | Annotate (arrow/text/shape/blur) before saving/copying | satty `config.toml` structure fetched from upstream repo; `early-exit`/`action-on-enter` mechanism found, version-gated to the installed 0.21.1 |
| SHOT-03 | Record region/screen to video + GIF export | gpu-screen-recorder CLI flags + Omarchy's exact reference script fetched verbatim (SIGINT stop, ffmpeg finalize pipeline) |
| UTIL-01 | Emoji picker, insert/copy | elephant-symbols `.` prefix already wired in `walker/config.toml`; provider's default "type or copy" behavior confirmed ambiguous upstream — wtype wrapper needed for guaranteed typing |
| UTIL-02 | Screen color picker, hex copied | hyprpicker already a standard companion tool to hyprshot's author's ecosystem; official-repo package confirmed |
| UTIL-03 | Clipboard history, size cap + wipe policy | cliphist `-max-items`/config-file mechanism found; `cliphist wipe` command confirmed; no native session-end hook — wiring point identified |
| UTIL-04 | Icon theme picker, applies to Thunar/GTK live | Current `gtk-3.0-settings.ini`/`gtk-4.0-settings.ini` render path read in full (icon-theme-name is currently hardcoded "Adwaita" in shell printf — must become a state-driven variable); Tela's per-color-variant install model (separate theme names, not a folder-color script) discovered — architecturally different from Papirus |
| UTIL-05 | Nerd font switcher across kitty/vscodium/GTK/waybar | All four hardcode sites located and read (kitty.conf lines 12-16, vscodium settings.json 2 keys, gtk.sh printf, 3 waybar style-*.css files) — none currently matugen-templated for font; rendering pattern designed below |

</phase_requirements>

## Summary

Phase 6 is a large, heterogeneous phase: it extends the existing render→commit→reload theme-engine pipeline (Phases 1-5) to 3-5 new surfaces (hyprlock dedicated target, SwayOSD, Zen chrome, satty annotation colors, and an edited wlogout) and, separately, ships five independently-themed-but-not-matugen-driven utility scripts (screenshot/record, emoji, color pick, clipboard, icon theme, nerd font). The two halves have different engineering shapes: the **surfaces** slot cleanly into the established `theme-apply` → `matugen` → `commit.sh`/`reload.sh` contract (same pattern as every Phase 1-5 target); the **utilities** are mostly one-shot CLI wrapper scripts that read the current palette (via the already-committed state-dir files) rather than being matugen render targets themselves — except the icon-theme and font choices, which introduce a **new kind of state**: independent, theme-orthogonal axes that must survive across theme switches and be re-applied on every `theme-apply` run (mirroring the existing per-theme `last-wallpaper` state-dir pattern, not the `current-theme` single-value pattern).

Every package this phase needs turned out to already be on the **official Arch `extra` repo** (`hyprshot`, `gpu-screen-recorder`, `satty`, `swayosd`, `hyprpicker`, `wtype`, `ddcutil`, `papirus-icon-theme`, and all five new `ttf-*-nerd` fonts) — none require AUR at all, correcting CONTEXT.md's assumption that most of these need the AUR package-legitimacy gate. Only `tela-icon-theme`, `colloid-icon-theme-git` (note: **not** `colloid-icon-theme` — the plain name doesn't exist on AUR), and `papirus-folders` are AUR, and all three verified cleanly (established maintainers, real upstream repos, non-trivial vote counts, recently updated).

The two knottiest technical unknowns are: (1) **font-family theming has no existing render path** — kitty, vscodium, GTK, and waybar all hardcode `FiraCode Nerd Font` as a literal in four structurally different places (an `include`-able kitty conf, a jq-merged JSON, a shell-printf'd `settings.ini`, and three plain, non-templated waybar CSS files with no `@import` hook today), so UTIL-05 requires wiring a genuinely new one-time integration point per surface, not just a new matugen template; and (2) **Zen's `userChrome.css` activation mechanism changed upstream recently** (the legacy `toolkit.legacyUserProfileCustomizations.stylesheets` about:config pref is reportedly no longer required on the newest Zen backend, but the exact cutover version is unconfirmed against the installed `zen-browser-bin` version) — the safe, idempotent move is to set the pref defensively via a profile-root `user.js` override (standard Firefox-family mechanism) regardless, since it is harmless on versions that ignore it.

**Primary recommendation:** Extend `contract.json` with exactly the 5 new render targets the UI-SPEC's own reconciliation implies (`hyprlock-colors.conf`, `swayosd-colors.css`, `zen-userchrome.css`, `satty-colors.toml`, plus the edited-not-added `wlogout-colors.css`), install every new package straight into `install.sh`'s `PACMAN_PKGS` (not `AUR_PKGS` — see Package Legitimacy Audit), build the font/icon-theme axes as new engine-owned state-dir files following the exact pattern `last-wallpaper/` already established (excluded from `commit.sh`'s rsync `--delete`, read at render time by `generate.sh`), and treat every new utility script (`hyprshot`→`satty`, `gpu-screen-recorder`, pickers) as a thin caller of already-committed state-dir palette values — never a second palette-rendering path.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| wlogout redesign (colors, glyphs) | Compositor-adjacent GTK surface | Theme engine (matugen render) | GTK3 CSS process launched by Hyprland's `bind = SUPER SHIFT, Q`; colors come from the existing `wlogout.css` contract target, not owned by wlogout itself |
| hyprlock redesign | Compositor-adjacent DSL surface | Theme engine (new dedicated render target) | Hyprland's own lock daemon reads a `.conf` DSL, not CSS; needs its own `hyprlock-colors.conf` template so it stops piggybacking on `hyprland.conf` (D-30) |
| SwayOSD | Standalone GTK daemon (systemd user service) | Theme engine (new render target) + Hyprland (keybind trigger) | `swayosd-server` is a persistent background service; `swayosd-client` is the CLI trigger Hyprland binds call; theming is CSS `@define-color`, same shape as swaync |
| Zen browser chrome | Browser-owned CSS surface | Theme engine (new render target) + filesystem self-heal (theme-apply) | Firefox-family reads `userChrome.css` from inside its own profile directory — theme-apply must locate and symlink into a path it doesn't own |
| Screenshot/record scripts | Hyprland-bound CLI scripts | Theme engine (read-only: palette hex consumed by satty config) | `hyprshot`/`gpu-screen-recorder`/`satty` are standalone CLI tools invoked by keybinds; they consume already-rendered state-dir values, they do not render anything themselves |
| Emoji/color/clipboard pickers | Walker (elephant backend) / standalone CLI | — | UTIL-01/02/03 reuse existing walker+elephant or single-purpose CLI tools (`hyprpicker`, `cliphist`) already wired into the desktop; no new render target |
| Icon-theme picker | fzf-in-kitty CLI script | Theme engine (gsettings write + `papirus-folders` invocation) + GTK settings.ini render | UTIL-04 changes live GTK state (`gsettings set ... icon-theme`) and must also update the engine's own rendered `gtk-*-settings.ini` so a later theme switch doesn't silently revert the icon theme back to the hardcoded "Adwaita" default |
| Nerd-font switcher | fzf-in-kitty CLI script | Theme engine (new font-axis state + 4 new render fragments) | UTIL-05 is the most theme-engine-integrated utility — it must write a persistent, theme-independent state file AND touch four different render mechanisms (kitty `include`, jq-merged vscodium JSON, shell-printf'd GTK ini, and a new waybar CSS `@import` hook) |

## Standard Stack

### Core

| Tool | Version (verified) | Purpose | Why Standard |
|------|---------------------|---------|---------------|
| hyprshot | 1.3.0 [VERIFIED: archlinux.org/packages] | Region/window/full screenshot capture (grim+slurp+hyprctl wrapper) | Purpose-built for Hyprland by the wlr-screencopy ecosystem; supports `--freeze`(`-z`), raw stdout output (`-r`), clipboard-only mode (`-c`) — exactly the D-01 feature set. Confirmed **official `extra` repo**, not AUR as CONTEXT.md assumed. [CITED: raw.githubusercontent.com/Gustash/Hyprshot/main/README.md] |
| satty | 0.21.1 [VERIFIED: archlinux.org/packages] | Screenshot annotation (arrows, text, shapes, blur) + save/copy/exit | De facto Hyprland-ecosystem annotator (successor to swappy in most 2025/2026 rice references, incl. Omarchy). TOML config with `[color-palette]` section matching D-31's palette-row requirement exactly; installed version (0.21.1) postdates the "early-exit split into two flags" change (>=0.20.1), confirmed via the Omarchy discussion thread. [CITED: github.com/gabm/Satty config.toml; github.com/basecamp/omarchy discussion #5439] |
| gpu-screen-recorder | 5.14.1 [VERIFIED: archlinux.org/packages] | Screen/region recording with NVENC hardware encode | Only actively-maintained Linux screen recorder with a real NVIDIA NVENC Wayland path (per CONTEXT.md's hardware-driven rejection of wl-screenrec/wf-recorder). Confirmed **official `extra` repo**. [CITED: git.dec05eba.com/gpu-screen-recorder] |
| swayosd | 0.3.1 [VERIFIED: archlinux.org/packages] | Themeable volume/brightness/capslock OSD pill | Already locked by OSD-01/CLAUDE.md project instructions; ships 3 binaries (`swayosd-server`, `swayosd-client`, `swayosd-libinput-backend`) + a systemd user unit + udev rules, all confirmed present in the official package's file list. [VERIFIED: archlinux.org/packages/extra/x86_64/swayosd/files] |
| hyprpicker | 0.4.7 [VERIFIED: archlinux.org/packages] | Screen color picker → hex | Hyprland-author-maintained (`hyprwm` org), same ecosystem as hyprshot; standard hex-to-clipboard picker for wlroots compositors. Official `extra` repo. |
| wtype | 0.4 [VERIFIED: archlinux.org/packages] | Synthetic keyboard input (types emoji into focused app) | Uses the Wayland `virtual-keyboard` protocol natively supported by wlroots/Hyprland — no root daemon, no `uinput` group membership needed, unlike `ydotool`. [CITED: orioninsist.org/blog/wayland-broke-my-scripts-meet-wtype-your-new-xdotool] |
| ddcutil | 2.2.7 [VERIFIED: archlinux.org/packages] | DDC/CI monitor control (brightness on external displays) | Standard Linux DDC/CI tool; feeds a `swayosd-client --custom-progress` wrapper (D-25) rather than swayosd's own built-in brightness path, which does not support DDC monitors natively. [CITED: github.com/ErikReider/SwayOSD issue #87] |
| papirus-icon-theme | 20250501 [VERIFIED: archlinux.org/packages] | Icon theme #1 of 3 (D-16) | Official `extra` repo, already the de facto standard flat icon theme; ships `papirus-folders`-compatible per-flavour folder assets. |

### Supporting (AUR)

| Package | AUR name (verified) | Purpose | Notes |
|---------|----------------------|---------|-------|
| tela-icon-theme | `tela-icon-theme` [VERIFIED: AUR RPC v5] | Icon theme #2 of 3 | 21 votes, maintained by yochananmarqos, last modified 2026-07 (this week) — actively maintained. Upstream ships **15 separate color-variant theme names** (Tela, Tela-blue, Tela-red, Tela-nord, ...) rather than a single theme + folder-color helper — see Pitfall "Tela/Colloid are not Papirus" below. |
| colloid-icon-theme-git | `colloid-icon-theme-git` [VERIFIED: AUR RPC v5] | Icon theme #3 of 3 | **Correction to CONTEXT.md**: the plain name `colloid-icon-theme` does not exist on AUR — only `colloid-icon-theme-git` (which `Provides: colloid-icon-theme` and `Conflicts: colloid-icon-theme`). Same vinceliuice author/pattern as Tela; also per-color-variant theme names. |
| papirus-folders | `papirus-folders` [VERIFIED: AUR RPC v5] | Folder-color changer for Papirus (D-17) | 33 votes, maintained by yochananmarqos, actively updated (2026-08 per LastModified epoch — verify at execution). CLI: `papirus-folders -C <name> -t <ThemeVariant>`. Accepts **only a fixed named palette** (`black, blue, breeze, bright-orange, brown, carmine-red, cyan, deeporange, green, grey, indigo, magenta, nordic, orange, oxidgreen, palebrown, paleorange, pink, red, teal, violet, white, yellow`, plus `cat-*` Catppuccin names) — no arbitrary hex. [CITED: github.com/PapirusDevelopmentTeam/papirus-folders] |

### Supporting (official repo — new nerd fonts, D-18)

| Package | Version | Font family name |
|---------|---------|-------------------|
| ttf-jetbrains-mono-nerd [VERIFIED: archlinux.org] | 3.4.0 | `JetBrainsMono Nerd Font` |
| ttf-cascadia-code-nerd [VERIFIED: archlinux.org] | 3.4.0 | `CaskaydiaCove Nerd Font` (package name uses upstream "Cascadia Code"; the patched family name is CaskaydiaCove per nerd-fonts convention — confirm via `fc-list` at execution, not hardcoded here) |
| ttf-hack-nerd [VERIFIED: archlinux.org] | 3.4.0 | `Hack Nerd Font` |
| ttf-iosevka-nerd [VERIFIED: archlinux.org] | 3.4.0 | `Iosevka Nerd Font` |
| ttf-meslo-nerd [VERIFIED: archlinux.org] | 3.4.0 | `MesloLGS Nerd Font` (verify exact family via `fc-list` — Meslo ships multiple sub-variants) |

Already-installed (no new package): `ttf-firacode-nerd`, `otf-firamono-nerd` (both already in `install.sh` `PACMAN_PKGS`).

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| wtype | ydotool | ydotool needs a root `uinput`-based daemon + group membership and types more slowly; wtype needs neither and matches Hyprland's native virtual-keyboard protocol. Locked here per this research; document as the D-21 discretion resolution. |
| papirus-folders (script mutating one theme) | Ship 24 pre-baked Papirus color variants like Tela/Colloid | Papirus's own upstream ships exactly one theme name; `papirus-folders` is the standard, actively-maintained companion tool for exactly this use case — no reason to deviate. |
| gpu-screen-recorder | OBS Studio (headless/CLI mode) | OBS is far heavier (full GUI app, scene/source graph) for a single keybind-triggered record-to-file use case; gpu-screen-recorder is purpose-built and is what Omarchy itself uses. |

**Installation (corrected — see Package Legitimacy Audit for the AUR/official split):**
```bash
# install.sh PACMAN_PKGS += (official extra repo, NOT AUR)
hyprshot gpu-screen-recorder satty swayosd hyprpicker wtype ddcutil \
  papirus-icon-theme ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd \
  ttf-hack-nerd ttf-iosevka-nerd ttf-meslo-nerd

# install.sh AUR_PKGS += (still AUR)
tela-icon-theme colloid-icon-theme-git papirus-folders
```

## Package Legitimacy Audit

> Ecosystem note: this phase's new dependencies are Arch pacman/AUR packages, not npm/PyPI/crates — the `gsd-tools query package-legitimacy check` seam targets those three ecosystems and does not apply directly. The equivalent ecosystem-appropriate verification was performed manually this session: (1) `archlinux.org/packages/search/json` for official-repo membership, (2) AUR RPC v5 `info` endpoint for AUR packages (maintainer, vote count, first-submitted/last-modified timestamps, upstream URL) — the same signals `package-legitimacy check` would compute for npm, applied to the correct registry.

| Package | Registry | Age | Popularity signal | Source repo | Verdict | Disposition |
|---------|----------|-----|--------------------|--------------|---------|-------------|
| hyprshot | pacman `extra` | official repo (not AUR) | N/A — official repo | github.com/Gustash/Hyprshot | OK | Approved — move to `PACMAN_PKGS`, not `AUR_PKGS` |
| gpu-screen-recorder | pacman `extra` | official repo | N/A | git.dec05eba.com/gpu-screen-recorder | OK | Approved — move to `PACMAN_PKGS` |
| satty | pacman `extra` | official repo | N/A | github.com/Satty-org/Satty (or gabm/Satty upstream) | OK | Approved — move to `PACMAN_PKGS` |
| swayosd | pacman `extra` | official repo | N/A | github.com/ErikReider/SwayOSD | OK | Approved — move to `PACMAN_PKGS` |
| hyprpicker | pacman `extra` | official repo | N/A | github.com/hyprwm/hyprpicker | OK | Approved — move to `PACMAN_PKGS` |
| wtype | pacman `extra` | official repo | N/A | github.com/atx/wtype | OK | Approved — move to `PACMAN_PKGS` |
| ddcutil | pacman `extra` | official repo | N/A | www.ddcutil.com | OK | Approved — move to `PACMAN_PKGS` |
| papirus-icon-theme | pacman `extra` | official repo | N/A | github.com/PapirusDevelopmentTeam/papirus-icon-theme | OK | Approved — move to `PACMAN_PKGS` |
| ttf-{jetbrains-mono,cascadia-code,hack,iosevka,meslo}-nerd (×5) | pacman `extra` | official repo | N/A | ryanoasis/nerd-fonts upstream | OK | Approved — move to `PACMAN_PKGS` |
| tela-icon-theme | AUR | first submitted 2020, last modified this week | 21 votes | github.com/vinceliuice/Tela-icon-theme | OK | Approved — `AUR_PKGS`, human package-legitimacy gate at execution per project precedent |
| colloid-icon-theme-git | AUR | first submitted 2022 | 14 votes | github.com/vinceliuice/Colloid-icon-theme | OK | Approved — **name correction**: use `colloid-icon-theme-git`, not `colloid-icon-theme` (doesn't exist) |
| papirus-folders | AUR | first submitted 2020, actively maintained | 33 votes, popularity 0.76 | github.com/PapirusDevelopmentTeam/papirus-folders | OK | Approved — `AUR_PKGS` |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none — every package resolved to an established upstream with a real GitHub source repo and (for AUR entries) a named, multi-year-active maintainer.

**Key correction for the planner:** CONTEXT.md's "Claude's Discretion" note assumed most of these packages need AUR + a human package-legitimacy checkpoint (Phase 4 precedent). In fact only 3 of 12 new packages are AUR (`tela-icon-theme`, `colloid-icon-theme-git`, `papirus-folders`); the rest are official `extra` repo and need no AUR-helper install path at all — this simplifies `install.sh` and removes 9 packages from the human-verification burden. The 3 remaining AUR packages should still get a `checkpoint:human-verify` task per project precedent, but this is a much smaller gate than CONTEXT.md implied.

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────────────────┐
                         │   Hyprland keybinds.conf     │
                         │  (Print family, X/Z chords)  │
                         └───────────┬───────────────────┘
                                     │
        ┌────────────────────────────┼─────────────────────────────┐
        │                            │                              │
        ▼                            ▼                              ▼
┌───────────────┐          ┌──────────────────┐          ┌──────────────────┐
│ hyprshot -m .. │          │ record-toggle.sh  │          │ utility pickers   │
│  -z --raw -    │          │ (walker dmenu     │          │ (emoji/color/     │
└───────┬────────┘          │  audio picker →    │          │  clip/icon/font)  │
        │ stdout PPM        │  gpu-screen-recorder)│         └──────┬───────────┘
        ▼                   └──────────┬─────────┘                 │
┌────────────────┐                     │ SIGINT to stop            │
│ satty --filename -│                   ▼                          │
│ (owns save+copy+ │          ┌──────────────────┐                │
│  notify, D-02)   │          │ ffmpeg finalize +  │                │
└────────────────┘           │ GIF palette-pass   │                │
                              │ (notification      │                │
                              │  action, D-04)      │                │
                              └──────────────────┘                 │
                                                                     │
   ┌─────────────────────────────────────────────────────────────┘
   │
   ▼
┌──────────────────────────────────────────────────────────────────────┐
│                     theme-engine/theme-apply (existing)                 │
│  generate.sh (matugen render + shell-render for non-matugen targets)   │
│      │                                                                   │
│      ├─► matugen json/image ─► [contract.json 13→18 files, incl.       │
│      │                          hyprlock-colors.conf, swayosd-colors.css,│
│      │                          zen-userchrome.css, satty-colors.toml]   │
│      │                                                                   │
│      └─► shell printf (mode-aware, non-matugen) ─► gtk-*-settings.ini   │
│                                                       (NOW icon-theme-  │
│                                                        name state-driven,│
│                                                        UTIL-04)         │
│                                                     kitty-font.conf     │
│                                                       (NEW, UTIL-05)    │
│                                                                          │
│  commit.sh  ─► rsync into ~/.local/state/theme/ (atomic)                │
│                 excludes: logs/, last-wallpaper/, current-theme,        │
│                 + NEW: icon-theme/, font-choice (independent axes)      │
│                                                                          │
│  reload.sh  ─► existing fan-out (hyprctl, waybar SIGUSR2, kitty         │
│                 SIGUSR1, swaync -rs, walker restart, vscodium merge)    │
│                 + NEW: swayosd style reload, Zen notify-only,           │
│                 papirus-folders accent, waybar font @import wire-up     │
└──────────────────────────────────────────────────────────────────────┘
   ▲
   │ palette hex values consumed READ-ONLY (not rendered) by:
   │
┌──┴───────────────────────────────────────────────────────────────────┐
│ Utility pickers read ~/.local/state/theme/fzf-colors.conf (existing)  │
│ satty-colors.toml is matugen-rendered directly — satty needs no       │
│   runtime palette read, its config IS the rendered file               │
└─────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure (additions only)

```
hypr/.config/hypr/scripts/
├── capture-region.sh       # hyprshot -m region -z --raw | satty --filename -
├── capture-window.sh       # hyprshot -m window ...
├── capture-full.sh         # hyprshot -m output ...
├── record-toggle.sh        # audio picker (walker --dmenu) + gpu-screen-recorder + SIGINT stop
├── gif-export.sh           # notification-action callback, ffmpeg palette-pass
├── emoji-picker.sh         # walker -s <symbols set> | wtype -  (+ wl-copy backup)
├── color-picker.sh         # hyprpicker -a -f hex | wl-copy + notify-send swatch
├── clipboard-wipe.sh       # cliphist wipe + confirmation dmenu (D-15 manual wipe entry)
├── icon-theme-picker.sh    # fzf-in-kitty (wallpaper-picker.sh pattern) + gsettings + papirus-folders
└── font-switcher.sh        # fzf-in-kitty (wallpaper-picker.sh pattern) + font-axis state write

theme-engine/.config/theme-engine/lib/
├── font.sh                 # NEW: theme_engine_render_font_files (mirrors gtk.sh's render_gtk_settings shape)
└── icon-theme.sh           # NEW: theme_engine_apply_icon_theme (gsettings write + papirus-folders accent call)

matugen/.config/matugen/templates/
├── hyprlock-colors.conf    # NEW — hypr-vars format, same 19 keys as hyprland-colors.conf
├── swayosd-colors.css      # NEW — gtk-css format, same as swaync-colors.css
├── zen-userchrome.css      # NEW — css-literal format (CSS custom properties, not @define-color)
└── satty-colors.toml       # NEW — toml format, renders the [color-palette] array (D-31)

swayosd/.config/swayosd/
└── style.css                # NEW stow package — @import from state dir, mirrors swaync's pattern

satty/.config/satty/
└── config.toml               # NEW stow package — @import-equivalent: theme-apply symlinks
                               #   satty-colors.toml's rendered palette array in, or satty's config
                               #   itself becomes the rendered file directly (simplest — no separate
                               #   static config needed since D-31's only themed piece is the palette)
```

### Pattern 1: Independent theme-orthogonal state axis (font choice, icon theme)

**What:** A user choice that must persist across theme switches (unlike `current-theme` which the wallpaper/theme pickers change together) and must be re-applied on every subsequent `theme-apply` run regardless of which theme is active.
**When to use:** UTIL-04 (icon theme) and UTIL-05 (font) — both explicitly called out as independent axes in CONTEXT.md D-19.
**Existing precedent to copy exactly:** `theme-engine/lib/wallpaper.sh` + `commit.sh`'s `last-wallpaper/` directory — a per-theme state file, explicitly excluded from `commit.sh`'s `rsync --delete` (`--exclude=last-wallpaper/`), read back at the point of use.
```bash
# Pattern (font axis, new lib/font.sh, called from generate.sh alongside
# theme_engine_render_gtk_settings):
theme_engine_render_font_files() {
    local tmp="$1"
    local font_state="$HOME/.local/state/theme/font-choice"
    local font_name
    font_name="$(cat "$font_state" 2>/dev/null || echo "FiraCode Nerd Font")"

    local out_dir="$tmp$STATE_DIR"
    mkdir -p "$out_dir"

    # kitty: included by kitty.conf's SECOND include line (new one-time wire-up)
    printf 'font_family      %s\nbold_font        %s Bold\nitalic_font      %s Italic\nbold_italic_font %s Bold Italic\n' \
        "$font_name" "$font_name" "$font_name" "$font_name" > "$out_dir/kitty-font.conf"

    # GTK settings.ini gtk-font-name key — folded into the EXISTING
    # theme_engine_render_gtk_settings printf call, not a separate file
    # (avoids a second settings.ini write racing the mode-aware one).
}
```
`commit.sh` must add `--exclude=font-choice --exclude=icon-theme` (or whichever state filenames are chosen) to its rsync call, same as `last-wallpaper/`/`current-theme` today — **these are engine-owned root-level files that are not part of the matugen-rendered tree, exactly the WR-02/CR-01 bug class already fixed twice in commit.sh's history.**

### Pattern 2: Non-templatable static CSS gets a one-time `@import` wire-up, never in-place sed

**What:** waybar's `style-{full,minimal,floating}.css` currently hardcode `font-family: "FiraCode Nerd Font", ...;` as plain stowed (git-tracked) CSS — there is no existing matugen template or `@import` hook for font in these files (unlike colors, which already `@import url("../../.local/state/theme/waybar.css")`).
**When to use:** Any surface where the thing needing to vary (font) lives in a git-tracked stylesheet that was never designed to be regenerated.
**Why it matters:** Editing the stowed CSS file in place (e.g., via `sed`) would break the "git tree stays clean on switch" invariant this whole engine is built around (Established Pattern: Rendered-file + state-dir pattern). Do not do this.
**Correct approach:** Add a **second** `@import url("../../.local/state/theme/waybar-font.css");` line to all three `style-*.css` files (one-time stow-package edit, not a render), placed **after** the existing color import so cascade order lets a later `font-family` declaration win over any earlier one; `theme-apply` then always writes `waybar-font.css` (shell-rendered, contract.json entry, non-matugen — same shape as `gtk-*-settings.ini`).
```css
/* waybar/.config/waybar/style-full.css — ADD after existing @import */
@import url("../../.local/state/theme/waybar.css");
@import url("../../.local/state/theme/waybar-font.css");   /* NEW */
```

### Pattern 3: Nerd Font glyph as GTK button label (wlogout, D-10)

**What:** wlogout's layout JSON has a `text` field per button that is a real GTK `label` widget — confirmed against the upstream `ArtsyMacaw/wlogout` README (the actually-installed AUR fork, `wlogout` package). This is a regular GTK label, so any Unicode codepoint (including Nerd Font private-use-area glyphs) renders as long as the font family applied to `button label` includes that glyph.
**When to use:** WLOG-01's icon-source swap (SVG → glyph).
```json
{
    "label": "lock",
    "action": "uwsm app -- hyprlock",
    "text": "",
    "keybind": "l"
}
```
```css
/* wlogout/.config/wlogout/style.css */
button label {
    font-family: "FiraCode Nerd Font";  /* UI-SPEC: hardcoded literal, not the UTIL-05 font axis */
    font-size: 28px;                     /* UI-SPEC icon glyph size */
}
/* #lock background-image rule DELETED (icons/ dir removed per D-10) */
```
**Exact codepoints are Claude's discretion at execution** (resolve via `fc-list | grep NerdFont` or nerdfonts.com cheat-sheet — UI-SPEC explicitly declines to hardcode an unverified Unicode codepoint here, and this research does not verify them either; do not copy the ``-style codepoint above without confirming against the installed Nerd Font's actual cmap).

### Pattern 4: hyprshot → satty pipe (screenshot suite)

**What:** hyprshot's raw stdout mode feeds satty's stdin mode directly — no intermediate file for the pre-annotation capture.
**Source:** [CITED: raw.githubusercontent.com/Gustash/Hyprshot/main/README.md; the exact `grim -g "$(slurp)" -t ppm - | satty --filename -` idiom is the documented upstream pattern this composes with]
```bash
#!/usr/bin/env bash
# capture-region.sh
set -euo pipefail
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
hyprshot -m region -z --raw | satty --filename - \
    --output-filename "$HOME/Pictures/Screenshots/screenshot_${TIMESTAMP}.png" \
    --early-exit copy,save
```
**Verify at execution:** exact `--early-exit`/`--action-on-enter` flag names and accepted values against the INSTALLED `satty --help` (0.21.1) — the upstream config.toml sample fetched this session documents the mechanism but this research did not run the binary. This is exactly the kind of claim that should get a `checkpoint:human-verify` or a quick `satty --help` grep task, not be trusted blindly.

### Pattern 5: gpu-screen-recorder region record + SIGINT stop (Omarchy reference, verbatim structure)

**Source:** [CITED: raw.githubusercontent.com/basecamp/omarchy/master/bin/omarchy-capture-screenrecording — fetched and summarized this session]
```bash
# Selection (slurp over hyprctl monitor/window rects, snap-to-nearest under 20px²)
selection=$(echo "$rects" | slurp 2>/dev/null)
# capture_args becomes either "-w <monitor_name>" or "-w region:<dimensions>"

gpu-screen-recorder "${capture_args[@]}" -k auto -f 60 -fm cfr \
    -fallback-cpu-encoding yes -o "$filename" "${audio_args[@]}"
# audio_args: -a "default_output|default_input" -ac aac  (silent = omit -a entirely, D-06)

# Stop (toggle keybind, D-05/D-07):
pkill -SIGINT -f "^gpu-screen-recorder"
# waits up to 5s, force-kills with SIGKILL if the process hasn't exited (mirrors this
# repo's existing bounded-poll idiom already used in reload.sh/gtk.sh)
```
Omarchy's `finalize_recording()` additionally: re-encodes with libx264 only if the GOP has discardable packets (otherwise stream-copies, fast path), trims the first 0.1s, and for audio applies a 400ms mute + 50ms fade-in + -14 LUFS normalize. **Adapt, don't reinvent** — CONTEXT.md's canonical-refs section explicitly names this script as the reference implementation; the exact ffmpeg flags are Claude's discretion at execution (fetch the live script again then, since this is a moving upstream target).

### Pattern 6: ddcutil → swayosd custom-progress brightness wrapper (D-25)

**Source:** [CITED: WebSearch-surfaced gist + blog post pattern, corroborated by SwayOSD's own `--custom-progress`/`--custom-icon`/`--custom-progress-text` flags being real, documented options — MEDIUM confidence, not run on this machine]
```bash
#!/usr/bin/env bash
# ddc-brightness.sh — wraps ddcutil, feeds swayosd's generic OSD (bypasses
# swayosd's own built-in backlight path, which does not support DDC/CI
# external monitors — GitHub issue ErikReider/SwayOSD#87).
ddcutil setvcp 10 + 5   # or - 5 for lower; VCP 10 = brightness
read -r percent ratio <<< "$(ddcutil getvcp 10 | awk 'BEGIN{FS="[=,]"} /current value/ {cv=$2+0; mv=$4+0; p=int((cv*100+mv/2)/mv); r=cv/mv; printf "%d %.2f", p, r}')"
swayosd-client --custom-icon display-brightness-symbolic \
    --custom-progress-text "Brightness: ${percent}%" \
    --custom-progress "$ratio"
```
**Descope trigger (per D-25's own instruction):** if `ddcutil detect` finds no DDC-capable monitor, or `ddcutil getvcp 10` errors/times out (DDC is notoriously flaky over some HDMI/DP + GPU combinations), skip this wrapper entirely and ship volume+capslock only — this is an explicit, pre-authorized descope, not a gap to hide.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Screenshot region/window selection | A new grim+slurp+hyprctl wrapper | `hyprshot` | Already solves window-geometry lookup, freeze-on-select, and clipboard-only mode; D-01 already locks this |
| Screenshot annotation (arrows/text/shapes/blur) | A custom GTK/cairo annotator | `satty` | Purpose-built, actively maintained, TOML-configurable, matches D-02/D-31 exactly |
| Hardware-encoded screen recording | A custom ffmpeg+wf-recorder wrapper | `gpu-screen-recorder` | Handles NVENC device selection, portal fallback, and audio muxing already — CONTEXT.md already rejected the DIY alternatives for concrete NVIDIA-specific reasons |
| Volume/brightness/capslock OSD rendering | Custom layer-shell popup + progress bar widget | `swayosd` | Already GTK-CSS-themeable, already has a libinput backend for keyless capslock detection (D-23) — reinventing this is pure waste |
| Folder-icon recoloring for Papirus | A script that patches SVG fill colors | `papirus-folders` | Actively maintained, ships a curated valid-color enumeration, exactly matches D-17's use case |
| Typing Unicode into the focused Wayland app | A custom virtual-keyboard-protocol client | `wtype` | The Wayland virtual-keyboard protocol has real security/permission subtleties (compositor-side authorization) that `wtype` already handles correctly and is battle-tested for |
| Clipboard history storage/eviction | A custom clipboard-watching daemon | `cliphist` (already running) | Already deployed (`wl-paste --watch cliphist store` in autostart.conf); UTIL-03 only needs a config change (`-max-items`) + a wipe wrapper, not a new daemon |
| Nearest-color mapping (papirus-folders hex→named, D-17) | A new bespoke hue-bucket function | Adapt the **existing** `theme_engine_gtk4_accent` HSL-hue-bucket pattern in `lib/gtk.sh` | This exact problem (map an arbitrary hex to the nearest member of a small fixed enum) was already solved once this codebase, for GTK4 accent-color; copy the shape, swap the enum and thresholds |

**Key insight:** Every single new CLI tool this phase needs (hyprshot, satty, gpu-screen-recorder, swayosd, hyprpicker, wtype, ddcutil, papirus-folders, cliphist) already exists, is actively maintained, and is either already installed or one `pacman -S` away. The actual net-new engineering surface of this phase is almost entirely **glue**: keybind wiring, matugen template authoring, and the two theme-orthogonal state axes (font, icon theme) — not new capability implementation.

## Common Pitfalls

### Pitfall 1: contract.json file-count mismatch (D-30 "13→17" vs UI-SPEC's own "13→18" recount)
**What goes wrong:** CONTEXT.md says contract.json grows "13 → 17 files"; 06-UI-SPEC.md's own rendered-target inventory table lists exactly 5 new/changed templates and explicitly flags "13 existing + wlogout is an edit not an addition, +5 new = 18; if D-30's '17' figure intentionally excludes one of these, flag to planner for reconciliation."
**Why it happens:** D-30's headline number was written before the UI-SPEC's own detailed accounting.
**How to avoid:** Treat the UI-SPEC's 5-row table (`hyprlock-colors.conf`, `swayosd-colors.css`, `zen-userchrome.css`, `satty-colors.toml`, plus the wlogout edit) as authoritative — that is 4 genuinely NEW contract.json entries (13→17 is correct if wlogout doesn't count as "growth" since it's an edit to an existing entry, not a new line in the `files` array). **Resolution: contract.json's `files` array grows by exactly 4 entries (13→17); wlogout-colors.css already exists in contract.json today and is edited, not added.** Confirm this reading with the planner before task-writing.
**Warning signs:** A plan that adds 5 new entries to `contract.json`'s array, or a plan that forgets `hyprlock-colors.conf` needs its own entry distinct from the existing `hyprland.conf` one.

### Pitfall 2: Font-family theming has zero existing render infrastructure
**What goes wrong:** Assuming UTIL-05 is "just another matugen template" like every other Phase 1-5 surface.
**Why it happens:** Every prior contract.json target is either matugen-rendered or, for the two GTK settings.ini exceptions, mode-aware shell-printf'd — but font is neither a color-mode signal nor matugen-templatable (matugen's whole job is emitting palette hex values, not arbitrary user-chosen strings), and it must be an axis independent of theme identity (D-19).
**How to avoid:** Build a genuinely new `lib/font.sh` module (Pattern 1 above) parallel to, not folded into, `lib/gtk.sh`'s existing mode-aware render. Budget real design/implementation time for this — it touches 4 different surfaces with 4 different injection mechanisms (kitty `include`, jq-merge, printf, new `@import`).
**Warning signs:** A plan that treats UTIL-05 as a single task instead of (at minimum) one task per surface (kitty/vscodium/GTK/waybar) plus one task for the state-file + picker itself.

### Pitfall 3: Tela/Colloid are architecturally NOT Papirus — no shared folder-color mechanism
**What goes wrong:** Assuming D-17's "papirus-folders" pattern generalizes to Tela/Colloid with a different CLI tool name.
**Why it happens:** Surface-level similarity (all three are "icon themes with color variants").
**Reality (researched this session):** Papirus ships **one** theme name ("Papirus" / "Papirus-Dark") and a separate `papirus-folders` script mutates that same theme's folder SVGs in place. Tela and Colloid instead ship **N separate, fully-baked theme directories** — one full icon set per color (`Tela-blue`, `Tela-red`, `Tela-nord`, ... — 15 variants for Tela) — installed via their own upstream `install.sh -a` (install all variants) at AUR-package-build time. "Nearest fixed variant" (D-17) for these two therefore means: pick the closest-hue **theme name** and `gsettings set ... icon-theme "Tela-<name>"` (a full icon-theme swap), not a folder-recolor call.
**How to avoid:** Verify at execution exactly which variants the `tela-icon-theme`/`colloid-icon-theme-git` AUR PKGBUILDs actually install (full `-a` set vs. just `standard`) before writing the nearest-hue mapping — this is a real open question this research could not resolve without inspecting the live PKGBUILD.
**Warning signs:** A plan task that tries to run a `tela-folders`/`colloid-folders` command that doesn't exist.

### Pitfall 4: Zen's `userChrome.css` activation mechanism is version-dependent and unverified against the installed build
**What goes wrong:** Hardcoding the `toolkit.legacyUserProfileCustomizations.stylesheets` about:config toggle as a required step, when recent Zen versions reportedly no longer need it (a new backend for loading custom styles was mentioned in a 2026 GitHub discussion, without a clear version cutover documented).
**Why it happens:** Most existing tutorials/theme repos (catppuccin/zen-browser, zenhanced) predate this backend change and still instruct the legacy toggle.
**How to avoid:** Write the pref defensively and idempotently via a `user.js` file dropped at the profile root (`~/.zen/<profile>/user.js`, containing `user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);`) — this is harmless on a version that ignores the pref, and correct on a version that still honors it. Do not rely on a one-time manual about:config edit (breaks the "reproduces from scratch with one script" core value).
**Warning signs:** A UAT report of "Zen chrome colors don't apply even though `userChrome.css` looks correct and the browser was restarted" — check this pref/backend distinction first before assuming the CSS selectors are wrong.

### Pitfall 5: profiles.ini vs installs.ini — resolve the RIGHT file for "the default profile"
**What goes wrong:** Parsing only the legacy `profiles.ini` `[General] Default=` (or `Default=1` flag on a `[ProfileN]` section), which is what most naive scripts do, and getting it wrong on a modern multi-install Firefox-family browser.
**Why it happens:** `profiles.ini`'s own `Default=` key is now considered fallback/legacy; the authoritative "which profile does THIS install use" answer for current Firefox-family browsers lives in a separate `installs.ini` file, keyed by a hash of the install path (`[<hash>] Default=Profiles/xxxx.default-release`).
**How to avoid:** D-26's self-heal logic should read `installs.ini` first (only one install-hash section expected on a single-user desktop — take it unconditionally if there's exactly one), falling back to `profiles.ini`'s `Default=`/`Default=1` only if `installs.ini` is absent or empty. [CITED: support.mozilla.org/en-US/kb/understanding-depth-profile-installation; bugzilla.mozilla.org/show_bug.cgi?id=1553929]
**Warning signs:** The self-heal silently wires the wrong (non-default, e.g. a leftover dev/testing) profile on a machine that has ever run Zen with `-P` or multiple profiles.

### Pitfall 6: Icon-theme choice is currently hardcoded and WILL be silently reverted by any theme switch unless fixed
**What goes wrong:** UTIL-04's picker calls `gsettings set org.gnome.desktop.interface icon-theme "Papirus"` directly and appears to work — until the next `Super+T` theme switch, at which point `theme_engine_render_gtk_settings` (in `generate.sh`) unconditionally re-writes `gtk-icon-theme-name=Adwaita` into the freshly-rendered `settings.ini`, and `theme_engine_gtk_reload`'s own `gsettings set ... gtk-theme ""` dance (used to force GTK3 to reload) can also stomp icon-theme state depending on timing.
**Why it happens:** `gtk-icon-theme-name=Adwaita` is a literal in the existing `theme_engine_render_gtk_settings` printf call (verified directly in `theme-engine/.config/theme-engine/lib/generate.sh` lines 106-112) — it was never meant to vary, because icon themes didn't exist as a concept in this pipeline before Phase 6.
**How to avoid:** Read the new icon-theme state file inside `theme_engine_render_gtk_settings` itself (same function, one more `cat state-file || echo "Adwaita"` line) rather than writing icon-theme via a separate, un-synchronized `gsettings` call from the picker script. The picker script should WRITE the state file and trigger a full `theme-apply` re-run (or at minimum re-invoke `theme_engine_gtk_reload`), exactly like the wallpaper-picker's "post-selection re-run theme-apply" pattern (D-05/D-11/D-20 in Phase 5) — never a bare, one-off `gsettings set`.
**Warning signs:** UAT step "pick an icon theme, then switch themes, confirm icon theme survives" fails — this is the single highest-value regression test for UTIL-04.

## Code Examples

### hyprlock dedicated color target (D-30, extending the existing hyprland-colors.conf pattern)
```
# matugen/.config/matugen/templates/hyprlock-colors.conf — Source: pattern
# copied verbatim from the existing hyprland-colors.conf template (not
# fetched from an external source; this repo's own established convention)
$primary = rgba({{colors.primary.default.hex_stripped}}ff)
$on_primary = rgba({{colors.on_primary.default.hex_stripped}}ff)
$secondary = rgba({{colors.secondary.default.hex_stripped}}ff)
$surface = rgba({{colors.surface.default.hex_stripped}}ff)
$on_surface = rgba({{colors.on_surface.default.hex_stripped}}ff)
$tertiary = rgba({{colors.tertiary.default.hex_stripped}}ff)
$error = rgba({{colors.error.default.hex_stripped}}ff)
# ... all 19 keys, same format
```
```toml
# matugen/.config/matugen/config.toml — new entry
[templates.hyprlock]
input_path = "~/.config/matugen/templates/hyprlock-colors.conf"
output_path = "~/.local/state/theme/hyprlock.conf"
```
```
# hypr/.config/hypr/hyprlock.conf — top of file, replaces the current
# `source = ~/.local/state/theme/hyprland.conf` coupling (D-30's explicit
# goal: hyprlock stops piggybacking on hyprland.conf)
source = ~/.local/state/theme/hyprlock.conf
```

### satty color-palette rendering (D-31, TOML format target — verbatim from UI-SPEC, reproduced here as the confirmed-real satty schema)
```toml
# matugen/.config/matugen/templates/satty-colors.toml
[color-palette]
palette = [
  "{{colors.primary.default.hex_stripped}}ff",
  "{{colors.secondary.default.hex_stripped}}ff",
  "{{colors.tertiary.default.hex_stripped}}ff",
  "{{colors.on_surface.default.hex_stripped}}ff",
  "{{colors.background.default.hex_stripped}}ff",
  "E53935ff",
  "{{colors.outline.default.hex_stripped}}ff",
]
```
[Source: gabm/Satty upstream `config.toml` `[color-palette]` structure, RRGGBBAA format, `custom` sub-array also available — fetched this session]

### elephant-symbols → wtype wiring (UTIL-01, D-21)
```bash
#!/usr/bin/env bash
# emoji-picker.sh — walker's own symbols provider action is documented
# only as "copies to clipboard or types it" with no confirmed default
# (WebSearch of walkerlauncher.com/docs/providers could not resolve
# which). Do not trust walker's built-in action alone for the "typed
# directly into the focused app" requirement (D-21) — wrap explicitly.
set -euo pipefail
SELECTED=$(walker --dmenu -s symbols --placeholder "Search Emoji...") || exit 0
[[ -z "$SELECTED" ]] && exit 0
EMOJI="${SELECTED%% *}"   # elephant-symbols list format: "😀 grinning face" — verify separator at execution
wtype "$EMOJI"
wl-copy <<< "$EMOJI"
notify-send -a "Emoji Picker" "Emoji Inserted" "${EMOJI} typed and copied to clipboard" -i face-smile -t 2000
```
**Verify at execution:** the exact stdout format `walker -s symbols`/`elephant generatedoc symbols` produces (this research could not confirm the separator between glyph and name, or whether walker's dmenu mode for this provider even emits the raw glyph vs. a name string) — flag as a `checkpoint:human-verify` or a first-task spike before wiring the rest of the script around an assumed format.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|-------------------|---------------|--------|
| Bare `grim`/`slurp` screenshot.sh (this repo's current state) | `hyprshot` (structured wrapper) → `satty` (annotator) | This phase | Adds freeze-on-select, window-geometry lookup without manual `hyprctl activewindow -j` parsing, and full annotation before save — the exact SHOT-01/02 gap this repo currently has |
| `swappy` (older Sway-ecosystem annotator, common in 2023/2024 tutorials) | `satty` | satty has been the more actively maintained/richer-featured tool across 2025/2026 rice references (Omarchy uses it) | Do not follow older swappy-based tutorials found during execution-time research — they are the previous generation of this exact tool category |
| `toolkit.legacyUserProfileCustomizations.stylesheets` about:config toggle (universal Firefox-family requirement, still true for stock Firefox) | Possibly no longer required on newest Zen builds (unconfirmed cutover version) | Reported in a 2026 zen-browser/desktop GitHub discussion | Write the pref defensively via `user.js` regardless (Pitfall 4) rather than betting on either behavior |
| `wl-screenrec`/`wf-recorder` for Wayland screen recording | `gpu-screen-recorder` for any NVIDIA-GPU Wayland setup | Ongoing — VAAPI-via-libva-nvidia-driver has long-standing gaps on NVENC-capable hardware | CONTEXT.md already made this call with concrete hardware evidence (RTX 3070) — do not relitigate during planning |

**Deprecated/outdated:** the pre-Phase-6 `screenshot.sh` (bare grim/slurp, no annotation, no freeze) is fully replaced by D-01/D-02 — delete it, do not keep it as a fallback path (CONTEXT.md is explicit: "The old bare `screenshot.sh` is replaced").

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|-----------------|
| A1 | `satty`'s exact CLI/config flag names for "Enter = copy+save+exit" (`--early-exit`, `--action-on-enter`) match the upstream docs fetched this session, on the specifically-installed 0.21.1 build | Code Examples, Pattern 4 | Low-medium — wrong flag name is a fast, obvious failure (`satty: unrecognized option`) caught on first manual test, not a silent misbehavior; fix is a one-line flag-name correction against `satty --help` |
| A2 | `hyprshot`'s AUR-fork-turned-official-package still exposes identical `-m/-z/-r/-c/-s` flags as the upstream `Gustash/Hyprshot` README describes | Standard Stack, Pattern 4 | Low — same fast-fail profile as A1; confirm with `hyprshot --help` at execution |
| A3 | The `elephant-symbols` provider's dmenu output format (glyph + name, separator character) | Code Examples (emoji picker) | Medium — a wrong assumed separator could silently type/copy the wrong substring (e.g. the name instead of the glyph) without an obvious error; explicitly flagged for a spike/checkpoint above |
| A4 | Zen's newest builds no longer require the `toolkit.legacyUserProfileCustomizations.stylesheets` pref, sourced from a single 2026 GitHub discussion thread without a confirmed version cutover | Pitfall 4, State of the Art | Low — mitigated by writing the pref defensively regardless (harmless either way); the actual risk this note guards against is a planner treating the manual-toggle step as still strictly required and adding unnecessary user-facing setup friction |
| A5 | Exact `tela-icon-theme`/`colloid-icon-theme-git` AUR PKGBUILD behavior — whether they install all 15/12 color variants automatically or require build-time variant selection | Pitfall 3, Standard Stack | Medium — if only the `standard` variant installs by default, D-17's "nearest fixed variant" picker has nothing to switch between for these two themes; needs a PKGBUILD read or a test install at execution before the icon-theme picker's variant-enumeration logic is written |
| A6 | Nerd Font family name strings (`CaskaydiaCove Nerd Font`, `MesloLGS Nerd Font`) match what `fc-list` actually reports for the specific `ttf-cascadia-code-nerd`/`ttf-meslo-nerd` official packages | Standard Stack (supporting fonts table) | Low — cosmetic-only risk (wrong font-family string in a config = falls back to default sans, not a crash); verify via `fc-list \| grep -i cascadia` / `grep -i meslo` once installed, before hardcoding into the font picker's display-name list |
| A7 | The `contract.json` file-count reconciliation (13→17, not 18) reading in Pitfall 1 is correct | Pitfall 1 | Medium — if wrong, a plan following the "17" reading under-provisions the `files` array by one entry; low-cost to catch (theme-parity would fail structure-parity for the missing/extra target on the very first run) but worth an explicit planner decision, not silent inference |

**If this table is empty:** N/A — see entries above; none of these block planning, all are either self-correcting on first test run or explicitly flagged for a spike/checkpoint task.

## Open Questions

1. **Does `tela-icon-theme`/`colloid-icon-theme-git`'s AUR build install all color variants, or only `standard`?**
   - What we know: upstream `install.sh -a` installs all variants; unknown whether the AUR PKGBUILD passes `-a` by default or requires a build-time variant selection prompt/flag (AUR builds are typically non-interactive, so likely `-a`, but not confirmed).
   - What's unclear: the exact PKGBUILD content (not fetched this session — would require `paru -Gp tela-icon-theme` or reading the AUR package's `.SRCINFO`/PKGBUILD directly).
   - Recommendation: first planning/execution task for UTIL-04's Tela/Colloid path should be a quick `pacman -Ql tela-icon-theme` / `ls ~/.local/share/icons/` check after install, before writing the nearest-hue-to-variant mapping logic.

2. **What exact stdout format does `walker -s symbols` / the elephant-symbols provider emit for a dmenu selection?**
   - What we know: the provider exists, is already wired via the `.` prefix in `walker/config.toml`, and its "action" is documented only as "copies to clipboard or types it" with no default specified.
   - What's unclear: whether walker's own built-in action already does what D-21 wants (type AND copy) without any wrapper at all, making the wtype wrapper redundant — or whether the built-in action does only one of the two, making the wrapper necessary.
   - Recommendation: a 5-minute manual check at execution time (`walker -s symbols`, select an emoji, observe whether it typed into a test field automatically) should precede writing `emoji-picker.sh` — this could shrink UTIL-01 to zero new code if walker's default action already satisfies D-21.

3. **Exact satty config key names for "Enter = copy + save + exit" on the installed 0.21.1 build**
   - What we know: `early-exit` accepts a list of triggers (`["copy","save","save-as"]` in 0.21.0+) and `--action-on-enter` controls what Enter does; both are real, documented options.
   - What's unclear: the precise TOML key spelling and value syntax for the installed version (upstream docs/READMEs for this fast-moving tool are inconsistent across recent versions per the search results — e.g. `save-after-copy` is called out as deprecated in favor of `action_on_copy` in one source).
   - Recommendation: `satty --help` (installed binary, ground truth) should be the first thing read during the satty-config-authoring task, not this research's WebSearch-sourced examples.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| hyprshot | SHOT-01 | ✗ (not yet installed — confirmed via `pacman -Q`-equivalent research; official `extra` repo, install-time only) | 1.3.0 (extra) | none needed — one `pacman -S` away |
| satty | SHOT-02 | ✗ | 0.21.1 (extra) | none needed |
| gpu-screen-recorder | SHOT-03 | ✗ | 5.14.1 (extra) | none needed |
| swayosd | OSD-01 | ✗ | 0.3.1 (extra) | none needed |
| hyprpicker | UTIL-02 | ✗ | 0.4.7 (extra) | none needed |
| wtype | UTIL-01 | ✗ | 0.4 (extra) | ydotool (rejected — see Standard Stack rationale) |
| ddcutil | OSD-01 (D-25, conditional) | ✗ | 2.2.7 (extra) | descope brightness-via-DDC entirely per D-25's own pre-authorized fallback |
| papirus-icon-theme | UTIL-04 | ✗ | 20250501 (extra) | none needed |
| tela-icon-theme, colloid-icon-theme-git, papirus-folders | UTIL-04 | ✗ | AUR, verified above | none needed, human package-legitimacy gate at execution |
| 5× `ttf-*-nerd` | UTIL-05 | ✗ | 3.4.0 each (extra) | none needed |
| elephant-symbols, cliphist | UTIL-01/03 | already in install.sh AUR_PKGS/PACMAN_PKGS | — | already deployed, confirmed in `install.sh` read this session |
| playerctl | LOCK-01 (now-playing) | ✓ already installed (2.4.1, per CLAUDE.md verified system state) | 2.4.1 | — |
| Podman (container gate) | verify/container-run.sh regression coverage for the install.sh additions | not probed this session | — | run `command -v podman` at execution before relying on the container gate to catch install.sh regressions from this phase's new packages |

**Missing dependencies with no fallback:** none — every new dependency is a straightforward `pacman -S`/AUR-helper install with no environment-specific blocker identified.

**Missing dependencies with fallback:** ddcutil-based DDC brightness (D-25's own pre-authorized descope path if flaky).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|--------------------|
| V2 Authentication | yes (hyprlock only) | Preserve Phase 4's FIX-02 hardening verbatim (`ignore_empty_input`, `check_text`, `immediate_render`) — LOCK-01 is additive UI only, never touches the PAM/input-field auth logic |
| V3 Session Management | no | No new session/token surface introduced this phase |
| V4 Access Control | no | Single-user personal desktop; no multi-user access boundary in scope |
| V5 Input Validation | yes | Every new picker script that interpolates a user/enumeration-derived string into a filesystem path or shell command must validate against an actual enumerated allowlist first — same discipline as the existing `theme-apply`/`wallpaper-picker.sh`/`theme-switch.sh` pattern (validate against real palette filenames / real wallpaper files before path use, never trust raw fzf/walker output) |
| V6 Cryptography | no | No crypto surface this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|-----------------------|
| Path traversal via icon-theme/font picker selection (a crafted `../../` entry name reaching a `gsettings set` or file-copy call) | Tampering | Enumerate real, existing theme/font names only (`gsettings-list-icon-themes`-style directory scan or `fc-list` family enumeration), validate the picker's return value against that enumerated set before any use — mirrors the existing `wallpaper-picker.sh`/`theme-apply` discipline (Established Pattern already in this codebase) |
| Notification content injection via satty/hyprshot/ffmpeg error output reaching `notify-send` unsanitized | Tampering / Information Disclosure | Reuse the EXISTING sanitized-truncation pattern (`head -c 200 \| tr -d '\000-\011\013\014\016-\037'`) already proven in `theme-apply`'s own error path — do not invent a new error-surfacing mechanism for the new scripts |
| Clipboard history retaining secrets across sessions (pasted passwords/tokens sitting in `cliphist`'s sqlite db indefinitely) | Information Disclosure | D-15's own cap (~100 entries) + wipe-on-logout + manual wipe entry IS the mitigation — this requirement exists specifically because of this threat; do not ship UTIL-03 without the wipe policy landing in the SAME plan/wave as the cap, never as a follow-up |
| Zen profile-path resolution reading an attacker-influenced `profiles.ini`/`installs.ini` (low realistic risk on a single-user desktop, but the file IS parsed and its `Path=` value IS used to construct a filesystem path) | Tampering | Validate the resolved profile path exists and is a real subdirectory of `~/.zen` before symlinking into it (same "validate before path interpolation" discipline as V5 above) — D-26 already frames this as "lazy self-heal," which should include this validation step explicitly, not just a bare `readlink`/`ln -sf` |
| `wtype`/emoji-typing accepting unsanitized elephant-symbols provider output as a literal string to type | Tampering (low severity — types into the user's own focused window) | Low risk since the provider's own curated symbol list is the only input source (not free user text), but still validate the selected string is a recognized symbol-list entry before typing, not raw walker stdout |

## Sources

### Primary (HIGH confidence — verified directly this session)
- `archlinux.org/packages/search/json` — confirmed official `extra`-repo membership + exact installed version for: hyprshot, gpu-screen-recorder, satty, swayosd, hyprpicker, wtype, ddcutil, papirus-icon-theme, ttf-jetbrains-mono-nerd, ttf-cascadia-code-nerd, ttf-hack-nerd, ttf-iosevka-nerd, ttf-meslo-nerd
- `aur.archlinux.org/rpc/v5/info` — confirmed AUR package existence/maintainer/vote-count for: tela-icon-theme, colloid-icon-theme-git (and the nonexistence of plain `colloid-icon-theme`), papirus-folders, wlogout
- `archlinux.org/packages/extra/x86_64/swayosd/files/` — confirmed exact installed binary/service/udev filenames (`swayosd-server`, `swayosd-client`, `swayosd-libinput-backend`, `swayosd-libinput-backend.service`, `99-swayosd.rules`)
- Full read of this repo's own `theme-engine/lib/{generate,commit,reload,gtk,mode}.sh`, `theme-apply`, `contract.json`, `matugen/config.toml`, `hypr/hyprlock.conf`, `wlogout/{style.css,layout}`, `hypr/scripts/{screenshot,wallpaper-picker,theme-switch}.sh`, `keybinds.conf`, `autostart.conf`, `install.sh`, `stow.sh`, `walker/config.toml`, kitty/vscodium/waybar font-hardcode sites, `verify/container-run.sh` — every architectural claim about "how this pipeline currently works" is grounded in this direct repo read, not inference

### Secondary (MEDIUM confidence — WebFetch/WebSearch against official upstream docs)
- `raw.githubusercontent.com/basecamp/omarchy/master/bin/omarchy-capture-screenrecording` — fetched and summarized verbatim this session (gpu-screen-recorder invocation, SIGINT stop, ffmpeg finalize pipeline)
- `github.com/gabm/Satty/blob/main/config.toml` — fetched, `[general]`/`[color-palette]` structure
- `github.com/catppuccin/zen-browser/blob/main/README.md` — fetched, manual install process (no automated profile resolution shown, confirming this repo needs to build its own)
- `raw.githubusercontent.com/ErikReider/SwayOSD/main/data/style/style.scss` — fetched, selector/class structure for the new swayosd template
- WebSearch: hyprshot flags (cross-referenced against `Gustash/Hyprshot` README content surfaced in the same search)
- WebSearch: satty early-exit/action-on-enter mechanism, corroborated across 3 independent sources (lib.rs, GitHub issue #415, Omarchy discussion #5439)
- WebSearch: SwayOSD systemd service + libinput backend + ddcutil custom-progress wrapper pattern
- WebSearch: wtype vs ydotool architecture/reliability comparison
- WebSearch: Zen browser profiles.ini/userChrome.css activation mechanism (incl. the version-uncertainty flagged in Pitfall 4)
- WebSearch: papirus-folders valid-color enumeration and CLI usage
- WebSearch: Tela icon theme color-variant install model
- WebSearch: Firefox profiles.ini vs installs.ini resolution order (support.mozilla.org, bugzilla.mozilla.org)

### Tertiary (LOW confidence — flagged individually in Assumptions Log)
- elephant-symbols exact dmenu output format (A3) — not resolvable via WebSearch, needs a live check
- Exact satty CLI flag spelling on the specific installed 0.21.1 build (A1) — needs `satty --help`
- Tela/Colloid AUR PKGBUILD variant-install behavior (A5) — needs a PKGBUILD read or test install

## Metadata

**Confidence breakdown:**
- Package/registry facts (Standard Stack, Package Legitimacy Audit): HIGH — verified directly against `archlinux.org` and AUR RPC v5 this session, not WebSearch-only
- Existing-codebase architecture claims (Architecture Patterns, Pitfalls 1/2/6): HIGH — grounded in a full direct read of every relevant file this session
- New-tool CLI/config specifics (hyprshot flags, satty keys, gpu-screen-recorder flags, swayosd custom-progress, papirus-folders colors): MEDIUM — corroborated across multiple WebSearch/WebFetch sources but not run on this machine; each has an explicit "verify at execution" note
- Zen browser activation mechanism, Tela/Colloid variant model, elephant-symbols output format: LOW/uncertain — explicitly flagged in Open Questions and the Assumptions Log, not presented as settled

**Research date:** 2026-07-12
**Valid until:** ~14 days for the package/version facts (Arch `extra` repo moves fast — re-verify exact versions at execution, not this document's snapshot); ~30 days for the architectural/pattern findings (this repo's own pipeline, changes only when this repo changes)
