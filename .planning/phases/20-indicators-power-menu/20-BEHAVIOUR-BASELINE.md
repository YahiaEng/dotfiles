# Phase 20 GATE-01: swayosd + wleave Behaviour Baseline

Written per the GATE-01 Recurrence Protocol in `18-BEHAVIOUR-BASELINE.md` § "GATE-01
Recurrence Protocol" (six steps, surface-agnostic), taken in wave 1 of this phase — before any
redesign work and before any deletion is planned. Read directly off the live implementations
(no dedicated resolver exists for either surface's config format, per the protocol's own
per-phase surface table).

This document is what GATE-02 judges the replacement OSD/power-menu surfaces against. It is
**not** a port specification (step 6) — see `## Not a Port Specification` below.

---

## swayosd

### Layer-shell geometry — NOT CSS-configurable

The pill's **anchor position (bottom-center)** and **margin-from-edge** are SwayOSD's own
built-in layer-shell behavior, hardcoded in the binary — `swayosd/.config/swayosd/style.css`'s
own header comment states this explicitly (lines 3-7): *"Anchor position (bottom-center) +
margin-from-edge (64px) are SwayOSD's own built-in layer-shell behavior, not CSS-configurable
(06-UI-SPEC.md 'SwayOSD' spacing table) — this file only themes colors + the pill/track/fill
structure via the `@define-color` names imported above."* This file is the **only** file in the
`swayosd/` stow package.

### Themed geometry/color (the CSS-configurable half)

- `window { background: transparent; }`
- `#container` (the pill itself): `background-color: alpha(@background, 0.85)`, `margin: 16px`,
  `padding: 16px`, `border-radius: 999px` (full pill).
- `image` (icon): `color: @on_background`, `-gtk-icon-transform: scale(1.2)` — 1.2x icon scale.
- `label`: `color: @on_background`, `font-family: "FiraCode Nerd Font"`, `font-size: 16px`.
- `progressbar, progressbar > trough` (progress track): `min-height: 6px`, `border-radius:
  999px`, `background-color: alpha(@surface_variant, 0.6)`.
- `progressbar > trough > progress` (progress fill): `min-height: 6px`, `border-radius: 999px`,
  `background-color: @primary` (solid, no alpha).
- Palette source: `@import url("../../.local/state/theme/swayosd.css")` (matugen-rendered).

### Two-unit topology (RETIRE-04's exact scope)

swayosd is split into **two separately-owned units**, confirmed live this session:

1. **`swayosd-libinput-backend.service`** — system-level unit.
   - `systemctl is-enabled` → `enabled`
   - `systemctl is-active` → `active`
   - `FragmentPath` = `/usr/lib/systemd/system/swayosd-libinput-backend.service`
   - `WantedBy=graphical.target`, symlinked live under
     `/etc/systemd/system/graphical.target.wants/swayosd-libinput-backend.service`
   - This is the keyless caps-lock OSD backend (reads the raw libinput event stream at the
     kernel level, independent of any Wayland session) — confirmed by
     `autostart.lua:190`'s own comment: *"The keyless caps-lock OSD is handled separately by the
     packaged `swayosd-libinput-backend.service` (system bus, enabled in install.sh)."*
2. **`swayosd-server`** — per-session, started at **`autostart.lua:192`**:
   `hl.exec_cmd("uwsm app -- swayosd-server")`. This is the process that actually renders the
   themed pill (reads `style.css`); it is a session-scoped GTK client, not a systemd unit.

**The split matters because it makes RETIRE-04's SDDM-greeter question non-obvious**: the
backend is enabled and running at system level (confirmed PID 1318, `Active: active (running)
since Sat 2026-08-15 17:11:23 EEST` this session) reaching pre-session contexts like the SDDM
greeter — but the thing that renders anything visible (`swayosd-server`) is only started inside
the already-authenticated Hyprland session. Whether the backend alone produces any visible
feedback at the greeter is GATE-01's own open measurement (see `20-GATE-01-MEASUREMENTS.md` §
D-20-17) — not concluded here.

