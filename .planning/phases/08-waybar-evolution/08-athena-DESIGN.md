---
type: design-spec
phase: 08-waybar-evolution
topic: athena-waybar-layout
status: approved
created: 2026-07-15
source: brainstorming (user redirected 08-12 minimal → from-scratch redesign)
supersedes: the "minimal" layout (config-minimal.jsonc / style-minimal.css)
gap_closure: true
---

# Design Spec: the `athena` waybar layout

## Origin

At the 08-12 visual checkpoint the user approved the `full` translucent-island
redesign and locked it as the design-system contract for 08-13/08-14. The user then
directed that the `minimal` layout be **scrapped entirely and rebuilt from scratch**,
mimicking the Athena waybar (https://github.com/haikal-hakim/athena/tree/main/.config/waybar),
and **renamed from `minimal` to `athena`**.

This spec is the approved output of a brainstorming session. It replaces `minimal`.

## Approved decisions (locked)

1. **Colour follows each theme's colour-scheme, matugen-driven, always.** No hardcoded
   hex. No per-app brand colours. Every colour resolves from the palette through the
   `theme.css` alias layer. `waybar-design-lint` must stay green (CHECK B: role names
   only outside theme.css; CHECK D: no literal hex; CHECK C: transparent window).
2. **Athena's structure, your colour system.** Reproduce Athena's *layout* faithfully —
   discrete rounded capsules, live-window workspace icons, hover-expand drawers — but
   route all colour through the alias layer. Chroma reserved for state; active workspace
   is the sole accent at rest.
3. **Keep the app-launcher drawer, themed, wired to the user's apps** (not Athena's).
4. **Rename** `config-minimal.jsonc` → `config-athena.jsonc`,
   `style-minimal.css` → `style-athena.css`. The layout switcher (08-02) globs
   `config-*.jsonc`, so `athena` appears and `minimal` disappears with no switcher edits.

## System facts that shaped the design (verified 2026-07-15)

- **Palette is a curated 19-token subset.** `surface_container*` and `*_fixed_dim`
  tokens that Athena relies on DO NOT EXIST in this repo's matugen output.
  `surface` == `background` (identical hex); `surface_variant` is the only distinctly
  raised neutral. → Capsule surface = an alias built on `@surface_variant`.
- **Desktop, not laptop** (no `/sys/class/power_supply/BAT*`). → Drop Athena's battery.
- **power-profiles-daemon is inactive.** → Drop Athena's power-profiles module.
- **Present & usable:** bluetooth, swaync, nm-applet, blueman. → Athena's audio,
  connections, tray-arrow(swaync) modules all work.
- **Font:** FiraCode Nerd Font installed (not Athena's JetBrainsMono). Carries every
  required glyph. → Keep FiraCode.
- **Apps (from Hyprland keybinds), all launched `uwsm app --`:** kitty (terminal),
  codium (editor), zen-browser, thunar (files); also installed: obsidian, spotify,
  discord.

## Module layout

Top bar. Discrete capsules (each a raised neutral surface pill, radius consistent with
the phase's scale).

**Left**
- **App drawer** (`group/apps`, `drawer`, reveal-on-hover): collapsed = a launcher glyph;
  expanded, in order = zen-browser · spotify · discord · steam · lutris · obsidian · codium.
  Neutral glyphs, `@accent` on hover. Each `on-click` = `uwsm app -- <target>` (matching the
  session pipeline), targets confirmed present 2026-07-15:
  - zen-browser → `zen.desktop`
  - spotify → `spotify.desktop`
  - discord → `discord.desktop`
  - steam → `steam.desktop`
  - lutris → `net.lutris.Lutris.desktop`
  - obsidian → `obsidian.desktop`
  - codium → `codium.desktop`
  Glyphs must be cmap-verified against FiraCode Nerd Font per the 08-11 discipline
  (no empty/unrendered glyph fields). (No terminal/file-manager in the drawer — user's
  chosen set is browser + games/media + editor.)
- **Storage pill** (`group/storage`): disk + memory.
- **System pill** (`group/system`): temperature + cpu.

**Center**
- **Workspaces pill**: Athena's `{icon} {windows}` — live window app-icons per workspace
  via `window-rewrite` (port Athena's ~40-class map; add zen, codium, yazi; default glyph
  fallback). Active workspace = `@accent` fill. `on-click: activate`, 5 persistent.
- **idle_inhibitor**: activated/deactivated glyphs; state colour when active.

**Right**
- **Audio drawer** (`group/audio`, `drawer`): pulseaudio icon → volume slider + mic toggle.
- **Connections drawer** (`group/connections`, `drawer`): network + bluetooth.
- **Clock pill**.
- **Tray group** (`group/tray`, `drawer`): swaync bell (the `custom/notification` role,
  using Athena's `custom/tray-arrow` swaync-client wiring) + system tray + the two
  settings buttons folded in here: `custom/theme` (theme switcher) and
  `custom/waybar-layout` (layout switcher).
- **gaming-mode** indicator + **custom/power** (wlogout) at the right end.

**Dropped:** battery (desktop), power-profiles-daemon (inactive).
**Preserved from this repo:** custom/gaming-mode, custom/power, custom/theme,
custom/waybar-layout, swaync bell.

## Colour / theme.css additions

New semantic aliases (theme.css is the only file allowed to name raw tokens):
- `@capsule` — raised capsule surface, built on `@surface_variant` (translucent enough to
  sit in the house style, opaque enough to read as a raised pill).
- `@capsule-fg` — default capsule glyph/text colour (`@on_surface_variant`, the legible
  dimmed role fixed in 08-12 — NOT `@outline`).
- Reuse existing `@accent` / `@on-accent` (active workspace, hover), `@warn` / `@danger`
  (state), `@fg` / `@fg-dim` from the 08-11/08-12 alias layer.

State colours (idle-inhibitor active, cpu/mem/disk/temp warning+critical, network
disabled) map to the existing `@warn` / `@danger` aliases — Athena's `state.css` hex is
re-expressed, not copied.

## Composition & gates

- Same `include` (jsonc) + `@import` (css) composition as the rest of Phase 08.
- Module JSON lives in shared `modules.jsonc` where reusable; athena-specific group
  definitions (drawers, app launchers, window-rewrite) live in `config-athena.jsonc`
  redefinitions (whole-key first-defined-wins, per D-31).
- Must pass `waybar-design-lint` (all checks) and `theme-doctor` before the user sees it.
- Verified live under at least one dark and one light theme (subject to the light-preset
  wallpaper gap logged separately).

## Explicitly out of scope

- The empty light-preset wallpaper directories (logged as a separate todo).
- eww media popup / swaync fixes (logged as separate todos; deferred until after 08-15).
- Changes to full / floating / vertical layouts.

## Acceptance

User approves the athena bar **on sight**, under dark and light, with: capsules reading as
discrete raised pills; workspace window-icons live; app drawer revealing on hover and
launching the right apps; no hardcoded colour; every colour tracking the active theme.
