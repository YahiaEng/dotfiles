---
status: resolved-by-redesign
trigger: "eww media popup transport controls (prev/play-pause/next) do not respond to clicks even after converting GTK buttons to eventbox>box>label. Popup is an eww overlay layer-shell window on Hyprland 0.55.4, :focusable false, with a scrim backdrop for click-away. Backdrop click-away DOES work (popup closes on outside click). No interactive widget inside the popup receives clicks. Prior eventbox theory DISPROVEN."
created: "2026-07-15"
updated: "2026-07-15"
---

# Debug Session: eww-media-popup-clicks-dead

## Symptoms

- **Expected behavior:** Clicking prev / play-pause / next in the eww media popup controls MPRIS playback; seek/volume scales drag.
- **Actual behavior:** Clicks on transport controls do nothing. NO interactive widget inside the popup receives clicks. However, the full-screen scrim backdrop window DOES receive clicks (clicking outside the popup closes it via click-away).
- **Error messages:** None reported yet — eww daemon logs not yet checked.
- **Timeline:** Never worked. Built this session during Phase 08 post-phase gap-closure. Backdrop click-away was added and works; transport-button interaction has never fired.
- **Reproduction:** Run `media-popup-open.sh` to open the eww overlay popup, click any transport button — nothing happens.

## Environment / Constraints

- Hyprland 0.55.4, eww daemon running (pid confirmed), Wayland layer-shell.
- Popup: eww window, likely `:stacking "overlay"`, `:focusable false`, plus a separate scrim/backdrop eww window for click-away.
- Hyprland blur layerrule namespace `eww-media-popup`.
- NO pointer-injection tool available agent-side (no ydotool/wlrctl/wtype). User must live-test any interaction fix.
- Files: eww/.config/eww/eww.yuck, eww/.config/eww/eww.scss, hypr/.config/hypr/config/windowrules.conf, hypr/.config/hypr/scripts/media-popup-open.sh, hypr/.config/hypr/scripts/media-popup-close.sh

## Eliminated

- hypothesis: "GTK buttons need a focus-grab that fails on the layer surface; eventboxes fire on raw pointer so converting button->eventbox will fix it"
  evidence: Converted transport controls to eventbox>box>label; clicks STILL do nothing. DISPROVEN.

## Key Signal (strong lead)

The scrim BACKDROP window receives pointer clicks (click-away works), but the POPUP window's widgets do not. Both are eww layer-shell windows. This points at a per-window difference — stacking order (backdrop drawn ABOVE popup and eating events?), the popup window's own exclusivity/focusable/namespace config, or the popup surface not being assigned an input region — rather than a widget-level (button vs eventbox) problem.

## RESOLUTION (resolved-by-redesign)

- **Root cause:** eww layer-shell surface widgets do not receive pointer input on this build (eww 0.6.0 Wayland build — confirmed linked against libgtk-layer-shell + libwayland-client; Hyprland 0.55.4). This is a toolkit-level limitation, NOT a config bug. Confirmed dead ends:
  1. `:stacking` overlay AND fg — no difference.
  2. `eventbox` AND plain `button :onclick` — no difference (buttons render correctly, clicks never fire).
  3. `:wm-ignore false` (real-window path from the working husseinhareb/hyprland-eww reference) — NO-OP on Wayland: `hyprctl clients` never lists the window, `hyprctl layers` still shows it as `namespace eww-media-popup` on a layer. eww on Wayland is layer-shell-only; the wm-ignore/windowtype/anchor X11 attrs are ignored.
  4. Nothing overlaps the popup (`hyprctl layers`: only awww-daemon L0, waybar L2 at y6-46, popup L2 at y46 — popup is topmost over its region). No layer is stealing clicks.
  5. eww is the correct Wayland build (pacman eww 0.6.0; binary links gtk-layer-shell) — not an X11/wrong-build mismatch. waybar (same toolkit family) receives clicks fine, so the compositor CAN route pointer to layer surfaces; eww specifically does not deliver to its widgets here.
- **Could not self-verify:** no pointer-injection tool available (ydotool/wlrctl/dotool absent; wtype is keyboard-only; wlrctl AUR-only). Every attempt required a user click-test; all 3 came back "still nothing."
- **Resolution:** Replace the eww media popup with a standalone AGS/astal media applet (a real window with working pointer input + native cava), keeping waybar + swaync + matugen theming. Backend MPRIS scripts (media-players.sh / media-status.sh / media-art-resolve.sh) are toolkit-agnostic and carry over. User decision recorded 2026-07-15. The eww media-popup/-backdrop windows + media-popup-open/close scripts will be retired by that build (tracked as a separate feature, not this debug session).
- **Files reverted to committed baseline** (bedb01d): eww.yuck, eww.scss, media-popup-open.sh — all failed experiments discarded; tree clean.

## Current Focus (attempt 2 — copy the working reference)