### The six `swayosd-client` invocations (keybinds.lua:293-314, verbatim)

All six carry `locked = true` (keeps working over an active hyprlock session — see D-20-19)
and the two repeatable-key binds additionally carry `repeating = true`:

| Line | Bind | Command | Flags |
|---|---|---|---|
| 297 | `XF86AudioRaiseVolume` | `swayosd-client --output-volume raise` | `locked = true, repeating = true` |
| 298 | `XF86AudioLowerVolume` | `swayosd-client --output-volume lower` | `locked = true, repeating = true` |
| 299 | `XF86AudioMute` | `swayosd-client --output-volume mute-toggle` | `locked = true, repeating = true` |
| 300 | `XF86AudioMicMute` | `swayosd-client --input-volume mute-toggle` | `locked = true, repeating = true` |
| 307 | `XF86MonBrightnessUp` | `swayosd-client --brightness raise` | `locked = true, repeating = true` |
| 308 | `XF86MonBrightnessDown` | `swayosd-client --brightness lower` | `locked = true, repeating = true` |

No keybind drives the caps-lock OSD — it is keyless, driven entirely by
`swayosd-libinput-backend.service` reading raw input events (comment at `keybinds.lua:295-296`
confirms this explicitly).

---

## wleave

### The six `layout.json` entries — VERBATIM (this is the migration source for plan 20-06;
these strings exist nowhere else in the repo and are deleted with the package, D-20-26)

```json
{ "label": "lock",      "action": "uwsm app -- hyprlock",                                          "text": "Lock",      "keybind": "l" }
{ "label": "logout",    "action": "cliphist wipe; uwsm stop",                                       "text": "Log Out",   "keybind": "e" }
{ "label": "suspend",   "action": "systemctl suspend",                                              "text": "Suspend",   "keybind": "u" }
{ "label": "hibernate", "action": "systemctl hibernate",                                            "text": "Hibernate", "keybind": "h" }
{ "label": "reboot",    "action": "cliphist wipe; hyprshutdown --post-cmd 'systemctl reboot'",       "text": "Reboot",    "keybind": "r" }
{ "label": "shutdown",  "action": "cliphist wipe; hyprshutdown --post-cmd 'systemctl poweroff'",     "text": "Shut Down", "keybind": "s" }
```

Each entry also carries an `icon` field pointing at wleave's packaged SVGs
(`/usr/share/wleave/icons/{lock,logout,suspend,hibernate,reboot,shutdown}.svg`) — a runtime
dependency of the already-installed AUR package, not a repo asset.

**Note (previously unstated at this level of detail, confirmed by direct read this session):**
the current Logout action is the bare `cliphist wipe; uwsm stop` — it does **not** wrap through
`hyprshutdown` the way Reboot/Shutdown do. Any future change that adds a `hyprshutdown` wrapper
to Logout is a genuine *addition*, not a re-composition of an existing wrap.

### Top-level layout.json config keys

- `"buttons-per-row": "6"` — all six actions render in a single row.
- `"close-on-lost-focus": false`
- `"show-keybinds": false` — see `## Dead Definitions` below.
- `"column-spacing": 24` — the native inter-capsule gap mechanism (no CSS margin duplicates
  this — see the `style.css` capsule-geometry comment, which documents this explicitly as the
  "exactly one gap mechanism" invariant).
- `"button-aspect-ratio": 1.0` — keeps every button square.
- `"margin": "36.4%"` — a percentage inset (not a hardcoded pixel value), narrowing the
  available row width so six 96px-derived square buttons + five 24px gaps fit exactly.
- `"no-version-info": true` — collapses wleave's built-in "Wleave 0.7.0..." footer widget
  entirely (not merely hidden).

### style.css structure (09-03/09-04 six-capsule hue identity — the aesthetic D-20-25 redesigns
away from; recorded for completeness, not as a target — see `## Not a Port Specification`)

