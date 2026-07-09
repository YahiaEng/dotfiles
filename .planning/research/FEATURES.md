# Feature Research

**Domain:** Hyprland desktop "rice" utilities and menus — v2.0 Desktop Expansion for an existing static+matugen theme-engine
**Researched:** 2026-07-09
**Confidence:** LOW-MEDIUM (websearch only, no MCP docs/curated sources available this run; all claims tagged LOW per `classify-confidence`; cross-referenced across 3-5 independent rices per topic where possible — treat as directionally solid but verify exact CLI flags/versions before building)

## Context

This is a **subsequent milestone** on an already-working theme-engine (static presets + matugen Material You, one pipeline, 10 desktop surfaces). This research covers ONLY the seven NEW v2.0 feature areas — it assumes the existing theme propagation pipeline, does not re-litigate it, and treats every new feature's "themed" requirement as "render through the existing `theme-apply` → `~/.local/state/theme/` pipeline," not a new theming mechanism.

Five reference rices anchor the comparison, and they split into two architectural camps:

- **Bash + Walker + waybar/swaync/wlogout camp:** **Omarchy** (basecamp), **HyDE**. Utilities are shell scripts and Rofi/Walker dmenu pickers layered onto standard Wayland tools (grim/slurp/satty, cliphist, swayosd). This is architecturally identical to this project's stack — Omarchy and HyDE are the directly-portable reference points.
- **Custom Quickshell/QML shell camp:** **end-4/dots-hyprland**, **Caelestia**. These abandoned waybar/rofi entirely for one unified QML "shell" process (bar+sidebar+dashboard+OSD+lock as one brain). Architecturally incompatible with this project's waybar-based stack without a full framework rewrite — useful only as a UX/animation aspiration, not a portable implementation pattern.
- **GTK4 settings-app camp:** **ML4W** — keeps waybar/rofi but adds a GUI settings app on top. Relevant analog for the "settings menu" item.

Given this project's existing investment (waybar, swaync, walker+elephant, wlogout, hyprlock, matugen templates), **Omarchy and HyDE are the primary implementation references; end-4/Caelestia inform aspiration/UX only.**

## Feature Landscape

### Table Stakes (Users Expect These)

