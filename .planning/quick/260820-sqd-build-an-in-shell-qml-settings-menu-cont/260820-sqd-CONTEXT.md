# Quick Task 260820-sqd: Build an in-shell QML settings menu (control-panel-style, like end-4/Caelestia) for machine and system options - Context

**Gathered:** 2026-08-20
**Status:** Ready for planning

<domain>
## Task Boundary

Build an in-shell QML settings surface — a control panel in the spirit of
end-4's `ContentPage`/`ConfigSlider`/`ConfigSwitch` family and Caelestia's
settings window — for adjusting machine and system options.

**Scope reversal, recorded:** this deliberately reverses the "no full GUI
settings app — the settings menu launches existing tools" Out of Scope entry
in `.planning/PROJECT.md` (carried from v2.0, reaffirmed in
`.planning/research/FEATURES.md:170` as an anti-feature). The operator
directed the reversal on 2026-08-20. PROJECT.md's Out of Scope entry must be
updated as part of this task, the same way the QML-rewrite reversal was
recorded — as a deliberate decision with a date, not silent drift.

</domain>

<decisions>
## Implementation Decisions

### V1 scope — all four option groups
- **Appearance**: theme, wallpaper, icon theme, font, bar orientation — all
  five already have working scripts/pickers to drive.
- **Audio + connectivity**: audio mixer, wifi, bluetooth — wire in the three
  existing in-shell QML panels.
- **Display + input**: monitor resolution/refresh/scale and keyboard/mouse
  options via hyprctl/Hyprland Lua — the new territory.
- **Shell behaviour**: motion preset (normal/reduced/off), notification DND,
  idle/lock timing, OSD knobs the shell and scripts already own.

### Shape — standalone settings window
- Caelestia-style centered floating window on the shell: left nav rail, one
  content page per group. Not a dashboard tab, not a PanelDialog accordion.
- Operator chose this from rendered previews.
- **Operator confirmed 2026-08-20 (post-research): use `FloatingWindow`**, per
  the research recommendation — it dodges the layer-surface never-resize rule,
  layerrule/blur ordering, and bar-surface registration. Still subject to the
  Task-1 viability probe since it has never been instantiated in this repo
  (research assumption A3); if the probe falsifies it, fall back to
  `PanelWindow` and surface the change to the operator.

### Persistence — state-dir + scripts convention
- Every knob routes through the pipeline's existing convention: scripts own
  the write (theme-apply, motion-switch, …), state lives in
  `~/.local/state`, repo holds defaults. Git tree stays clean; no fighting
  theme-doctor's clean-tree invariant.
- Consequence for Display + input: persistence needs a state-dir mechanism
  (e.g. an overrides file the Hyprland Lua config sources), NOT edits to the
  stowed Lua config files.

### Reuse — mixed embed + launch
- QML-native controls (dropdowns, toggles, sliders) live directly in the
  settings pages.
- The kitty-graphics pickers (wallpaper, font — anything needing image
  previews) and the existing audio/wifi/bluetooth panels are summoned from
  entries. Nothing that already works gets rebuilt.

### Claude's Discretion
- Entry points (suggested: a keybind plus an entry in the walker Settings
  submenu; the submenu itself stays for muscle memory).
- Fate of the walker settings submenu (suggested: keep, add the window as
  its top entry rather than deleting the existing rows).
- Exact page layout, control styling (must go through `Colours.qml` /
  `Motion.qml` — colour-lint rejects hardcoded colors), nav-rail behaviour.
- How Display + input writes reach Hyprland (hyprctl live + state-dir
  persistence design).

</decisions>

<specifics>
## Specific Ideas

- Reference language is Caelestia first (standing project rule), end-4's
  settings component family second; both were source-verified in
  `.planning/research/FEATURES.md`.
- The existing walker settings submenu
  (`elephant/.config/elephant/menus/settings.toml`) enumerates today's
  settings reach: Theme, Wallpaper, Icon theme, Font, Bar orientation,
  Network, Bluetooth, Audio, Display (nwg-displays).
- Existing in-shell panels to reuse: audio mixer, wifi picker, bluetooth
  manager (PanelDialog family, `quickshell/.config/quickshell/`).
- New QML surfaces belong under `quickshell/.config/quickshell/modules/`,
  colored through `Colours.qml`, animated through `Motion.qml` (project
  stack rule; GATE-04 colour-lint enforces it).

</specifics>

<canonical_refs>
## Canonical References

- `.planning/PROJECT.md` — Out of Scope entry to be reversed and re-recorded
- `.planning/research/FEATURES.md` — source-verified reference-shell feature map
- `elephant/.config/elephant/menus/settings.toml` — current settings menu
- `.claude/CLAUDE.md` — stack patterns (QML capsule rules, colour-lint)

</canonical_refs>