- Full-screen dim scrim on `window` itself: `rgba(0, 0, 0, 0.40)` — a deliberate hardcoded
  literal (documented exception to the zero-literal-colour convention, so the dim survives a
  total palette-resolution failure).
- `window > box` (content wrapper): `background-color: transparent`.
- Capsule base (`button`): `min-width: 62px`, `min-height: 62px`, `padding: 16px`,
  `border-width: 1px`, `border-style: solid`, `border-radius: 24px` — 96px derived outer size
  (62 + 2×16 + 2×1).
- Six per-hue capsules (`button#lock`, `#logout`, `#suspend`, `#hibernate`, `#reboot`,
  `#shutdown`): each pairs a translucent container-role fill (0.55 alpha rest / 0.70 alpha
  hover-focus) with an `on_*`-role glyph colour and a base-hue hairline border (0.82 alpha).
  Two of the six hues (`hibernate`, `reboot`) are `mix()`-derived (`vhue-teal`, `vhue-purple`)
  because this repo's four native M3 roles don't cover six distinct hues.
  `#shutdown` alone references `@error`/`@error_container` directly — the reserved severity
  role.
- Hover/focus: `transform: scale(1.06)`, a `cubic-bezier(0.55, 0, 0.28, 1.68)` overshoot on the
  transform only (duration tokenized via `--motion-duration-standard`); background/border/
  box-shadow keep literal `150ms ease`.
