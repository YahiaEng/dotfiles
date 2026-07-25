---
phase: 08-waybar-evolution
plan: 16
type: execute
status: complete
completed: 2026-07-15
gap_closure: true
outcome: approved — athena rebuilt and iterated to user approval over three checkpoint rounds
requirements: [BAR-01]
---

# 08-16 Summary: athena layout (rebuilds/renames `minimal`)

## Outcome

**APPROVED by the user on sight**, verbatim: **"approved"**, after three checkpoint
iterations on the live bar under tokyonight (dark) and catppuccin-latte (light). The
`minimal` layout is gone; `athena` exists in its place and the switcher enumerates it.

Screenshots (final): `/tmp/final-tokyonight.png`, `/tmp/final-latte.png`; filled-pill
close-ups `/tmp/v-clock.png` (cyan), `/tmp/v-updates.png` (green), `/tmp/v-notif.png` (blue).

## What shipped

The Athena reference *shape* (discrete rounded capsules, live-window workspace icons,
hover-expand drawers, an app-launcher drawer) expressed entirely through the repo's
`theme.css` alias layer. Then iterated on live UAT feedback:

### Round 1 — initial athena (Tasks 1–5 of the plan)
- `theme.css` capsule aliases; `config-athena.jsonc` + `style-athena.css` authored;
  `git mv` from `config-minimal`/`style-minimal`; stale-`minimal` sweep.

### Round 2 — user feedback (7 items)
- **Settings drawer** — a dedicated `group/settings` drawer (gear launcher) expanding to
  five switch axes: theme, waybar-layout, font, icons, wallpaper (all existing scripts).
  Added `custom/font` + `custom/icon-theme` to `modules.jsonc`.
- **Gaming-mode click-toggle** — the module had **no keybind and no on-click anywhere**;
  it was a display-only indicator wired to nothing. Added `on-click → gaming-mode-toggle.sh`
  (still a read-only consumer of the state file; the toggle script owns the logic).
- **eww media popup revived** — root cause (confirmed in the pending todo): the **eww
  daemon was never started** (absent from `autostart.conf`), so every media-segment click
  talked to a dead socket. Added `exec-once = uwsm app -- eww daemon`; wired `custom/media`
  beside the audio group; **restyled `eww.scss`** to the translucent-island language.
- **Notification bell** — pulled out of the tray drawer to a standalone module next to
  power. This surfaced the **pre-existing deferred `custom/notification` format bug**
  (`mixing manual and automatic argument indexing`), now fixed (`{}` → `{text}`).
- **System-updates pill** — `custom/updates` (glyph + count) beside the system pills,
  auto-hidden when `checkupdates` reports 0 via `exec-if`.
- **Per-group colour** + **focus-mode centring**.

### Round 3 — user feedback (3 items)
- **The missing settings gear** — root cause: the gear glyph (and the new font/icon
  glyphs) had been stored as **empty strings** — the private-use-area Nerd Font
  characters were stripped on input. An empty drawer *handle* makes waybar collapse the
  whole group to **zero width**, so the gear and its drawer were invisible. Fixed by
  writing the real codepoints as UTF-8 (`fa-gear`/`fa-font`/`fa-paintbrush`).
- **Colour legibility → "filled, but fewer"** (see decision below).
- **Duplicate network/bluetooth removed** — the `tray` showed nm-applet/blueman icons
  that duplicated the connections drawer; `tray` removed from athena.
- **Settings gear moved** to sit directly left of `custom/power`.

## Key decision — filled-pill colour (supersedes DESIGN Rule 2's "chroma = state only")

The user asked for "more theme colours". A measured WCAG contrast matrix (hue token vs the
translucent capsule, both presets) proved a **coloured glyph on a neutral translucent pill
is illegible on light presets**:

| preset | primary | secondary | tertiary(green) |
|--------|---------|-----------|-----------------|
| tokyonight (dark) | 5.9 / 4.3 | 8.7 / 6.2 | 8.2 / 5.9 — all fine |
| catppuccin-latte (light) | 2.6 / 3.4 | 2.4 / 3.1 | **1.6 / 2.1** — all fail |

No hue-tuning lifts a saturated glyph above ~3:1 on a light see-through pill. Resolution
(user: **"filled, but fewer"**): exactly **three** pills carry colour as a SOLID FILL with
the glyph in the guaranteed-contrast M3 `on_X` role — **clock** (`@secondary`), **updates**
(`@tertiary`), **notification** (`@primary`, only while unread). Everything else is neutral,
chroma reserved for state. `theme.css` `@fill-*`/`@fill-*-fg` roles. DESIGN.md Rule 2 amended.

## Deviations (from the plan-as-written)
- `custom/notification` format bug fixed (was logged deferred; became load-bearing once the
  bell was promoted to a standalone prominent module).
- `tray` removed from athena (duplicate of the connections drawer, per user).
- eww daemon added to `autostart.conf` + `eww.scss` restyled — this reaches back into
  08-06/07/08's scope (the "eww-media-popup-dead" todo), resolved here by user request.
- `custom/font` / `custom/icon-theme` added to `modules.jsonc` (new shared modules).

## Gates
- `waybar-design-lint`: athena all green (CHECK A resolves 14 refs, B/C/D/E pass). The 4
  failures are `style-floating.css`/`style-vertical.css` (08-13/08-14 scope, unchanged).
- `theme-doctor`: athena CSS parses non-empty; D-17 module-gate resolves every athena
  module's colour tokens. (Working-tree-clean check fails only on uncommitted work.)
- Live-verified: media popup opens (`eww active-windows` shows `media-popup`); gaming-mode
  toggles `off→on→off`; fills render (colour scan: cyan@2298-2380, green@156-218, blue).

## Follow-on (not in scope here)
- **Light-preset wallpapers**: light themes keep the prior dark wallpaper (empty light
  wallpaper dirs) — pre-existing, flagged to the user, deferred.
- `.planning/todos/pending/eww-media-popup-dead.md` — **resolved** by this plan (daemon
  autostart + restyle). Its 3rd ask (a gate asserting the popup opens) remains open.
- `.planning/todos/pending/swaync-intrusive-overlapping.md` — still pending.

## Self-Check: PASSED — user approved athena on sight under light + dark.