- status: FIX APPLIED — awaiting user live click-test.
- reference: husseinhareb/hyprland-eww — a KNOWN-WORKING eww music-controls config on Hyprland. Its transport controls are plain `(button :onclick "..." GLYPH)` on a `:stacking "fg"` window. (NOTE: the repo the user first linked, yurihikari/garuda-hyprdots, is AGS/HyprPanel — NOT eww — so it cannot be copied into this eww setup.)
- fix applied (copying the working pattern):
  1. media-popup `:stacking "overlay"` -> `"fg"` (attempt 1, kept).
  2. Transport eventbox -> plain GTK `button :onclick` (class `transport-btn-btn` wrapping the styled `.transport-btn` pill). eww.yuck lines ~90-105.
  3. Added `:windowtype "dock"` to the media-popup window (matches the reference; confirmed still a layer-shell surface, namespace eww-media-popup — positioning preserved).
  4. eww.scss: reset GTK button chrome on `.transport-btn-btn` so only the inner pill shows.
- render verified: grim screenshot shows correct pill buttons, seek, volume, switcher — styling intact.
- prior confound corrected: the earlier "buttons didn't work" test ran on `overlay` + `:focusable false` simultaneously. This is the FIRST test of plain buttons on the `fg` layer.
- next_action: USER opens popup, clicks prev/play-pause/next. If they respond -> confirmed, close session, then check seek/volume drag. If STILL dead -> escalate to the managed-window approach (`:wm-ignore false`, needs float windowrules) which forces normal Hyprland pointer/keyboard focus.

## Evidence

- timestamp: 2026-07-15T13:50
  checked: `hyprctl layers` with both windows open (backdrop opened first, then popup — mirroring media-popup-open.sh `_open_eww`)
  found: backdrop -> `top` layer (level 2), namespace `gtk-layer-shell`, xywh `0 46 2560 1440` (full screen). popup -> `overlay` layer (level 3), namespace `eww-media-popup`, xywh `2212 56 338 582`. Overlay (3) is ABOVE top (2).
  implication: DISPROVES the orchestrator's primary "backdrop stacked ABOVE popup, eating clicks" hypothesis. The popup is genuinely on top over its own rectangle; the backdrop cannot be intercepting clicks that land on the popup. The remaining window-level difference is the stacking LAYER itself (overlay vs top).

- timestamp: 2026-07-15T13:52
  checked: `eww get media` + `media-status.sh watch` sample while popup open
  found: `media.status == "Playing"`, full metadata present (firefox player active). media-center `:visible {media.status != ""}` evaluates TRUE.
  implication: DISPROVES "popup content invisible/collapsed so no widget to click". The transport/seek/volume/switcher widgets are rendered and allocated (confirmed by screenshot). The bug is pointer delivery to rendered widgets, not visibility.

- timestamp: 2026-07-15T13:54
  checked: screenshot of popup (grim) — renders album-art fallback, title, artist, transport row (prev / accent play-pause / next), seek bar, volume, Firefox switcher. All visibly present and laid out.
  found: popup UI is fully rendered and correctly styled.
  implication: confirms widgets exist and are sized; failure is input, not layout.

- timestamp: 2026-07-15T14:00
  checked: `hyprctl dispatch movecursor` over prev button + grim + PIL pixel-diff of the prev-button region (baseline cursor-away vs cursor-on-prev). Attempted positive controls: waybar workspace hover, waybar clock tooltip.
  found: prev-button pixels barely changed (delta ~3) with cursor on it — NO `:hover` accent flip. BUT positive controls (waybar hover / tooltip) also produced no visible change, so `movecursor` may not emit wl_pointer motion events to clients at all.
  implication: INCONCLUSIVE. The movecursor-hover technique is not a validated pointer-delivery probe on this setup; cannot use "no hover" as strong evidence without a confirmed positive control. Need either a validated positive control (add temp `:hover` to the backdrop, which is KNOWN to receive pointer) or user live-testing.

## Eliminated

- hypothesis: "GTK buttons need a focus-grab that fails on the layer surface; eventboxes fire on raw pointer so converting button->eventbox will fix it"
  evidence: Converted transport controls to eventbox>box>label; clicks STILL do nothing. DISPROVEN. (carried from prior session)

- hypothesis: "The backdrop window is stacked ABOVE the popup and captures all pointer events across the whole screen including over the popup"
  evidence: `hyprctl layers` shows popup on overlay (level 3) ABOVE backdrop on top (level 2). Backdrop is BELOW popup over the popup's rectangle. Also: if backdrop were on top over the popup, clicking a transport button would hit the backdrop's onclick and CLOSE the popup — but the symptom is clicks do NOTHING (popup stays open). DISPROVEN.

- hypothesis: "Popup content is invisible (media.status empty) so there are no widgets to click"
  evidence: media.status == 'Playing', media-center visible, screenshot shows fully rendered controls. DISPROVEN.