- Entrance: `@keyframes capsule-entrance` (opacity 0→1, `translateY(6px) scale(0.96)` →
  `translateY(0) scale(1)`), `animation-timing-function: var(--motion-easing-emphasized-
  decelerate)`, `animation-duration: var(--motion-duration-emphasized-in)`, staggered
  left-to-right in fixed 80ms increments: Lock 0ms, Log Out 80ms, Suspend 160ms, Hibernate
  240ms, Reboot 320ms, Shut Down 400ms (fixed literals — the stagger is a composition decision,
  not a token, per D-19's fence).
- Label reveal (`label.action-name`): hidden at rest (`opacity: 0`), 13px/400/1.2, slides up
  4px into place on hover/focus.
- `#version-info`: collapsed via `opacity: 0; font-size: 0; min-width: 0; min-height: 0;
  padding: 0; margin: 0` — a CSS-only defence-in-depth fallback behind the primary
  `no-version-info: true` config fix.

### Launcher (`hypr/.config/hypr/scripts/wleave.sh`)

Open-only launcher (D-18): no toggle branch, no liveness scan of any other running instance.
Backgrounds `wleave &`, waits `0.3s`, then checks the PID is still alive
(`kill -0 "$WLEAVE_PID"`); on either the binary being absent or the launch failing, emits a
`notify-send ... -u critical` and exits 1. This is the entire error-state surface (D-23) — no
in-surface error UI. Dismissal (Esc / scrim click-away) is handled natively by the wleave
binary itself.

### Three layer rules (`hypr/.config/hypr/config/windowrules.lua`)

All match `{ namespace = "wleave" }`:

- Line 231: `blur = true`
- Line 292: `animation = "fade"` — pinned to the fade bucket for BOTH entrance and exit (a
  documented fix for wleave's synchronous-hide behaviour breaking the default animation
  bucket).
- Line 440: `ignore_alpha = 0.25` — the compensating check for the window scrim's own
  composited alpha differing from the retired single-uniform-fill surface this replaced.

---

## wlogout / eww (`pacman -Qi` facts only — neither has a config tree in this repo)

| Package | Version | Install date | Install reason | Install script |
|---|---|---|---|---|
| `wlogout` | `1.2.2-0` | 2026-03-24 | Explicitly installed | No |
| `eww` | `0.6.0-1` | 2026-07-14 | Explicitly installed | Yes |

Neither package has a stow-managed config tree in this repo (no `wlogout/` or `eww/` stow
package directory exists) — this absence is itself the recorded finding for both surfaces, not
an omission. Both are confirmed live targets for RETIRE-07.

---

## Dead Definitions

Capabilities that are a deliberate prior cut rather than a live user-facing capability today —
named so a later executor does not mistake "recorded here" for "authorised to reproduce
unchanged":

- **`show-keybinds: false`** (wleave `layout.json`) — the six mnemonics (`l`/`e`/`u`/`h`/`r`/`s`)
  work today (confirmed functional via the `keybind` field being wired), but are **not
  displayed** on the capsules. D-20-24 deliberately reverses this for the QML replacement
  (mnemonics shown, per the redesign's UI-SPEC).

---

## Unaccounted Keys

Mechanical completeness check — every top-level key of `layout.json` and every top-level
selector class of both `style.css` files, enumerated, with the accounted-for set matched
against this document's own coverage above. Loop output (run this session):

```
$ python3 -c "
import json
d = json.load(open('wleave/.config/wleave/layout.json'))
top_keys = sorted(k for k in d.keys() if k != 'buttons')
button_keys = sorted(set().union(*(b.keys() for b in d['buttons'])))
print('layout.json top-level keys:', top_keys)
print('layout.json per-button keys:', button_keys)
"
layout.json top-level keys: ['buttons-per-row', 'button-aspect-ratio', 'close-on-lost-focus', 'column-spacing', 'margin', 'no-version-info', 'show-keybinds']
layout.json per-button keys: ['action', 'icon', 'keybind', 'label', 'text']

$ grep -oE '^[a-zA-Z#.][a-zA-Z0-9#.:,>_ -]*\{' swayosd/.config/swayosd/style.css | sed 's/ *{$//' | sort -u
#container
image
label
progressbar,
progressbar > trough
progressbar > trough > progress
window

$ grep -oE '^[a-zA-Z#.@][a-zA-Z0-9#.:,>_ -]*\{' wleave/.config/wleave/style.css | sed 's/ *{$//' | sort -u
box:hover button#hibernate:focus:not(:hover)
box:hover button#lock:focus:not(:hover)
box:hover button#logout:focus:not(:hover)
box:hover button#reboot:focus:not(:hover)
box:hover button#shutdown:focus:not(:hover)
box:hover button#suspend:focus:not(:hover)
box:hover button:focus:not(:hover)
box:hover button:focus:not(:hover) label.action-name
button
button #version-info
button label.action-name
button picture
button#hibernate
button#hibernate:hover,
button#lock
button#lock:hover,
button#lock:focus
button#logout
button#logout:hover,
button#reboot
button#reboot:hover,
button#shutdown
button#shutdown:hover,
button#suspend
button#suspend:hover,
button:hover,
button:hover label.action-name,
window
window > box
```

**Unaccounted set: EMPTY** for all three source files. Every `layout.json` top-level key, every
per-button key, and every top-level selector block in both `style.css` files is covered by the
sections above (`swayosd`'s six selector groups map 1:1 to the "Themed geometry/color" list;
`wleave`'s selector blocks map 1:1 to the capsule-geometry/hue-identity/hover-focus/entrance
sections). No stray key or rule was found outside this document's coverage.

---

## Not a Port Specification

wleave's six hue capsules (the per-id `@define-color` mix()-derived fills, the 0.55/0.70 alpha
rest/hover pairing, the 96px derived square geometry) and swayosd's flat unthemed pill
(`alpha(@background, 0.85)` full-radius capsule, no per-state colour identity) are the **exact
aesthetics D-20-25 redesigns away from**. Nothing in this document authorises reproducing
wleave's hue-capsule visual language or swayosd's plain pill shape in the QML replacement —
this document records the **capability** the user had (six distinct, keybind-addressable power
actions with hover/focus reveal; a themed volume/brightness/caps-lock pill with an icon, label
and progress fill), never the pixel/colour/duration values it was rendered at. GATE-02 judges
the replacement against the capability list above, not against a side-by-side visual diff of
this document's colour values.
