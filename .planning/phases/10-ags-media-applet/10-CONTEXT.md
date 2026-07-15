# Phase 10: AGS Media Applet — Context

> This phase has an ALREADY-APPROVED spec and implementation plan. The planner should build the GSD PLAN(s) from these locked decisions — do NOT re-open settled choices.
>
> - **Approved spec:** `docs/superpowers/specs/2026-07-15-ags-media-applet-design.md`
> - **Approved implementation plan (6 dependency-ordered tasks):** `docs/superpowers/plans/2026-07-15-ags-media-applet.md`
> - **Root-cause debug that drove this phase:** `.planning/debug/resolved/eww-media-popup-clicks-dead.md`

## Why this phase exists

The Phase 08 eww media popup renders correctly but **no interactive widget receives pointer clicks** on this machine (eww 0.6.0 Wayland build, Hyprland 0.55.4). Confirmed toolkit-level, not config: tested overlay/fg stacking, `button` vs `eventbox`, and `:wm-ignore false` (a no-op on Wayland). waybar and AGS/HyprPanel (both GTK-layer-shell) get clicks here; eww specifically does not. Replace it with AGS.

## Locked decisions (from the approved spec)

| Decision | Choice |
|----------|--------|
| Toolkit | AGS v3 (`aylurs-gtk-shell` 3.1.2, AUR) — GTK4, TypeScript/JSX, `gjs` |
| Scope | Replace ONLY the eww media popup. Keep waybar, swaync, matugen. (Full HyprPanel bar takeover was explicitly REJECTED.) |
| Visual | garuda/HyprPanel look — blurred album-art background, overlaid controls, rounded pills; distinct from the athena bar |
| Cava | underlay — bars bleed around/behind a centered album-art thumbnail |
| Position | centered on screen; close on focus-loss / click-away + Esc; waybar segment toggles via `ags request toggle-media` |
| Backend | reuse `media-status.sh` / `media-players.sh` / `media-art-resolve.sh` UNCHANGED |
| Deps | install `aylurs-gtk-shell` (paru) + `cava` (extra); add both to `install.sh` |

## Verified AGS v3 API facts (from real working configs — TheWolfStreet/ags2-shell)

- `import app from "ags/gtk4/app"`; `app.start({ instanceName, css, main(), requestHandler(argv, res) })`.
- Window: `Astal.Window` with `name`, `namespace`, `keymode` (`Astal.Keymode.ON_DEMAND`), `anchor` (`Astal.WindowAnchor.TOP|BOTTOM|LEFT|RIGHT` = full-screen), `exclusivity` (`IGNORE`), `layer` (`Astal.Layer.TOP`).
- Click-away: `<Gtk.GestureClick onPressed>` → `card.compute_bounds(win)` → if click point not in rect → `win.hide()`.
- Esc: `<Gtk.EventControllerKey onKeyPressed>` → `Gdk.KEY_Escape` → `win.hide()`.
- CSS hot reload: `app.apply_css(style, true)` + `monitorFile()` from `ags/file` watching the matugen output.
- Toggle from waybar: `requestHandler` case `toggle-media` flips `app.get_window("media").visible`.
- Subprocess: `subprocess()` / `exec()` from `ags/process`. Reactive: pin exact primitive (`createState`/`createBinding`) against the installed 3.1.2 at scaffold time.

## Hard constraints for planning

- **No agent-side pointer injection exists.** Interaction verification (buttons click, sliders drag) MUST be user live-tests. The plan front-loads a fail-fast input-viability gate (a test button) right after scaffolding — if AGS also can't deliver clicks, STOP.
- Task 1 (deps) needs the user's sudo password in the terminal.
- `style.scss`: zero hex literals — every color `@import`ed from `~/.local/state/theme/ags.scss`.
- Window name `media`, namespace `ags-media`, request verbs `toggle-media` / `reload-css` — used consistently.
- Glyphs by codepoint only (PUA glyphs typed via the edit tool store as empty strings — recurring gotcha this project).
- Retirement: remove eww `media-popup`/`media-backdrop` + `media-popup-open/close.sh`; verify eww has no other consumer before dropping it from autostart.

## Suggested plan decomposition (already ordered in the approved plan)

1. Deps + install.sh
2. AGS scaffold + centered clickable window (**input-viability gate**)
3. Backend binding + transport/seek/volume/switcher
4. Garuda visual + cava underlay + blur layerrule
5. matugen template + CSS hot reload
6. Integration (waybar/autostart) + eww retirement + reproducibility