Features any modern-rice user assumes exist. Missing them makes the desktop feel unfinished relative to 2025/2026 peers.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Screenshot: region/window/full capture | Baseline OS function on every DE; Wayland has no native screenshot key | LOW | `grim` (capture) + `slurp` (region select) is the universal base layer across every rice researched. |
| Screenshot annotate before save/share | Users expect to mark up a screenshot without opening a separate app | LOW-MED | `satty` is the current de-facto standard (actively maintained successor to `swappy`, "needs no ricing" — themes itself sanely by default). Omarchy pipes grim+slurp output directly into satty. |
| Screen recording (region or full) | Table stakes once screenshot suite exists; users expect symmetric capture-video capability | MED | `wf-recorder`, optionally scoped to a `slurp`-selected region. GIF output is typically a post-process (`wf-recorder` to mp4/webm, then `ffmpeg`→gif) — no rice found with native GIF capture; treat GIF as a conversion step, not a separate capture mode. |
| Clipboard history picker | Every modern rice ships one; losing copied text/images is a daily papercut | LOW | `cliphist` (Wayland-native, stores text+image blobs) piped into Walker dmenu; selection re-copied via `wl-copy`. This project already has Walker/elephant running — reuse it as the picker frontend rather than introducing rofi/wofi. |
| Emoji picker | Common productivity utility, cheap to build, expected in any "complete" launcher-driven rice | LOW | Flat emoji-list text file + `awk`/grep filtering fed into a dmenu-style picker (Walker). Trivial script, no external daemon needed. |
| Themed power menu with fast, reliable actions | A power menu that hangs or looks stock breaks the "polished rice" impression instantly — this project's own known bug (shutdown hang) is exactly this failure mode | LOW-MED (redesign) / MED (bug fix) | wlogout is the standard tool across every bash-based rice researched (Omarchy, HyDE, JaKooLit). Rendered via Wayland layer-shell as a full overlay; buttons-per-row (`-b N`) and theme-driven `style.css` are the standard customization surface. |
| Themed lock screen | Same expectation as above; lock screen is the most-seen surface after the desktop itself | LOW-MED (redesign) / MED (bug fix, focus-timing) | `hyprlock` is the only real option in this ecosystem; every Omarchy theme explicitly styles `hyprlock.conf` alongside bar/terminal/launcher — treat it as a first-class themed surface, not a system dialog. |
| Volume/brightness OSD | Un-themed default OSD (or none at all) reads as unfinished; hardware media keys must "just work" without a keybind | LOW | `swayosd` is the standard answer (GTK, plain-CSS themeable at `~/.config/swayosd/style.css`, already selected in this project's STACK.md). Its systemd `--user` service listens at the libinput level, so hardware keys work even before any Hyprland keybind is wired. |
| Media/now-playing widget in the bar | Nearly every 2025/2026 rice screenshot includes a now-playing widget; its absence is conspicuous | LOW | Waybar's **built-in** `mpris` module (backed by `playerctld`) is the standard, lowest-maintenance answer — already the STACK.md recommendation. No rice was found hand-rolling this unless they want a richer popover (see Differentiators). |
| Notification-center access from the bar | swaync running headless with no visible bar affordance is a common "forgot to finish it" gap | LOW | A waybar `custom` module (icon) that runs `swaync-client -t` (toggle control-center) on click — trivial, already the standard pattern for swaync+waybar pairings. |
| Icon theme applied consistently to file manager | Stock/mismatched icons in Thunar next to a fully-themed desktop is the single most common "this rice isn't finished" tell | LOW (apply) / MED (build a picker+installer) | `gsettings set org.gnome.desktop.interface icon-theme <name>` is the live-update mechanism (same layer this project's GTK theming already correctly uses per CLAUDE.md). Papirus (official `extra` repo) and Tela (AUR) are the two most commonly bundled icon themes across rices. |
| At least one light theme option | A rice that is "always dark" reads as incomplete/inflexible by 2025/2026 standards; light-theme users are a large, vocal minority | LOW (once static-preset pipeline exists — already does) | Not a new mechanism, just new preset content through the existing pipeline — this project's existing static-preset architecture already supports this; it's a content task, not an engineering task. |
| Wallpaper picker with live preview | Blind wallpaper selection (filename list, no thumbnail) feels dated; every modern rice picker shows thumbnails | LOW-MED | Both Omarchy and HyDE pickers show visual/thumbnail previews, not text lists. |

### Differentiators (Competitive Advantage)

Not required, but where a rice earns "wow" reactions and matches Omarchy/HyDE's actual polish ceiling.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Omarchy-style Super-key hierarchical menu with custom icons | Turns the launcher into a full command center (apps, style, setup, install, system) instead of "just app search" — this is Omarchy's single most recognizable UX signature | MED-HIGH | Omarchy implements this as ONE bash dispatcher script (`omarchy-menu`, ~636 lines) driving Walker in **dmenu mode** at a fixed width (295px) for a consistent sidebar look, not Walker's normal fuzzy-search UI. Icons are resolved by **name** (matched against the active GTK icon theme via a tool like `nwg-icon-picker`), not raw image files — this is the concrete, load-bearing implementation detail: custom menu icons are icon-theme lookups, so they re-theme for free when the icon theme changes. **Important divergence to flag for planning:** Omarchy binds this to `Super+Alt+Space`, not bare `Super` — bare `Super` is Hyprland's default modifier for window-management binds (move/resize/workspace-switch), so binding the menu to bare `Super`-tap (distinct from `Super`-hold-for-modifier) requires a tap-vs-hold keybind mechanism, which is a real implementation risk this repo's roadmap should size explicitly, not assume is trivial. |
| Theme-scoped wallpaper sets (static preset restricts to matching wallpapers; matugen allows any) | Prevents the "picked a nice static preset, then broke it by setting a clashing wallpaper" failure mode that plagues naive wallpaper-picker+static-theme combos; directly matches this project's own explicit requirement | MED | Omarchy and HyDE both implement this: wallpapers live in **per-theme directories** (HyDE: `~/.config/hyde/themes/<Theme-Name>/wallpapers/`), and the wallpaper picker only lists the active theme's set. Community Omarchy add-ons (e.g. `omarchy-aether-wallpapers`) go further with per-theme favorite/save/cycle/deactivate management via Walker menus. For matugen/dynamic mode, both rices treat wallpaper as unrestricted (any image → regenerate palette), matching this project's stated requirement exactly. |
| Vertical (left) waybar layout as a selectable variant | Distinct visual signature vs. the near-universal horizontal-top bar; several rices ship it as an alternate layout, not a replacement | MED | No rice was found with a turnkey "flip to vertical" toggle — it is standard practice to maintain vertical layout as a **second config file** (waybar supports multiple simultaneous bar instances via array-of-objects config, or a `-c`-selected alternate config) with CSS `writing-mode`/rotated-module adjustments, not a runtime CSS transform of the horizontal bar. Treat as "new config variant," not "new feature of the existing bar." |
| OLED-safe waybar behavior (auto-hide, dimming, pixel-shift) | Protects an OLED panel from burn-in from a bar that is visible ~100% of uptime at fixed pixel positions — a real hardware-protection feature, not cosmetic | MED-HIGH | No reference rice ships this as a packaged feature — it's a research gap across the whole ecosystem, not just this project. Closest existing primitive: `hyproled`, a standalone Hyprland shader tool that can target a defined screen region (documented example targets the bar's rectangle) and disables/dims alternating pixels, plus a cron-driven periodic pixel-shift. Realistic v2.0 scope is smaller than "full pixel-shift": auto-hide-on-idle/unfocused + avoiding static full-brightness/white bar segments is the pragmatic, low-complexity version; true pixel-shift is a stretch goal. **Flag for PITFALLS/roadmap: this needs its own focused research spike before planning, not just this survey.** |
| Rich now-playing widget (album art, popover/expanded panel, scrub bar) | Goes beyond waybar's inline-text mpris module toward the "mobile OS" media UX users see in end-4/Caelestia screenshots | MED-HIGH | This is exactly the reason end-4 and Caelestia **abandoned waybar** for Quickshell — a click-to-expand popover with album art is hard to do well inside waybar's `custom` module model (JSON `{text,tooltip,class}` output, not arbitrary widget trees). Realistic waybar-compatible version: a `custom` module scripted against `playerctl metadata`/`play-pause`/`next`/`previous` with `on-click`/`on-scroll` actions, format string showing artist–title (optionally scrolling text via a marquee helper script), NOT a full popover — that requires either a GTK popover companion process or accepting waybar's inline-text ceiling. Recommend scoping to "inline `custom` mpris module with icons + scroll actions," explicitly deferring popover/album-art as future/Quickshell-only territory, consistent with this project's existing "no framework rewrite" constraint. |
| AI dashboard as launchers + dedicated workspace (not embedded assistant UI) | Matches the project's explicit scope choice (Out of Scope: "Custom AI assistant widgets/sidebars") while still giving a cohesive "AI space" | LOW-MED | end-4's approach (AI chat sidebar built into the shell) is explicitly the pattern this project is **choosing not to build**. The lighter-weight, waybar-compatible equivalent already matches what Omarchy-style menus do elsewhere: a Walker submenu of AI-tool launch commands bound to auto-move-to a dedicated Hyprland workspace on launch (`windowrulev2 workspace` + `exec` wrapper script) — this is a config/scripting task, not a UI-build task, and is the only approach consistent with the stack's "no custom AI UI" constraint. |
| Game center menu (Steam/Gamescope launch shortcuts, not a full gaming-mode DE switch) | Matches modern-rice trend (Omarchy ships Steam-Deck-style gaming-mode tooling) without the complexity of a full mode-switch | MED | Omarchy's own ecosystem has multiple **third-party add-ons** for this (not core Omarchy), e.g. a Steam+Gamescope+MangoHud+GameMode installer/launcher wired into Hyprland keybinds with a TUI to pick resolution/overlay before launch. Recommend treating "Game center" as a Walker submenu of launch commands (Steam, Gamescope big-picture, per-game shortcuts) rather than attempting a full display-mode/session switch — that's a different, much larger feature (compositor-level Gamescope session swap) that is out of proportion to "menu item." |
| Settings menu (GUI-editable waybar/theme config) | ML4W's core differentiator — makes config changes discoverable without hand-editing JSON/CSS | MED-HIGH | ML4W ships a dedicated GTK4 app for this; building an equivalent from scratch is a meaningfully larger scope item than the other menu entries. Realistic v2.0 scope: a Walker submenu of **shortcuts to open specific config files/directories** in the user's editor (matches Omarchy's own "Setup" menu pattern — it also just opens `hyprland.lua`/waybar/walker configs for direct editing, it is NOT a GUI settings app either), not a bespoke settings GUI. Recommend explicitly scoping down from ML4W's GUI-app pattern to Omarchy's "quick-open config files" pattern to stay proportionate. |
| Keybind cheat-sheet menu item | Cheap, high-value discoverability feature; several rices auto-generate this from live compositor state rather than hand-maintaining a doc | LOW-MED | Omarchy's `omarchy-menu-keybindings` dynamically queries `hyprctl binds` rather than maintaining a static list — this is the correct pattern to copy: auto-generated from the live Hyprland config, so it can never drift out of sync with actual keybinds (a real risk with a hand-written cheat sheet). |
| Zen browser follows theme switches | Extends the "one switch re-themes everything" core value to a major non-native-toolkit app — meaningfully raises the "everything matches" bar | MED | Zen is Firefox-based; theming is via `userChrome.css` and requires `toolkit.legacyUserProfileCustomizations.stylesheets = true` in `about:config` (one-time, per-profile manual toggle — cannot be scripted around, `install.sh` should just document/prompt for it). Community precedent (DankMaterialShell's matugen integration) confirms the standard pattern: generate a matugen-templated CSS file (using matugen's color-key output, same as this project's other templates) and symlink/copy it to the profile's `chrome/userChrome.css`. **Critical constraint confirmed by two independent sources: there is no hot-reload for `userChrome.css` in Zen (or Firefox) — the browser must be fully restarted to pick up new theme colors**, same restart-required category as this project's existing GTK3 apps, not a live-CSS-reload app like GTK4/waybar. Plan the reload fan-out accordingly (kill+relaunch, not SIGUSR-style signal). |

### Anti-Features (Commonly Requested, Often Problematic)

Features that sound good but would create disproportionate complexity or break this project's existing constraints.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| Replacing waybar/rofi/wlogout with a Quickshell/QML shell (end-4/Caelestia style) | Their screenshots/demos are the most visually impressive results in the ecosystem right now | Total architecture rewrite: bar+sidebar+lock+OSD become one QML/C++ process instead of independently themed apps; directly contradicts this project's explicit constraint ("fixes and extends the existing setup, not a rewrite") and would invalidate the entire v1.0 theme-engine investment (10 surfaces already wired through one matugen pipeline) | Keep waybar+swaync+wlogout+walker; borrow specific UX ideas (animation quality, media popover concept) as inspiration for waybar `custom` modules, not as a reason to swap frameworks |
| Full custom GTK settings GUI app (ML4W Settings App equivalent) | "Settings menu" item in the requirements sounds like it implies a settings app | Building and maintaining a bespoke GTK4 app is a multi-week scope item on its own, orthogonal to "add a Walker menu item," and creates a second theming surface (a whole new app) to keep in sync with the existing pipeline | Walker submenu of "open this config file" shortcuts (Omarchy's actual "Setup" menu pattern) — zero new theming surface, near-zero new maintenance |
| Full Steam-Deck-style gaming-mode session switch (Gamescope compositor swap) | Omarchy's ecosystem has flashy "gaming mode" demos | This is a compositor-session-level feature (swapping to a Gamescope session and back), an order of magnitude more complex than a menu entry, with its own failure modes (session switch hangs, GPU driver quirks) unrelated to this milestone's theming/UX goals | Game center as a Walker submenu of launch shortcuts (Steam, per-game commands) — no session switching |
| True embedded AI assistant sidebar/chat UI | end-4's AiChat sidebar is a visible differentiator in that ecosystem | Explicitly out of scope per this project's own PROJECT.md ("Custom AI assistant widgets/sidebars" — Out of Scope); would also require choosing/maintaining an LLM-backend integration unrelated to desktop theming | Launchers-only AI dashboard: Walker submenu of external AI tool launch commands + auto-move to a dedicated workspace |
| Full pixel-shift OLED anti-burn-in (continuous sub-pixel image movement) | It's the "correct" TV/monitor engineering answer to burn-in | No existing Hyprland/waybar tool does this cleanly for a status bar (found only a shader-based partial primitive, `hyproled`, not a turnkey solution); attempting to build true continuous pixel-shift for a waybar overlay is a disproportionate research+engineering spike relative to the milestone's other items | Auto-hide-on-idle/unfocused + avoiding static full-brightness/white segments in the bar CSS — captures most of the real-world risk reduction at a fraction of the complexity; treat true pixel-shift as a separate future spike if still wanted |
| Native animated GIF screen recording | "Smooth animations/feedback" in the requirement reads as if GIF should be a first-class recording *mode* | No rice records directly to GIF — recording is always to video (`wf-recorder` → mp4/webm) with GIF as a separate `ffmpeg` conversion pass; building a "record straight to GIF" mode duplicates work for a strictly worse format (larger files, no audio) | Video recording via `wf-recorder`, with an optional post-hoc "convert last recording to GIF" script action, not a distinct capture mode |
| Re-theme on every wallpaper auto-cycle | Feels like the "obviously right" behavior if wallpapers are already theme-scoped and cycling | Already explicitly rejected in this project's own PROJECT.md Out of Scope ("latency/flicker cost; re-theme only on explicit user action") — restating here because the new theme-aware wallpaper picker/cycling feature makes this temptation more likely to resurface during implementation | Wallpaper cycling changes the background image only; palette regeneration stays a deliberate, explicit user action (theme-apply / picker "apply" step) |

## Feature Dependencies

```
Icon theme picker (browse/install/apply)
    └──requires──> GSettings icon-theme mechanism (already correct in this repo per CLAUDE.md)
    └──enhances──> Super-menu custom icons (icon-name lookups resolve against whichever icon theme is active)

Theme-scoped wallpaper picker
    └──requires──> Per-theme wallpaper directory convention (new: wallpapers/<theme-name>/ or equivalent registry)
    └──requires──> Existing static-preset + matugen dual-mode pipeline (already exists — v1.0)
    └──conflicts-with──> "re-theme on every cycle" anti-feature (cycling must NOT trigger theme-apply)

Super-key walker menu (Utilities/AI/Game/Power/Settings/Keybinds)
    └──requires──> Walker dmenu-mode scripting pattern (new script layer, not new Walker config)
    └──requires──> Icon-name-based custom icons ──requires──> Icon theme picker (so icons re-theme when icon theme changes)
    └──requires──> Keybind tap-vs-hold handling if bound to bare $SUPER (new Hyprland binding mechanism, not assumed-trivial)
    └──contains──> Keybind cheat-sheet ──requires──> live `hyprctl binds` query (no static doc to maintain)
    └──contains──> Power menu entry ──requires──> wlogout hang fix (broken power action inside a new polished menu is worse than the old bug alone)
    └──contains──> Settings menu entry ──requires──> config-file-shortcut convention (which files are "the" editable configs) — should reuse existing theme-engine's config locations

wlogout redesign
    └──requires──> wlogout hang bug fix first (redesigning a broken shutdown path just re-skins the bug)
    └──enhances──> Power menu entry inside Super-key menu

Hyprlock redesign
    └──requires──> Hyprlock first-keystroke bug fix first (same "don't skin a broken flow" logic as wlogout)
    └──requires──> Existing theme-engine pipeline (new hyprlock.conf becomes a new render target, same 10-surface pattern already proven)

SwayOSD themed indicators
    └──requires──> Existing theme-engine pipeline (new matugen template target, same pattern as existing 10 surfaces)
    └──independent-of──> everything else (low-risk, additive, no shared state with other v2.0 items)

Waybar media center (mpris)
    └──requires──> playerctl (already installed per STACK.md)
    └──enhances──> Waybar vertical-layout variant (must design mpris module to work in both orientations)
    └──conflicts-with──> full popover/album-art UX (that requires abandoning waybar's custom-module JSON-output model — explicitly deferred, see Anti-Features)

Waybar OLED-safe behavior
    └──independent-of──> vertical-layout variant, but should be designed to apply to BOTH layouts, not just the default horizontal one
    └──flagged for a dedicated research spike (see Anti-Features + Differentiators notes) before phase planning

Zen browser theming
    └──requires──> Existing matugen template pipeline (new render target using existing color keys)
    └──requires──> One-time manual `about:config` toggle (cannot be scripted transparently — document as a documented `install.sh` step, not silent automation)
    └──conflicts-with──> assuming live reload — reload fan-out must kill+relaunch Zen, not signal it

More static presets incl. light themes
    └──requires──> Existing static-preset pipeline (already exists — v1.0, no new mechanism)
    └──enhances──> Theme-scoped wallpaper picker (more presets = more per-theme wallpaper sets to curate)
```

### Dependency Notes

- **Both bug fixes (wlogout hang, hyprlock keystroke drop) must land before their respective redesigns.** This isn't just sequencing hygiene — the wlogout hang is specifically reported as an **input-event/focus-handoff bug triggered by mouse click** (keyboard-triggered logout already works), and the hyprlock issue is a **compositor-focus-acquisition timing gap**. Both are root-cause, not cosmetic, so a visual redesign done first would need to be redone/re-tested once the underlying input-handling fix lands (differently sized click targets, different focus-grab timing).
- **Icon theme picker enhances the Super-menu, and both should land in a coherent order** (icon picker first, or at minimum designed together): Omarchy's confirmed pattern is that custom menu icons are icon-theme **name lookups**, not bundled image files — if the icon theme picker isn't in place first, the Super-menu's custom icons have nothing correct to resolve against and may need rework once icon theming exists.
- **Settings menu entry should reuse the existing theme-engine's known config locations** rather than inventing a new "what counts as a setting" taxonomy — Omarchy's own "Setup" menu is just fast-access to edit known config files, which is directly compatible with this project's existing `theme-engine/` file layout.
- **Waybar OLED-safe behavior and vertical-layout variant are independent but should not be designed in isolation** — an OLED mitigation (auto-hide, dim) implemented only against the default horizontal config would silently not apply once a user switches to the vertical variant, defeating the point of a hardware-protection feature.
- **Zen browser theming's restart-required nature places it in the same reload-fan-out category as this project's existing GTK3 apps** (Thunar) — the existing `theme-apply` reload fan-out already has a "kill and relaunch" pattern for exactly this class of app (per CLAUDE.md: "GTK3 has no live CSS reload API"); Zen should be wired into that same pattern, not treated as a new reload mechanism.

## MVP Definition

### Launch With (v1 of this milestone)

The items with the clearest 1:1 mapping to this project's core value ("one switch re-themes everything, reproducible from scratch") and the lowest architectural risk:

- [ ] wlogout hang fix — root-cause bug, currently breaks a table-stakes surface
- [ ] Hyprlock keystroke-drop fix — root-cause bug, currently breaks a table-stakes surface
- [ ] Kitty startup speed fix — isolated, low-risk, high daily-friction payoff
- [ ] wlogout redesign (post-fix) — table stakes for "modern rice" appearance
- [ ] Hyprlock redesign (post-fix), themed via existing pipeline — table stakes
- [ ] Screenshot suite (grim+slurp+satty capture/annotate, wf-recorder for video) — table stakes, low complexity, well-trodden pattern
- [ ] Clipboard history (cliphist + Walker dmenu) — table stakes, low complexity, reuses existing Walker/elephant infrastructure
- [ ] Emoji picker (Walker dmenu) — table stakes, trivial
- [ ] SwayOSD themed indicators — table stakes, additive, no dependencies on anything else in this milestone
- [ ] Waybar notification-center button (swaync-client -t) — table stakes, trivial
- [ ] Waybar built-in mpris now-playing module (inline, not popover) — table stakes, low complexity, matches STACK.md recommendation
- [ ] Icon theme picker (apply via GSettings) + at least Papirus bundled — table stakes for visual coherence, blocks Super-menu custom icons

### Add After Validation (v1.x within this milestone)

Higher-complexity/higher-risk items that depend on the above landing cleanly first:

- [ ] Super-key walker menu (Utilities, keybind cheat-sheet, settings-as-config-shortcuts first — these are low-risk submenus)
- [ ] Super-key menu: AI dashboard submenu (launchers + workspace) and Game center submenu (launch shortcuts) — same menu mechanism, just more entries, but worth sequencing after the menu framework itself is proven
- [ ] Color picker script (hyprpicker-based, clipboard output)
- [ ] More static presets incl. light themes — content work, low engineering risk, can land incrementally
- [ ] Theme-aware wallpaper picker (per-theme directories/registry, thumbnail preview, static-restricts / matugen-unrestricted split)
- [ ] Zen browser theming (matugen template + restart-based reload fan-out + documented one-time about:config toggle)
- [ ] Waybar vertical (left) layout variant

### Future Consideration (beyond this milestone, or explicit stretch)

- [ ] Icon theme **browser/installer** (not just picker) — discovering and installing new icon themes (beyond bundling Papirus/Tela) is a bigger scope than "apply the active one"; land the picker first, revisit install/browse UX once real usage patterns are known
- [ ] Nerd-font switcher across apps — no existing rice has a reference implementation; this is genuinely novel scope (enumerate installed Nerd Fonts, rewrite font references across kitty/vscodium/GTK/waybar configs, trigger appropriate reloads per-app) and deserves its own focused design pass rather than folding into this survey's assumptions
- [ ] True OLED pixel-shift (beyond auto-hide/dim) — flagged above as needing a dedicated research spike; no turnkey solution exists in the ecosystem today
- [ ] Rich mpris popover/album-art media widget — requires either a GTK companion process or abandoning waybar's JSON-output custom-module model; explicitly deferred as disproportionate to this milestone's "extend, don't rewrite" constraint
- [ ] Full gaming-mode session switch (Gamescope) — explicitly out of proportion to "Game center menu item," see Anti-Features

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| wlogout hang fix | HIGH | MEDIUM | P1 |
| Hyprlock keystroke-drop fix | HIGH | MEDIUM | P1 |
| Kitty startup speedup | MEDIUM | LOW | P1 |
| wlogout redesign | HIGH | LOW-MEDIUM | P1 |
| Hyprlock redesign | HIGH | LOW-MEDIUM | P1 |
| Screenshot suite (capture/annotate/record) | HIGH | MEDIUM | P1 |
| Clipboard history | HIGH | LOW | P1 |
| Emoji picker | MEDIUM | LOW | P1 |
| SwayOSD themed indicators | MEDIUM | LOW | P1 |
| Notification-center bar button | MEDIUM | LOW | P1 |
| Waybar mpris now-playing (inline) | HIGH | LOW | P1 |
| Icon theme picker (apply) | HIGH | LOW-MEDIUM | P1 |
| Super-key menu (core: Utilities, keybinds, settings-shortcuts) | HIGH | MEDIUM-HIGH | P2 |
| Super-key menu: AI dashboard + Game center submenus | MEDIUM | MEDIUM | P2 |
| Color picker | MEDIUM | LOW | P2 |
| More static presets + light themes | MEDIUM | LOW | P2 |
| Theme-aware wallpaper picker | HIGH | MEDIUM | P2 |
| Zen browser theming | MEDIUM | MEDIUM | P2 |
| Waybar vertical layout variant | MEDIUM | MEDIUM | P2 |
| OLED-safe waybar behavior (auto-hide/dim only) | MEDIUM | MEDIUM | P2 |
| Icon theme browser/installer | LOW-MEDIUM | HIGH | P3 |
| Nerd-font switcher | LOW-MEDIUM | HIGH | P3 |
| True pixel-shift OLED mitigation | LOW | HIGH | P3 |
| Rich mpris popover/album-art | LOW-MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Bug fixes + table-stakes utilities with low/well-understood implementation cost — lowest-risk phase content
- P2: Differentiators that depend on P1 groundwork or carry real design/scope risk worth sizing carefully
- P3: Explicitly deferred — either no reference implementation exists in the researched ecosystem, or scope is disproportionate to this milestone

## Competitor Feature Analysis

| Feature | Omarchy | HyDE | end-4/Caelestia | ML4W | This Project's Approach |
|---------|---------|------|------------------|------|--------------------------|
| Super-key menu | Bash dispatcher + Walker dmenu, Super+Alt+Space, icon-name custom icons | Rofi-based, similar hierarchical pattern | N/A (full custom Quickshell shell instead) | N/A (traditional launcher, GUI settings app instead) | Follow Omarchy's script+Walker-dmenu+icon-name pattern (architecturally closest to existing stack); size the bare-$SUPER-tap keybind risk explicitly |
| Wallpaper/theme scoping | Per-theme wallpaper dirs, Manage/cycle/deactivate via Walker | Per-theme wallpaper dirs, Rofi Theme Patcher | Wallpaper-driven Material You dynamic only (no static preset restriction concept found) | Waybar theme templates, not full-desktop wallpaper scoping | Adopt Omarchy/HyDE's per-theme-directory convention directly — matches this project's explicit static-restricts/matugen-unrestricted requirement |
| Power menu / lock screen | wlogout (layer-shell overlay, theme-driven CSS) + themed hyprlock as first-class surface | Similar wlogout+hyprlock pairing | Custom QML lock/session modules (not portable) | Standard wlogout/hyprlock, GUI settings for waybar only | Keep wlogout+hyprlock; fix root-cause input bugs before redesign; theme via existing pipeline |
| Media widget | Waybar built-in mpris module, icon/click-action enhancements only | Not deeply documented; assume similar waybar mpris pattern | Custom QML popover/dashboard media widget (mobile-OS-like) | Not a focus area | Waybar built-in mpris module for v1 of this milestone; defer popover/album-art as P3 |
| Settings access | "Setup" menu = quick-open known config files (not a GUI app) | Similar config-file-shortcut pattern via menu | N/A (shell reconfigured via QML/JSON directly) | Dedicated GTK4 Settings App (GUI editing) | Follow Omarchy's lighter pattern (config-shortcut menu), not ML4W's GUI-app pattern — proportionate to scope |
| OSD (volume/brightness) | SwayOSD, themed CSS | Not deeply documented; SwayOSD or equivalent assumed | Custom QML OSD module | Not a focus area | SwayOSD, plain-CSS themed via existing matugen template pattern (already this project's STACK.md choice) |

## Sources

- websearch: "Omarchy Super key menu walker implementation custom icons structure" — confidence LOW
- websearch: "Omarchy wallpaper picker theme-aware wallpapers implementation walker" — confidence LOW
- websearch: "Omarchy wlogout power menu design and hyprlock configuration" — confidence LOW
- websearch: "Hyprland rice screenshot utility suite grim slurp satty swappy hyprshot annotate record wf-recorder" — confidence LOW
- websearch: "Hyprland waybar OLED burn-in mitigation pixel shift auto-hide vertical bar layout" — confidence LOW
- websearch: "Hyprland waybar media center mpris now playing widget design Omarchy end-4 HyDE Caelestia ML4W" — confidence LOW
- websearch: "Hyprland emoji picker color picker clipboard history cliphist rofi walker script" — confidence LOW
- websearch: "Hyprland icon theme picker nerd font switcher rice script" — confidence LOW
- websearch: "end-4 dots-hyprland ai sidebar game mode launcher menu design quickshell" — confidence LOW
- websearch: "HyDE dotfiles wallpaper picker theme switching design rofi" — confidence LOW
- websearch: "Caelestia dotfiles Hyprland quickshell design features" — confidence LOW
- websearch: "ML4W dotfiles Hyprland settings app features waybar" — confidence LOW
- websearch: "SwayOSD themed volume brightness indicator setup Hyprland rice CSS" — confidence LOW
- websearch: "hyprlock first keystroke dropped ignored fix grace period" — confidence LOW
- websearch: "wlogout shutdown hang blank screen stuck fix systemd" — confidence LOW
- websearch: "wlogout hyprland shutdown command hangs screen frozen after selecting poweroff" — confidence LOW
- websearch: "Omarchy game mode game center launcher menu design" — confidence LOW
- websearch: "Omarchy screenshot capture tool satty annotate OCR share flow omarchy-cmd-screenshot" — confidence LOW
- websearch: "Omarchy icon theme picker nwg-icon-picker install browse icons" — confidence LOW
- websearch: "icon theme switcher GTK papirus tela install AUR icon pack picker script Linux" — confidence LOW
- websearch: "Zen browser theme sync GTK theme userChrome.css matugen colors" — confidence LOW
- websearch: "matugen zen-browser template userChrome.css material you generate" — confidence LOW
- websearch: "GTK4 vertical waybar left layout module rotation Hyprland config" — confidence LOW
- webfetch: deepwiki.com/basecamp/omarchy/3.1-omarchy-menu-system (Omarchy Super-key menu system detail) — confidence LOW
- webfetch: github.com/hyprwm/hyprshutdown (graceful shutdown utility purpose/mechanism) — confidence LOW

---
*Feature research for: Hyprland desktop rice utilities/menus (v2.0 Desktop Expansion)*
*Researched: 2026-07-09*
