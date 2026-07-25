# Phase 6: Themed Surfaces & Utility Suite - Context

**Gathered:** 2026-07-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Redesign and pipeline-theme every remaining desktop surface — wlogout (WLOG-01), hyprlock (LOCK-01), SwayOSD (OSD-01), Zen browser (THM-05) — and ship the full everyday utility suite: screenshot capture/annotate/record with GIF export (SHOT-01/02/03), emoji picker, screen color picker, clipboard history with cap+wipe policy, icon-theme picker, and nerd-font switcher (UTIL-01..05). Every new themed surface follows the established render-into-`~/.local/state/theme/` + contract.json + theme-parity pattern, validated under both light and dark fixtures (Phase 5's parity gate). No walker menus (Phase 7 wraps these utilities); no waybar work (Phase 8 — including any recording indicator module).

</domain>

<decisions>
## Implementation Decisions

### Screenshot suite (SHOT-01/02/03)
- **D-01:** Capture backend is **hyprshot** (region/window/full via grim+slurp underneath, window geometry from hyprctl). Freeze-on-select enabled (`-z`) so moving content can be captured. The old bare `screenshot.sh` is replaced.
- **D-02:** Every capture pipes **straight into satty** (the annotator) — satty owns save+copy+notify. Satty is configured for instant-out: **Enter (or Ctrl+C) = copy to clipboard + save to ~/Pictures/Screenshots + exit**, so an unannotated shot costs one keypress. Default pre-selected tool: **arrow**.
- **D-03:** Recorder is **gpu-screen-recorder** (AUR) — NVENC hardware encode on the RTX 3070. wl-screenrec rejected (VAAPI encode broken on NVIDIA via libva-nvidia-driver); wf-recorder rejected (CPU-only encode on NVIDIA). Omarchy's current `omarchy-capture-screenrecording` script is the reference implementation (slurp region/monitor picker, SIGINT stop, ffmpeg post-process).
- **D-04:** GIF export is a **notification action**: the recording-saved notification offers Open / Export GIF; conversion is an ffmpeg palette-pass next to the .mp4.
- **D-05:** Keybinds move to the **Omarchy-style Print-key family**: Print = region, Shift+Print = window, Ctrl+Print = full, Alt+Print = record toggle. Super+X/Z are freed (reused by utilities, D-14).
- **D-06:** Record start opens a **pipeline-themed walker --dmenu audio picker** (silent / desktop audio / desktop+mic) before region select — reuse Phase 5's exit-code-130 cancel pattern. No audio is ever captured without explicit selection.
- **D-07:** Recording feedback is **notification on start + same-key toggle to stop**. No waybar indicator this phase (Phase 8 owns waybar).
- **D-08:** Save locations unchanged: screenshots → `~/Pictures/Screenshots`, recordings → `~/Videos`, timestamped filenames.

### wlogout redesign (WLOG-01)
- **D-09:** Layout: **minimal center bar** — compact horizontal row of icon buttons floating over the blurred/dimmed desktop, label on hover/focus. All **six actions kept** (lock, logout, suspend, hibernate, reboot, shutdown — Phase 4 already audited all against uwsm).
- **D-10:** Icons are **Nerd Font glyphs rendered as button text** — the SVG assets are deleted; colors come from the existing `wlogout.css` pipeline target. Sharp at any scale, light/dark for free, zero new render targets for icons.

### hyprlock redesign (LOCK-01)
- **D-11:** Direction: **info-rich lock screen** with ALL of: user avatar, now-playing (playerctl, hidden when nothing plays), battery + caps-lock indicators, failed-attempts counter (builds on Phase 4's check_text/fail_text work).
- **D-12:** Avatar is a **themed initial** — a styled circle rendering the user's initial in palette colors. No photo asset, no ~/.face dependency, fully reproducible.
- **D-13:** Background stays the **blurred current wallpaper** (`$image` from the pipeline), with blur/dim re-tuned for the busier layout.
- **D-14 (safety):** All hyprlock testing follows Phase 4's documented lockout-recovery procedure (second TTY logged in, `pkill hyprlock`) — a launch requirement, not a follow-up.

### Utility pickers (UTIL-01..05)
- **D-15:** Clipboard (UTIL-03): **cap ~100 entries + wipe on logout** (session-end hook) + a manual "wipe now" entry in the picker. Secrets never persist across sessions. Existing Super+C walker dmenu flow stays.
- **D-16:** Icon themes bundled (UTIL-04): **Papirus + Tela + Colloid** (papirus-icon-theme official repo; tela/colloid AUR), Adwaita remains as fallback choice.
- **D-17:** **Folder accent colors track the theme**: when Papirus is active, theme-apply runs `papirus-folders` toward the palette's primary hue; Tela/Colloid use nearest fixed variant.
- **D-18:** Nerd fonts bundled (UTIL-05): **rice classics 5-pack** — JetBrains Mono, CaskaydiaCove, Hack, Iosevka, Meslo (all official-repo ttf-*-nerd) alongside existing FiraCode/FiraMono. Picker enumerates installed ttf-*-nerd dynamically.
- **D-19:** Font choice is an **independent axis** from theme: its own state file (like per-theme last-wallpaper pattern), survives theme switches; templates reference the font variable and theme-apply re-renders with the current font.
- **D-20:** Icon-theme picker and font switcher use **fzf-in-floating-kitty with rich previews** (wallpaper-picker pattern, NOT walker dmenu): font picker shows a live rendered specimen (pangram + code sample + nerd glyphs via kitty graphics); icon picker shows a small icon grid (kitten icat).
- **D-21:** Emoji (UTIL-01): walker + elephant-symbols (locked by requirement); selection is **typed directly into the focused app** (wtype/ydotool) AND copied to clipboard as backup.
- **D-22:** Color picker (UTIL-02): hyprpicker → hex copied, with a **notification showing the hex value + color swatch**.

### SwayOSD (OSD-01)
- **D-23:** Trigger wiring: **Hyprland media-key binds calling swayosd-client + the libinput backend service** (systemd user unit, enabled via install.sh) so caps-lock OSD works without a keybind. Mute AND mic-mute keys both route through swayosd-client.
- **D-24:** Look: **bottom-center rounded pill** with icon + progress bar, themed via a new matugen template + contract.json entry.
- **D-25:** Brightness scope (desktop, no backlight): volume + caps-lock are the deliverable; researcher evaluates a **ddcutil → swayosd custom-progress wrapper** for monitor DDC brightness — include if straightforward, **descope with evidence if flaky** (DDC is monitor-dependent).

### Zen browser (THM-05)
- **D-26:** Profile chicken-and-egg (confirmed live: zen-browser-bin installed, `~/.zen` absent): **lazy self-heal** — theme-apply resolves the default profile from `~/.zen/profiles.ini` on each run, skips gracefully (logged, non-fatal) when absent, and auto-wires the userChrome symlink the first time a profile appears. Container gate stays green with no browser involved.
- **D-27:** Theming depth: **chrome colors only** — toolbar, tabs, sidebar, URL bar from the palette; no new-tab page or deep element styling (update-resilient, minimal selectors).
- **D-28:** Restart policy: **notify only** — render the CSS; if Zen is running, notify "Restart Zen to apply theme". Never kill the browser. Matches the accepted GTK3 stale-until-closed posture.
- **D-29:** theme-parity validates the **rendered state-dir CSS only**; profile symlinking is the reload step's job, skipped gracefully headless.

### Contract & parity wiring
- **D-30:** contract.json grows **13 → 17 files**: + `hyprlock.conf` (dedicated render target — lock-specific variables for avatar/indicators/media, hyprlock.conf sources it instead of piggybacking on hyprland.conf), + swayosd `style.css`, + zen userChrome colors, + satty config. The wlogout redesign edits its existing template. Parity matrix grows automatically via Phase 5's dynamic palette enumeration, light+dark fixtures both.
- **D-31:** Satty annotation colors are pipeline-themed: default annotation color = palette primary, standard palette row (incl. a true red) still available.

### Keybinds
- **D-32:** Print family owns capture (D-05). Freed Super+X/Z go to utilities: X/Z + shift-chords cover emoji, color picker, icon-theme picker, font switcher — **exact chord assignment is Claude's discretion** (avoid all existing binds; document for Phase 7's cheat-sheet). Super+C clipboard and Super+T/B/W stay untouched.

### Claude's Discretion
- Exact chord assignment for the four utility binds on the X/Z families (D-32).
- Satty toolbar/config details beyond D-02/D-31; exact ffmpeg GIF palette-pass flags; notification wording.
- Emoji injection tool choice (wtype vs ydotool) — research reliability under Hyprland/Wayland.
- Exact variable sets per new matugen template; hyprlock target's variable naming.
- cliphist wipe-hook wiring (uwsm session-end vs Hyprland exit dispatcher).
- GTK font-name key mapping for the font switcher's GTK surface; vscodium settings.json font update mechanics.
- wlogout hover-label mechanics and bar sizing/margins; hyprlock element positioning and typography.
- Record-start walker picker option labels/ordering.
- AUR additions follow the Phase 4 precedent (human package-legitimacy gate at execution): gpu-screen-recorder, hyprshot, tela-icon-theme, colloid-icon-theme (+ satty/swayosd/hyprpicker/wtype/ddcutil from official repos as needed).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — WLOG-01, LOCK-01, OSD-01, THM-05, SHOT-01..03, UTIL-01..05 definitions
- `.planning/ROADMAP.md` — Phase 6 goal + 5 success criteria (light+dark verification, lockout-recovery mandate, clipboard cap/wipe from day one, contract targets for swayosd/zen/hyprlock)

### Theme engine (pattern to extend)
- `theme-engine/.config/theme-engine/contract.json` — 13-file output contract; grows to 17 (D-30)
- `theme-engine/.config/theme-engine/theme-apply` + `lib/generate.sh` + `lib/commit.sh` + `lib/reload.sh` — render→commit→reload pipeline all new targets flow through; zen self-heal (D-26) and papirus-folders accent (D-17) hook into apply/reload
- `theme-engine/.config/theme-engine/theme-parity` — parity gate with light+dark fixtures (Phase 5); new targets must pass both
- `matugen/.config/matugen/config.toml` + `matugen/.config/matugen/templates/` — template registration pattern; `wlogout-colors.css` template already exists (redesign edits it)

### Surfaces under change
- `wlogout/.config/wlogout/layout` + `wlogout/.config/wlogout/style.css` + `wlogout/.config/wlogout/icons/` — current full-screen grid + SVG icons; becomes center bar + Nerd Font glyphs (D-09/D-10); icons/ deleted
- `hypr/.config/hypr/hyprlock.conf` — current lock config incl. Phase 4 FIX-02 hardening (immediate_render, ignore_empty_input, check_text) which MUST be preserved through the redesign
- `hypr/.config/hypr/scripts/screenshot.sh` — replaced by the hyprshot→satty flow
- `hypr/.config/hypr/config/keybinds.conf` — Print family + X/Z utility chords land here; Super+C/T/B/W untouched
- `hypr/.config/hypr/config/autostart.conf` — cliphist watchers already here; swayosd backend service + cap policy wiring
- `hypr/.config/hypr/scripts/wallpaper-picker.sh` — the fzf-kitty + kitty-graphics preview pattern the icon/font pickers replicate (D-20)

### Reliability procedures
- Phase 4 lockout-recovery procedure (in `.planning/phases/04-reliability-fixes-tech-debt/` artifacts, 04-02 plan/summary) — mandatory for all hyprlock testing (D-14)

### Reproducibility
- `install.sh` — PACMAN_PKGS + AUR_PKGS arrays: ~10 new packages (D-03, D-16, D-18, satty, swayosd, hyprpicker, wtype, ddcutil)
- `stow.sh` — first-boot theme state seeding; new state files (font axis D-19) follow its pattern
- `verify/` container gate — must stay green: zen skips gracefully headless (D-26/D-29), swayosd reload guarded like other headless-unsafe steps

### External reference
- Omarchy `bin/omarchy-capture-screenrecording` (github.com/basecamp/omarchy) — proven gpu-screen-recorder wrapper: slurp monitor/region picker, SIGINT stop, ffmpeg finalize; adapt, don't reinvent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `wlogout.css` render target + `@import` in style.css — the redesign is template + CSS work, no new plumbing
- Phase 5's fzf-kitty picker stack (kitty graphics protocol previews, floating window launcher, pipeline-themed fzf-colors.conf) — direct pattern for icon/font pickers
- Phase 5's walker dmenu exit-code-130 cancel handling (theme-switch.sh) — reuse in the record-start audio picker and any new dmenu flows
- Phase 4's hyprlock FIX-02 hardening — preserved verbatim; redesign is additive visual work
- cliphist already running (wl-paste watchers in autostart.conf) + Super+C bind — UTIL-03 adds cap/wipe policy, not new capture plumbing
- playerctl 2.4.1 already installed — hyprlock now-playing needs no new package

### Established Patterns
- Rendered-file + state-dir pattern (`~/.local/state/theme/`) — every new surface follows it; git tree stays clean on switch
- Atomic render-then-commit — new targets must render before commit so a failed render leaves the desktop unchanged
- Headless guards in reload fan-out — swayosd restart, zen notify, papirus-folders must all early-return without a session (container gate)
- Dynamic `palettes/*.json` enumeration — parity coverage for new targets is automatic across all 22 themes
- Preset/input validation before path interpolation (v1.0 security posture) — applies to profile paths from profiles.ini (D-26) and picker inputs

### Integration Points
- `lib/reload.sh` fan-out — gains: swayosd (style reload/restart), zen (notify-only), papirus-folders accent, satty (config re-read is per-launch, no reload needed)
- `theme-apply` — font-axis state read at render time (D-19); icon-theme picker writes gsettings like `lib/gtk.sh` does
- Phase 7 consumes everything: utility scripts become Utilities submenu entries; keybind choices feed the MENU-07 cheat-sheet; keep scripts CLI-invokable with no interactive prerequisites
- Phase 8 waybar work adds the recording indicator later — the record script should expose an easy status probe (pgrep pattern) for it

</code_context>

<specifics>
## Specific Ideas

- Omarchy is the explicit aesthetic and architecture reference again: Print-key capture family, gpu-screen-recorder wrapper, hyprshot→satty flow all mirror Omarchy's capture stack.
- "HUD, not a page" for wlogout — the center bar should feel like an overlay control, with the desktop visible behind it.
- Lock screen goes maximalist deliberately (all four extras selected) while the avatar stays a themed initial — personal photo explicitly kept out of the repo.
- Hardware reality drove the recorder choice: RTX 3070 + libva-nvidia-driver means NVENC (gpu-screen-recorder) is the only real hardware-encode path.

</specifics>

<deferred>
## Deferred Ideas

- Waybar recording-indicator module — Phase 8 (waybar work is Phase 8 scope); record script exposes a status probe for it
- Utility keybinds inside the Super-key menu + searchable cheat-sheet — Phase 7 (MENU-02, MENU-07)
- ICON-BROWSE (discover/install new icon themes from the picker) — already deferred beyond v2.0 in REQUIREMENTS.md
- Zen new-tab page / deep chrome styling — rejected for update-resilience (D-27); revisit only if chrome-colors proves stable across Zen updates

</deferred>

---

*Phase: 6-Themed Surfaces & Utility Suite*
*Context gathered: 2026-07-12*
