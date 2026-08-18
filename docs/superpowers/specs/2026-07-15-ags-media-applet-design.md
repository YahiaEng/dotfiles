# AGS/astal Media Applet — Design Spec

> ## ⛔ HISTORICAL RECORD — NOT CURRENT GUIDANCE
>
> This spec was implemented and the result has since been **retired**. It is
> kept verbatim as the design record of what was decided in July 2026; every
> package it names below has been deleted from repo *and* host.
>
> `ags` — **RETIRE-06**, Phase 21 Plan 08 · `waybar` — **RETIRE-02**, Phase 18
> Plan 20 · `swaync` — **RETIRE-03**, Phase 19 Plan 08 · `eww` — **RETIRE-07**,
> Phase 20 Plan 10.
>
> The media UI now lives in the Quickshell dashboard's Media tab (QMEDIA-01..03),
> backed by `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml`.

**Date:** 2026-07-15
**Status:** Approved (design), pending implementation plan
**Supersedes:** the eww media popup (`media-popup` / `media-backdrop`), confirmed non-viable — see `.planning/debug/resolved/eww-media-popup-clicks-dead.md`.

## Problem

The eww media popup renders correctly but **no interactive widget ever receives pointer clicks** on this machine (eww 0.6.0 Wayland build, Hyprland 0.55.4). Confirmed toolkit-level, not a config bug: tested overlay/fg stacking, `button` vs `eventbox`, and `:wm-ignore false` (a no-op on Wayland — eww is layer-shell-only). waybar and HyprPanel (both GTK-layer-shell) get clicks fine here, so the compositor routes pointer to layer surfaces; eww specifically does not. There is no agent-side pointer-injection tool, so every fix required a user click-test — all failed.

## Goal

Replace **only** the eww media popup with a standalone AGS/astal media applet: a working, garuda/HyprPanel-styled, centered media card with transport controls, seek/volume, a player switcher, and a cava audio-visualizer underlay. Keep waybar, swaync, and the matugen theming pipeline intact. Stay reproducible via `install.sh` + stow.

## Locked Decisions

| Decision | Choice |
|----------|--------|
| Toolkit | AGS v3 (`aylurs-gtk-shell` 3.1.2, AUR) — TypeScript/JSX, `gjs` runtime |
| Visual style | garuda/HyprPanel look — blurred album-art background, overlaid controls, rounded pills; distinct from the athena bar |
| Cava | **underlay** — bars bleed around/behind a centered album-art thumbnail |
| Position | **centered** on screen |
| Dismiss | close on focus-loss / click-away (dimmed area outside the card) + `Esc`; waybar media segment toggles |
| Deps | install `aylurs-gtk-shell` (AUR, paru) + `cava` 0.10.7 (extra) now; add both to `install.sh` |
| Backend | reuse existing MPRIS scripts unchanged |

## Architecture

New stow package `ags/.config/ags/`:

- `app.ts` — AGS entry; defines the media window + toggle handler + CSS bootstrap.
- `widget/MediaCard.tsx` — the card UI (art background, cava underlay, meta, transport, sliders, switcher).
- `lib/media.ts` — subscribes to `media-status.sh watch` (JSON) and exposes reactive state; wraps `media-players.sh` calls.
- `lib/cava.ts` — spawns `cava` (raw stdout config) and exposes reactive bar-height array.
- `style.scss` — layout + garuda styling; `@import`s the matugen palette.
- `cava/config` — cava raw-output config (N bars, ascii/raw to stdout).

### Window & dismiss
One full-screen transparent AGS layer window (`namespace` e.g. `ags-media`), card centered. The dimmed region outside the card is a click target that closes the window; `Esc` closes; re-clicking the waybar segment toggles via `ags toggle media`. Single window — no separate backdrop-window trick (AGS delivers pointer to its widgets, so click-away is a normal handler).

### Visual (garuda underlay)
- Card ≈360px wide. **Background:** album art scaled to cover + translucent scrim for legibility. A Hyprland `blur` layerrule on the `ags-media` namespace frosts it (same trick swaync/eww used).
- **Cava bars** render as a layer *around* a smaller centered album-art thumbnail, bleeding past its edges, accent-colored.
- **Overlaid:** title/artist, circular transport (prev / play-pause / next), seek pill + volume pill, player switcher.
- If nothing is playing, the applet does not open (mirrors current D-25 behavior — waybar segment only opens when a player is active).

### Cava bridge
`cava` runs with a dedicated config: raw stdout, fixed bar count, ascii/normalized range. `lib/cava.ts` reads stdout lines and drives bar heights reactively. cava process is started/stopped with the window's visibility to avoid idle CPU.

### Backend reuse (unchanged)
- `~/.config/hypr/scripts/media-status.sh watch` → JSON → bound to UI.
- `media-players.sh cmd <player> <action>` for transport; `... select <id>` for the switcher; `... list` for players.
- `media-art-resolve.sh` for the art path.
- The `_valid_id`-validated command paths (08-07 threat model) carry over verbatim — no metadata ever reaches a command string.

### Theming (matugen)
- New template `matugen/.config/matugen/templates/ags-colors.scss` → `~/.local/state/theme/ags.scss` (named color vars).
- New `[templates.ags]` in `matugen/.config/matugen/config.toml` with a `post_hook` that tells the running AGS to re-apply CSS on theme switch.
- `style.scss` `@import`s `~/.local/state/theme/ags.scss` — same pattern as every other themed app. Zero hex literals in `style.scss`.

### Integration & retirement
- `waybar/.config/waybar/modules.jsonc` + `config-vertical.jsonc`: `custom/media` `on-click` → `ags toggle media`.
- `hypr/.config/hypr/config/autostart.conf`: start the AGS daemon; add the `ags-media` blur layerrule to `windowrules.conf`.
- Remove `media-popup` / `media-backdrop` from `eww/.config/eww/eww.yuck`; retire `media-popup-open.sh` / `media-popup-close.sh`. Verify eww is unused elsewhere before removing it from autostart (if the media popup was its only consumer, drop eww entirely).
- `install.sh`: add `aylurs-gtk-shell` to the AUR list and `cava` to the pacman list.

## Success Criteria

1. Clicking the waybar media segment opens a centered card; clicking outside / `Esc` / re-click closes it.
2. Prev / play-pause / next **respond to clicks**; seek + volume sliders drag and affect playback.
3. Player switcher lists and switches active MPRIS players.
4. cava bars animate behind/around the album art while audio plays.
5. A theme switch (static or matugen) re-colors the applet with no manual step.
6. `install.sh` on a fresh system installs both deps; `stow` links the `ags` package; the applet works after login.

## Out of Scope

- Replacing waybar or swaync (explicitly rejected — HyprPanel full-bar takeover was declined).
- Any change to the MPRIS backend scripts beyond what integration requires.
- Multi-monitor placement tuning beyond "centered on the focused monitor".

## Risks / Open Questions (for planning)

- AGS v3 CSS hot-reload mechanism on theme change — confirm the exact `ags`/`astal` request API for re-applying CSS without a full restart (fallback: restart the daemon in the post_hook).
- "Blurred art background": whether to rely on the Hyprland namespace blur layerrule alone or also pre-scale/darken the art in `media-art-resolve.sh`.
- Whether eww has any other consumer in this repo before full removal.
