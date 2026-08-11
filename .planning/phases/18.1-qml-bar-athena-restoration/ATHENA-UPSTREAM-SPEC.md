# Athena upstream reference — verified ground truth

**Source:** `https://github.com/haikal-hakim/athena` (cloned, read directly — not inferred).
**Why this file exists:** phase 18.1 was built against this repo's *local* `waybar/.config/waybar/style-athena.scss`, which is a **reinterpretation**, not Athena. The operator's GATE-02 rejections were against real Athena. Every value below is copied from the upstream repo. Do not "correct" any of it from the local scss.

## Bar geometry

| Property | Upstream value | Source |
|---|---|---|
| bar height | **42** | `config.jsonc` `"height": 42` |
| inter-module spacing | **6** | `config.jsonc` `"spacing": 6` |
| module margin | **4px 5px** | every `#…` rule in `tokens/*.css` |
| **effective gap between modules** | **16px** (5 + 6 + 5) | margin + bar spacing + margin |
| module capsule height | **34** (42 − 2×4) | derived |
| border-radius | **20px** | every module rule |
| font family | `JetBrainsMono Nerd Font` | `style.css` |

## Module layout — NOTE the centre group

```
modules-left:   group/distro-group   group/storage   group/system
modules-center: power-profiles-daemon   hyprland/workspaces   idle_inhibitor
modules-right:  group/audio   group/connections   battery   clock   group/tray-group
```

- `idle_inhibitor` (the **light-bulb**) is in **modules-center, immediately right of workspaces** — NOT on the right next to settings. Glyphs `󰛨` activated / `󰛩` deactivated; tooltips "System Focused" / "Normal Mode".
- `power-profiles-daemon` sits in the centre **left of** workspaces. Glyphs: default `` / performance `` / balanced `󰶘` / power-saver ``.

## Backgrounds — every module has one

Upstream puts `background-color: @surface_container` on **all** of: `#distro-group`, `#storage`, `#system`, `#audio`, `#connections`, `#workspaces`, `#battery`, `#clock`, `#tray-group`, `#power-profiles-daemon`, `#idle_inhibitor`.

`@surface_container` = `#1b2023`, against `@surface`/`background` = `#0f1416`. It is an **opaque, very dark** raise — subtle, not translucent. The local scss instead uses `alpha(@surface_variant, 0.85)`, which is translucent and picks up the wallpaper — that is a local divergence.

> **OPEN DECISION:** the operator states only the centre workspace module should carry a background. That contradicts upstream (above). Operator preference wins, but must be confirmed before implementing — do not silently pick either.

## Drawers (hover/expand groups)

| Group | transition-duration | direction | members |
|---|---|---|---|
| `distro-group` | **650** | left-to-right | `custom/distro` + terminal, code, obsidian, office, files, spotify, browser |
| `audio` | **650** | right-to-left | `pulseaudio`, `pulseaudio/slider`, `pulseaudio#microphone` |
| `connections` | **500** | right-to-left | `network`, `bluetooth` |
| `tray-group` | **500** | right-to-left | `custom/tray-arrow`, `tray` |

`storage` (disk, memory) and `system` (temperature, cpu) are **plain groups, not drawers** — always expanded.

There is **no dwell delay** upstream: a GTK drawer opens on hover immediately. Our `popoutDwellMs` (400) is the "delay on hover is longer" the operator reported.

## Workspaces — dynamic, not fixed

```jsonc
"format": "{icon} {windows}",
"persistent-workspaces": { "*": 5 },
"show-special": true,
"all-outputs": true,
"window-rewrite-default": "󰊠",
"format-icons": { "active": "󰮯", "special": "󱁂", "default": "󰊠", "urgent": "󰧵", "empty": "" }
```

- **5 persistent minimum, but grows**: workspaces beyond 5 appear as they are used. Our QML has 5 fixed slots that never grow — operator item (c).
- Button metrics: `min-width: 32px`, `padding: 0 4px`, `margin: 0 2px`, `border-radius: 16px`, colour `@tertiary`.
- Active: `padding: 0 12px`, `background @primary`, `color @on_primary`.
- Empty: `@outline_variant`. Urgent: `@error_container`. Special: `@tertiary_fixed`.
- **Glyph centring (operator item (a))**: `button label:first-child { margin-right: 8px }` and `button label:last-child { margin-left: 2px }`. The state icon and the window glyphs are separate labels with asymmetric margins — this is what makes them read centred.

## Right-side modules our bar is missing (operator item (d))

- **`group/audio`** — `pulseaudio` glyph at rest (`` / `` / `` by level, `󰋋` headphones, `` muted); drawer opens to reveal `pulseaudio/slider` (horizontal, 0–100) **and** `pulseaudio#microphone` (`` / `` muted). Click → `pavucontrol`.
- **`group/connections`** — `network` at rest (ethernet ``, wifi by strength `󰤯 󰤟 󰤢 󰤥 󰤨`, disconnected `󰤣`, disabled `󰤮`); drawer reveals `bluetooth` (`󰂯` / `󰂱` connected / `󰂲` disabled).
- **`battery`** — own pill, `padding: 6px 16px`.
- **`clock`** — own pill, `padding: 6px 10px 6px 16px`.
- **`group/tray-group`** — `custom/tray-arrow` + `tray`. (Tray was withdrawn from our bar under D-15 / QBAR-05.)

## App drawer order the operator specified

`zen > spotify > discord > steam > lutris > obsidian > vscodium`

(Upstream's own distro-group is a different app set — terminal/code/obsidian/office/files/spotify/browser — so the operator's list governs, not upstream's.)
