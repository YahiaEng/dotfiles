# Phase 6: Themed Surfaces & Utility Suite - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-12
**Phase:** 6-Themed Surfaces & Utility Suite
**Areas discussed:** Screenshot suite stack & flow, wlogout + hyprlock look, Utility pickers UX & policies, SwayOSD + Zen wiring, Satty annotator defaults, Keybind map for new utilities, Contract & parity wiring

---

## Screenshot suite stack & flow

| Option | Description | Selected |
|--------|-------------|----------|
| hyprshot | Hyprland-native grim+slurp wrapper, freeze, save+copy | ✓ |
| grimblast | hyprland-contrib equivalent | |
| Extend screenshot.sh | Keep custom script, own the edge cases | |

**User's choice:** hyprshot; captures pipe straight into satty (vs save-first or ask-per-capture).

**Recorder:** User asked for wf-recorder vs wl-screenrec pros/cons and what Omarchy uses. Verified from Omarchy source: Omarchy currently uses **gpu-screen-recorder** (migrated from wf-recorder → wl-screenrec → gsr). Hardware check: RTX 3070 + libva-nvidia-driver = no VAAPI encode, so wl-screenrec non-viable, wf-recorder CPU-only. Selected **gpu-screen-recorder** (NVENC).

**Other selections:** GIF via notification action (vs record-as-GIF mode / manual command); Omarchy-style Print-key family (vs keep Super+X/Z / you-decide); audio picker at record start via walker dmenu (vs silent-default / desktop-default); freeze-on region select; notify + same-key stop toggle (waybar dot rejected as Phase 8 territory); keep ~/Pictures/Screenshots + ~/Videos.

---

## wlogout + hyprlock look

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal center bar | Compact icon row over blurred desktop, HUD-style | ✓ |
| Refined full-screen grid | Modernize current 6-button grid | |
| Vertical side panel | Edge-docked stack | |

**User's choice:** Minimal center bar; Nerd Font glyph icons (vs matugen-recolored SVGs / static SVGs); all six power actions kept.

**Hyprlock:** Info-rich direction (vs minimal / restyle-only), with ALL extras selected: avatar, now-playing, battery+caps indicators, failed-attempts counter. Avatar = themed initial (vs ~/.face+fallback / repo image — user chose zero-asset option). Background stays blurred wallpaper (vs stronger dim / solid palette).

---

## Utility pickers UX & policies

| Option | Description | Selected |
|--------|-------------|----------|
| Cap ~100 + wipe on logout | Session-end wipe + manual wipe entry | ✓ |
| Cap ~500, manual wipe only | Persistent history | |
| Cap ~100 + wipe on lock | Wipe on every hyprlock | |

**User's choice:** Cap ~100 + wipe on logout.

**Other selections:** Icon themes Papirus + Tela + Colloid (chose the larger roster over recommended two); nerd-font 5-pack (JetBrains Mono, CaskaydiaCove, Hack, Iosevka, Meslo); **fzf-kitty with previews** for icon/font pickers (rejected the recommended all-walker-dmenu option — wallpaper-picker polish bar applies); emoji types into focused app + clipboard backup; font is an independent axis (vs per-theme memory); live specimen + icon-grid previews; color pick → notification with swatch (vs multi-format menu / silent); folder accents track theme via papirus-folders.

---

## SwayOSD + Zen wiring

| Option | Description | Selected |
|--------|-------------|----------|
| Client binds + libinput backend | Full setup incl. caps-lock | ✓ |
| Client binds only | No backend service, no caps OSD | |

**User's choice:** Client binds + libinput backend; bottom-center pill (vs top-center / centered); mute + mic-mute both OSD.

**Brightness:** Desktop has no backlight; DDC via ddcutil is monitor-dependent. Selected: volume/caps now, DDC brightness if research shows it's cheap — descope with evidence otherwise.

**Zen:** Lazy self-heal profile resolution (vs install-time headless bootstrap / documented manual step) — ~/.zen confirmed absent on this machine; chrome colors only (vs full rice); notify-only on theme switch (vs auto-restart / notification action); parity validates rendered file only (vs fixture profile in gate).

---

## Satty annotator defaults

**Selections:** Instant-out Enter = copy+save+exit (vs copy-only / deliberate); arrow pre-selected (vs rectangle / neutral); themed primary annotation color + fixed red available (vs fixed red / you-decide).

---

## Keybind map for new utilities

**Selections:** Reuse freed Super+X/Z (rejected convention-set-with-unbound-rare and everything-gets-a-key), then expanded to X/Z + shift-chords so all four utilities get keys; exact chord assignment left to Claude ("You decide" on the final pairing question).

---

## Contract & parity wiring

**Selections:** Dedicated hyprlock render target (vs piggybacking hyprland.conf); confirmed 13 → 17 contract files (+ hyprlock.conf, swayosd style.css, zen colors, satty config).

---

## Claude's Discretion

- Exact utility chord assignment on the X/Z families
- Satty config details beyond flow/color; ffmpeg GIF flags; notification wording
- wtype vs ydotool for emoji injection
- Template variable sets; hyprlock target naming
- cliphist wipe-hook wiring mechanism
- Font propagation mechanics per surface (GTK key, vscodium settings.json)
- wlogout bar sizing/hover labels; hyprlock layout/typography
- Record-start picker labels/ordering
- AUR additions via Phase 4-style package-legitimacy gate

## Deferred Ideas

- Waybar recording-indicator module → Phase 8
- Utility entries in Super-key menu + cheat-sheet → Phase 7
- ICON-BROWSE → beyond v2.0 (already tracked)
- Zen new-tab/deep styling → revisit only if chrome-colors proves update-stable
