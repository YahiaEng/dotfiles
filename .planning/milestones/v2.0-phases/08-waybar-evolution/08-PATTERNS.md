# Phase 8: Waybar Evolution - Pattern Map

**Mapped:** 2026-07-14
**Files analyzed:** 22
**Analogs found:** 20 / 22

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `waybar/.config/waybar/modules.jsonc` (new, shared includes) | config | transform/CRUD | `waybar/.config/waybar/config-full.jsonc` | role-match (source of module defs to extract) |
| `waybar/.config/waybar/config-full.jsonc` (refactor to `include`) | config | request-response | itself (pre-refactor snapshot) | exact |
| `waybar/.config/waybar/config-minimal.jsonc` (refactor) | config | request-response | `config-full.jsonc` | exact (sibling) |
| `waybar/.config/waybar/config-floating.jsonc` (refactor + add `custom/notification`) | config | request-response | `config-full.jsonc` (has the module already) | exact |
| `waybar/.config/waybar/config-vertical.jsonc` (new) | config | request-response | `config-floating.jsonc` (closest to a "modules-left stacked" composition) + `config-full.jsonc` (module defs) | role-match |
| `waybar/.config/waybar/waybar-modules.css` (new, shared includes) | config/style | transform | `waybar/.config/waybar/style-full.css` | role-match |
| `waybar/.config/waybar/style-full.css` (OLED trim + refactor) | config/style | transform | itself (pre-refactor snapshot) | exact |
| `waybar/.config/waybar/style-minimal.css` (OLED trim + refactor) | config/style | transform | `style-full.css` | exact (sibling) |
| `waybar/.config/waybar/style-floating.css` (OLED trim + refactor) | config/style | transform | `style-full.css` | exact (sibling) |
| `waybar/.config/waybar/style-vertical.css` (new) | config/style | transform | `style-full.css` | role-match |
| `hypr/.config/hypr/scripts/waybar-switch.sh` (dynamic enumeration) | utility/script | event-driven (walker dmenu) | itself | exact |
| `hypr/.config/hypr/scripts/waybar-launch.sh` (dynamic enumeration) | utility/script | request-response | itself | exact |
| `hypr/.config/hypr/scripts/waybar-visibility.sh` (new, visibility owner) | utility/script | event-driven | `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` (state-file owner + atomic write pattern) | role-match |
| `hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh` (new, socket2 listener) | utility/script (daemon) | event-driven | none close — see "No Analog Found" | none |
| `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` (re-point `_gaming_waybar_toggle`) | utility/script | event-driven | itself | exact |
| `hypr/.config/hypr/config/hypridle.conf` (add visibility listener) | config | event-driven | itself (existing `listener {}` blocks) | exact |
| `hypr/.config/hypr/config/keybinds.conf` (add bar-toggle bind) | config | request-response | itself (existing bind lines with trailing `# description`) | exact |
| `hypr/.config/hypr/config/autostart.conf` (add fullscreen-watch exec-once) | config | event-driven | itself (existing `exec-once` lines) | exact |
| `hypr/.config/hypr/scripts/theme-doctor` (extend CSS-parse guard to 4th style + module-color assertion) | test/gate | batch | itself | exact |
| `hypr/.config/hypr/scripts/waybar-equivalence-check` (new, D-34 gate) | test/gate | batch | `theme-engine/.config/theme-engine/theme-parity` (rerunnable comparison-gate shape) | role-match |
| `eww/.config/eww/eww.yuck` (new) | component | event-driven | none installed locally — see "No Analog Found" | none |
| `eww/.config/eww/eww.scss` (new) | style | transform | `waybar/.config/waybar/style-full.css` (`@import` shared-file-first pattern) | role-match |
| `hypr/.config/hypr/scripts/media-popup-open.sh` (new, cursor-pos + eww open wrapper) | utility/script | request-response | `hypr/.config/hypr/scripts/color-picker.sh` / `wallpaper-picker.sh` (small wrapper scripts calling out to a GUI tool) | role-match |
| `hypr/.config/hypr/scripts/media-art-resolve.sh` (new, artUrl → local path resolver) | utility/script | file-I/O | none close — see "No Analog Found" | none |
| `matugen/.config/matugen/templates/eww-colors.scss` (new) | config/template | transform | `matugen/.config/matugen/templates/waybar-colors.css` | exact (same 19-key `@define-color`-style substitution, different syntax) |
| `matugen/.config/matugen/config.toml` (add `[templates.eww]`) | config | transform | itself (existing `[templates.*]` blocks) | exact |
| `theme-engine/.config/theme-engine/contract.json` (add `eww.scss` entry, new `scss-kv` format) | config | transform | itself | exact |
| `swaync/.config/swaync/config.json` (widgets rework: remove `mpris`, add `slider`/`volume`/`backlight`/`buttons-grid`) | config | CRUD | itself + `/etc/xdg/swaync/config.json` (shipped default, has a live `buttons-grid` toggle example) | exact |
| `swaync/.config/swaync/style.css` (delete `.widget-mpris*` rules, style new widgets) | style | transform | itself (existing `.widget-mpris-player` block being deleted; existing `.notification`/card rules as the style precedent for new widget containers) | exact |
| `install.sh` (add `eww` to `AUR_PKGS` under `checkpoint:human-verify`) | config | batch | itself (existing AUR_PKGS entries with a legitimacy-check comment, e.g. the icon-themes/game-center blocks) | exact |

## Pattern Assignments

### `waybar/.config/waybar/config-vertical.jsonc` (config, request-response)

**Analog:** `waybar/.config/waybar/config-full.jsonc` (module definitions) + `config-floating.jsonc` (structural shape of a modules-left-heavy layout)

**Bar-level keys pattern** (`config-full.jsonc` lines 1-9):
```jsonc
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "margin-top": 6,
    "margin-left": 10,
    "margin-right": 10,
    "spacing": 0,
```
For vertical: swap `"position": "top"` → `"position": "left"`, `"height"` → `"width": 48` (per UI-SPEC's 48px column), keep `margin-left: 8` (UI-SPEC flush-left inset), drop `margin-right`.

**Module reuse pattern** — every module named in D-12 (workspaces, clock, volume/pulseaudio, network, battery, notification, mpris, cpu/memory/temperature, tray, power) already has a working definition in `config-full.jsonc` (lines 31-186) or `config-floating.jsonc` (battery, backlight, lines 121-132). Do not re-invent format strings — glyph-reduce them (drop text, keep `{icon}` only) per D-13, and move any dropped text into `tooltip-format` (mpris tooltip pattern already at line 80 is the template: `"tooltip-format": "{player}: {artist} — {title}\n{album}\n{position} / {length}"`).

**Notification module** (copy verbatim from `config-full.jsonc` lines 155-174) — this is the exact block that must ALSO be added to `config-floating.jsonc` (currently missing, D-26 parity fix).

---

### `waybar/.config/waybar/modules.jsonc` (new, shared includes) — D-31 refactor

**Analog:** `config-full.jsonc` as the richest source of module definitions

**Extraction pattern:** module-definition keys only (`hyprland/workspaces`, `hyprland/window`, `mpris`, `clock`, `cpu`, `memory`, `temperature`, `pulseaudio`, `network`, `custom/theme`, `custom/waybar-layout`, `custom/notification`, `custom/power`, `tray`) — verbatim bodies from `config-full.jsonc` lines 31-186. Bar-level keys (`layer`, `position`, `height`, `margin-*`, `modules-left/-center/-right`) must NEVER appear in this file — confirmed by Verdict 3's first-wins semantics (`waybar(5)`: *"In case of duplicate options, the first defined value takes precedence"*).

**Per-layout override shape:** each `config-{X}.jsonc` gets `"include": ["modules.jsonc"]` as its first key, then its own bar-level keys + `modules-left/-center/-right` + any FULL redefinition (not partial patch) of a module it needs to customize (e.g. vertical's glyph-only `mpris`).

**Gaming-mode indicator module (new, D-35):**
```jsonc
"custom/gaming-mode": {
    "exec": "cat ~/.cache/gaming-mode 2>/dev/null || echo off",
    "interval": 5,
    "return-type": "",
    "format": "{}",
    "tooltip-format": "Gaming Mode: {}"
}
```
Modeled directly on `custom/notification`'s `exec`/`return-type`/`format` shape (`config-full.jsonc` lines 155-174) but simpler (plain text poll, not JSON) since it only reads one state-file value — same state file gaming-mode-toggle.sh already owns (`~/.cache/gaming-mode`), per D-28's anti-drift constraint.

---

### `waybar/.config/waybar/waybar-modules.css` (new, shared includes) — D-31 refactor

**Analog:** `style-full.css`

**Pattern:** CSS has no JSON-style `include`, but this repo already uses `@import url(...)` for the theme (`style-full.css` lines 1-2). Shared selectors (`#cpu`, `#memory`, `#temperature`, `#pulseaudio`, `#network`, `#mpris`, `#custom-notification`, `#custom-theme`, `#custom-waybar-layout`, `#custom-power`, `#tray`, `tooltip`) move here verbatim from `style-full.css` (lines 56-196); each `style-{X}.css` `@import`s this file AFTER the theme import, and may override individual properties via normal cascade (later rule wins at property level — more granular than the JSONC side, per Verdict 3).

---

### `waybar/.config/waybar/style-full.css` (OLED trim, D-06)

**Analog:** itself (before/after documented in UI-SPEC)

**Exact deltas** (UI-SPEC "OLED Styling Deltas" table, verified against live file lines 11-16, 29-33):
```css
/* BEFORE (style-full.css:11-16) */
window#waybar {
    background: @background;
    color: @on_surface;
    border-radius: 14px;
    border-bottom: 3px solid @primary;
}

/* AFTER */
window#waybar {
    background: alpha(@background, 0.90);
    color: @on_surface;
    border-radius: 14px;
    border-bottom: 1px solid alpha(@primary, 0.4);
}
```
```css
/* BEFORE (style-full.css:29-33) */
#workspaces button.active {
    color: @on_primary;
    background: @primary;
    border-bottom-color: @secondary;
}

/* AFTER */
#workspaces button.active {
    background: transparent;
    color: @primary;
    border-bottom: 2px solid @primary;
}
```

**Idle-dim state (new selector, additive, not a delta on an existing rule):**
```css
window#waybar.idle-dimmed { opacity: 0.05; }
```
This lives in the NEW owner-exclusive file `~/.local/state/theme/waybar-visibility.css`, imported by every `style-*.css` AFTER the theme import (same `@import url(...)` convention, line 1-2 pattern) — NOT hand-added to `style-full.css` itself.

---

### `hypr/.config/hypr/scripts/waybar-visibility.sh` (new, visibility owner, D-01..05/08)

**Analog:** `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` — closest existing "single owner script + state file" shape in the repo.

**Shebang + strict mode + header comment convention** (`gaming-mode-toggle.sh` lines 1-29):
```bash
#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              <TITLE> (D-xx)                          ║
# ╚══════════════════════════════════════════════════════╝
#
# <prose header explaining the hard constraint(s)>

set -euo pipefail

STATE_FILE="$HOME/.cache/<name>"
```

**Atomic state-write pattern** (`gaming-mode-toggle.sh` lines 45-52) — copy verbatim, this is the load-bearing anti-torn-read pattern:
```bash
_write_state() {
    local value="$1"
    printf '%s\n' "$value" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
}

_read_state() {
    cat "$STATE_FILE" 2>/dev/null || echo "off"
}
```
For `waybar-visibility.sh`, adapt to per-source intent tracking: one file per source under a directory (e.g. `~/.cache/waybar-visibility.d/<source>`), each written with the same tmp+mv atomic idiom, then compute the union.

**Best-effort external-call idiom** (`gaming-mode-toggle.sh` lines 76-79, 85, 92) — every `hyprctl`/`pkill`/`notify-send` call in this repo's scripts uses `2>/dev/null || true`:
```bash
hyprctl keyword decoration:blur:enabled 0 2>/dev/null || true
pkill -STOP -x hypridle 2>/dev/null || true
notify-send -a "Gaming Mode" "Gaming Mode: ON" "..." -i input-gaming -t 2500 2>/dev/null || true
```
`waybar-visibility.sh`'s SIGUSR1/SIGUSR2 sends and any CSS-file writes should follow the identical defensive idiom — this script is explicitly SILENT per UI-SPEC's Copywriting Contract ("no `notify-send` calls"), so only the signal/file-write lines need the `|| true` guard, not a notify line.

**CLI contract shape** (`gaming-mode-toggle.sh` lines 149-165, `main()`) — mirrors the `<source> <hide|show>` entrypoint CONTEXT.md specifies:
```bash
main() {
    local arg="${1:-}"
    if [[ "$arg" == "status" ]]; then
        _read_state
        exit 0
    fi
    ...
}
main "$@"
```

---

### `hypr/.config/hypr/scripts/waybar-switch.sh` and `waybar-launch.sh` (dynamic enumeration, D-32)

**Analog:** itself (both files) — hardcoded lists to replace with disk enumeration.

**Current hardcoded list to replace** (`waybar-switch.sh` lines 15-17, 36-41):
```bash
LAYOUT_LIST="📏 Minimal — Clock + Workspaces
📊 Full — System stats, media, tray
🏝️ Floating — Island-style modules"
...
case "$SELECTED" in
    *"Minimal"*)   LAYOUT="minimal"  ;;
    *"Full"*)      LAYOUT="full"     ;;
    *"Floating"*)  LAYOUT="floating" ;;
    *)             exit 1            ;;
esac
```
Replace with a `config-*.jsonc` glob (`ls "$WAYBAR_DIR"/config-*.jsonc`, strip `config-`/`.jsonc`, title-case per UI-SPEC's "derived from the filename" copy rule) — this is the **identical fix already proven in Phase 5's palette enumeration** (per CONTEXT D-32's own reference); look at `wallpaper-picker.sh`/palette-loading code in `theme-engine/lib/` for the established glob+basename idiom if a second confirming analog is wanted.

**Current hardcoded validation to replace** (`waybar-launch.sh` lines 10-13):
```bash
case "$LAYOUT" in
    minimal|full|floating) ;;
    *) LAYOUT="full" ;;
esac
```
Replace with: check `[[ -f "$WAYBAR_DIR/config-$LAYOUT.jsonc" ]]` instead of an enum list — same disk-truth principle.

**Walker-dmenu exit-130-cancel pattern** (`waybar-switch.sh` lines 20-31) — reuse verbatim unchanged, this is the exact pattern CONTEXT.md names as precedent:
```bash
rc=0
SELECTED=$(echo "$LAYOUT_LIST" | walker --dmenu --placeholder "Waybar Layout") || rc=$?
if (( rc == 130 )); then
    exit 0   # user cancel
elif (( rc != 0 )); then
    notify-send -a "Waybar Switcher" "Error" "walker dmenu failed" -i dialog-error 2>/dev/null || true
    exit 1
fi
```

---

### `hypr/.config/hypr/config/hypridle.conf` (add idle-hide listener, D-05)

**Analog:** itself — existing `listener {}` blocks

**Pattern** (lines 12-16, the dim-on-timeout listener is the closest structural match):
```
listener {
    timeout = 300
    on-timeout = brightnessctl -s set 30%
    on-resume = brightnessctl -r
}
```
New listener follows this exact shape, calling the visibility owner instead of brightnessctl:
```
listener {
    timeout = <TUNABLE, Claude's discretion per D-05>
    on-timeout = ~/.config/hypr/scripts/waybar-visibility.sh idle hide
    on-resume = ~/.config/hypr/scripts/waybar-visibility.sh idle show
}
```

---

### `hypr/.config/hypr/config/keybinds.conf` (bar-toggle bind, D-37)

**Analog:** itself — existing waybar/swaync bind lines

**Pattern** (lines 60, 104):
```
bind = $mainMod, B, exec, ~/.config/hypr/scripts/waybar-switch.sh # Switch waybar
bind = $mainMod, N, exec, swaync-client -t -sw # Toggle notification center
```
New bind must follow the identical `bind = <mod>, <key>, exec, <script> # <description>` shape — trailing `# description` is mandatory (MENU-07 cheat-sheet parses this literally).

---

### `hypr/.config/hypr/config/autostart.conf` (add fullscreen-watch listener, D-01)

**Analog:** itself

**Pattern** (lines 31, 34, 41):
```
exec-once = uwsm app -- ~/.config/hypr/scripts/waybar-launch.sh
exec-once = uwsm app -- swaync
exec-once = uwsm app -- hypridle
```
New long-running fullscreen-listener script gets its own `exec-once = uwsm app -- ~/.config/hypr/scripts/waybar-fullscreen-watch.sh` line, same `uwsm app --` wrapper convention as every other daemon-shaped autostart entry.

---

### `matugen/.config/matugen/templates/eww-colors.scss` (new render target, D-19)

**Analog:** `matugen/.config/matugen/templates/waybar-colors.css` (exact same 19-key substitution, different output syntax)

**Source pattern** (verbatim, all 19 keys, lines 1-20):
```css
/* Auto-generated by matugen — Material You */
@define-color primary {{colors.primary.default.hex}};
@define-color on_primary {{colors.on_primary.default.hex}};
... (17 more keys, identical structure)
```
**New SCSS-syntax equivalent** (same 19 keys, same matugen `{{colors.X.default.hex}}` substitution tokens, SCSS `$var:` syntax instead of GTK `@define-color`):
```scss
// Auto-generated by matugen — Material You
$primary: {{colors.primary.default.hex}};
$on_primary: {{colors.on_primary.default.hex}};
... (17 more keys, identical structure)
```

---

### `matugen/.config/matugen/config.toml` (add `[templates.eww]`)

**Analog:** itself — every existing `[templates.X]` block is the identical 3-line shape

**Pattern** (e.g. lines for `[templates.swayosd]`):
```toml
# ── SwayOSD colors (OSD-01/D-24) ─────────────────────
[templates.swayosd]
input_path = "~/.config/matugen/templates/swayosd-colors.css"
output_path = "~/.local/state/theme/swayosd.css"
```
New block:
```toml
# ── eww colors (BAR-04/D-19) ─────────────────────────
[templates.eww]
input_path = "~/.config/matugen/templates/eww-colors.scss"
output_path = "~/.local/state/theme/eww.scss"
```
No `post_hook` lines anywhere in this file (reload is owned solely by `theme-engine/lib/reload.sh` per the file's own header comment) — do not add one for eww either.

---

### `theme-engine/.config/theme-engine/contract.json` (add `eww.scss` entry + new format)

**Analog:** itself

**Pattern** (existing entries, e.g. line 15):
```json
{ "name": "fzf-colors.conf", "format": "env-kv" },
```
New entry (new format value, since neither `gtk-css` nor `env-kv` parsers match SCSS `$var: value;` syntax per UI-SPEC's own note):
```json
{ "name": "eww.scss", "format": "scss-kv" },
```
Files array grows from 17 → 18 entries (confirmed by direct read: current file has exactly 17 entries in `files[]`, lines 3-19).

---

### `swaync/.config/swaync/config.json` (widget rework, D-24/27/28/30)

**Analog:** itself + the installed default `/etc/xdg/swaync/config.json` (has a live `buttons-grid` toggle worked example)

**Current widgets list to modify** (lines 27-32):
```json
"widgets": [
    "dnd",
    "mpris",
    "title",
    "notifications"
]
```
**New widgets list** (remove `mpris`, add `volume`/`backlight`/`buttons-grid`, geometry per UI-SPEC's ordering "title → dnd → volume → backlight → toggle grid → notifications"):
```json
"widgets": [
    "title",
    "dnd",
    "volume",
    "backlight",
    "buttons-grid",
    "notifications"
]
```
**Remove from `widget-config`** (lines 33-37, the mpris sub-block):
```json
"mpris": {
    "image-size": 96,
    "image-radius": 12
}
```
**Add `buttons-grid` config** — modeled directly on the installed swaync's own shipped default (`/etc/xdg/swaync/config.json`, WiFi toggle, verified live):
```json
"buttons-grid": {
    "buttons-per-row": 3,
    "actions": [
        {
            "label": "<gaming-glyph, cmap-verify first>",
            "type": "toggle",
            "command": "~/.config/hypr/scripts/gaming-mode-toggle.sh",
            "update-command": "sh -c '[[ $(cat ~/.cache/gaming-mode) == on ]] && echo true || echo false'"
        },
        {
            "label": "󰂛",
            "type": "toggle",
            "command": "swaync-client -dn 2>/dev/null || swaync-client -df",
            "update-command": "swaync-client -D"
        },
        {
            "label": "<theme-glyph, cmap-verify first>",
            "type": "toggle",
            "command": "~/.config/hypr/scripts/theme-switch.sh",
            "update-command": "<query current theme mode>"
        }
    ]
}
```
**`control-center-width`** (line 20): change `380` → `420` per UI-SPEC D-30's revisited geometry; margins (lines 16-19) stay unchanged.

**D-28's hard constraint verification:** `gaming-mode-toggle.sh`'s own `main()` (lines 149-165, already read) is bare-toggle-shaped — calling it with no args from `command` is correct and matches its existing CLI contract exactly (only `status` is a special arg). This is a genuine reuse, not a re-implementation.

---

### `swaync/.config/swaync/style.css` (delete mpris rules, style new widgets)

**Analog:** itself — the exact `.widget-mpris*` block to delete (verified live, lines 59-101 range):
```css
.widget-mpris { margin: 6px 8px; }
.widget-mpris-player { background: @surface_variant; border: 2px solid @secondary; border-radius: 14px; ... }
.widget-mpris-player > box > image { border-radius: 12px; margin-right: 10px; }
.widget-mpris-title { color: @on_surface; font-size: 14px; font-weight: bold; }
.widget-mpris-subtitle { color: @secondary; font-size: 12px; }
.widget-mpris-player button { background: transparent; color: @primary; border: none; }
.widget-mpris-player button:hover { background: @primary; color: @on_primary; }
```
Delete this block in full (D-24 — "deleted in full, not repurposed"). The button hover convention (`background: @primary; color: @on_primary;` on hover) is exactly the pattern UI-SPEC's eww button-state table reuses verbatim for the NEW popup's transport buttons — read this block before deleting it, since its visual language survives the surface migration into eww's SCSS.

**New widget container styling** — model on the existing `.notification`/card convention already in this stylesheet (12px padding/radius per UI-SPEC), using `surface_variant` background — same convention `.widget-mpris-player` itself used (`background: @surface_variant; border-radius: 14px;`), so the container-styling precedent for `.widget-volume`/`.widget-backlight`/`.widget-buttons-grid` is literally the block being deleted, just re-applied to new selectors.

---

### `install.sh` (add `eww` to `AUR_PKGS`, D-36)

**Analog:** itself — existing AUR_PKGS entries with a legitimacy-check comment precedent

**Pattern** (lines ~247-260, icon-themes + game-center blocks):
```bash
    # Icon themes (D-16 — human package-legitimacy checkpoint approved;
    # colloid-icon-theme-git note: the plain colloid-icon-theme name does
    # NOT exist on AUR, only the -git suffix does)
    tela-icon-theme
    colloid-icon-theme-git
    papirus-folders

    # Game center (D-33 — human package-legitimacy checkpoint approved
    # 2026-07-13). protonup-qt is AUR-only — this corrects CONTEXT.md
    # D-25's assumption that it was an official-repo package...
    heroic-games-launcher-bin
    protonup-qt
```
New entry follows the identical shape — a dated comment recording the human legitimacy-check approval, then the package name(s):
```bash
    # Media center (BAR-04/D-18/D-36 — human package-legitimacy checkpoint
    # required before install; eww is AUR-only, stable variant preferred
    # over eww-git per 08-RESEARCH.md's Package Legitimacy Audit)
    eww
```
Insert into `AUR_PKGS` (starts at line 204), NOT `PACMAN_PKGS` (line 52) — eww does not exist in official repos, confirmed via `paru -Si`/`pacman -Ss`.

---

## Shared Patterns

### Best-effort external calls (`2>/dev/null || true`)
**Source:** `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` (throughout, e.g. lines 76-79, 85, 92, 106-146)
**Apply to:** `waybar-visibility.sh`, `waybar-fullscreen-watch.sh`, `media-popup-open.sh`, `media-art-resolve.sh` — every `hyprctl`/`pkill`/`playerctl`/`eww` call that is not the script's core purpose should be guarded this way, matching the house idiom exactly.

### Atomic state-file write (temp + mv)
**Source:** `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` lines 45-52 (`_write_state`)
**Apply to:** `waybar-visibility.sh`'s per-source intent files — any concurrent-read/write state file in this codebase uses this idiom, not a bare `>`.

### Walker-dmenu exit-130-cancel
**Source:** `hypr/.config/hypr/scripts/waybar-switch.sh` lines 20-31
**Apply to:** any new script that opens a walker dmenu picker (none strictly required by this phase's file list, but relevant if the media-popup player-switcher UI is ever exposed via walker rather than eww natively — it is not, per D-20's hard boundary, so this is reference-only).

### Matugen `[templates.X]` 3-line block + no post_hook
**Source:** `matugen/.config/matugen/config.toml` (every existing block)
**Apply to:** `[templates.eww]` — new block, same shape, same "no post_hook" rule (reload ownership stays exclusively with `theme-engine/lib/reload.sh`).

### `@import url(...)` shared-file-first CSS convention
**Source:** every `style-*.css`'s lines 1-2 (`@import url("../../.local/state/theme/waybar.css"); @import url("../../.local/state/theme/waybar-font.css");`)
**Apply to:** `waybar-modules.css` (new shared module CSS, imported by each layout's stylesheet after the theme import), `waybar-visibility.css` (new owner-written idle-dim override, imported last), `eww.scss` (`@import 'eww.scss';` — SCSS-flavored version of the identical pattern, per D-19).

### `bind = <mod>, <key>, exec, <script> # <description>` keybind contract
**Source:** `hypr/.config/hypr/config/keybinds.conf` lines 60, 104 (and every other bind in the file)
**Apply to:** the new bar-toggle keybind (D-37) — mandatory trailing `# description`, no exceptions (MENU-07 cheat-sheet parser depends on it literally, per Phase 7 D-30/31/32).

### `exec-once = uwsm app -- <script-or-binary>` autostart convention
**Source:** `hypr/.config/hypr/config/autostart.conf` lines 31, 34, 41
**Apply to:** `waybar-fullscreen-watch.sh`'s new autostart line — every long-running daemon-shaped process in this repo is launched via `uwsm app --`, not raw `exec-once = <script>`.

### Rerunnable gate, not one-time checklist (`theme-doctor`/`theme-parity` shape)
**Source:** `theme-engine/.config/theme-engine/theme-doctor` (existing style-file hardcoded list at lines 195-198) and `theme-engine/.config/theme-engine/theme-parity`
**Apply to:** D-17's module-color assertion (fold into `theme-doctor`, add `style-vertical.css` as a 4th entry alongside the existing 3) and D-34's waybar-config-equivalence gate (new standalone script, same "hermetic, rerunnable, prints diff, exits nonzero on mismatch" posture as `theme-parity`).

## No Analog Found

Files with no close match in the codebase (planner should lean on `08-RESEARCH.md`'s verified findings instead):

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh` | utility/script (long-running daemon) | event-driven (Unix socket read loop) | No existing script in this repo reads a raw Unix socket / long-lived event stream — every existing script is either a one-shot action or a poll-on-interval (`custom/updates` exec-if pattern). Research's "Fullscreen Detection" section (socket2, `EVENT>>DATA` lines) is the primary source; a `while read` loop over `socat -U - UNIX-CONNECT:$SOCK` or a Python stdlib `socket` reader are the two concrete options research names — pick one and treat this as a first-of-its-kind script, following only the shared house conventions above (shebang, `set -euo pipefail`, best-effort external calls) rather than a structural analog. |
| `eww/.config/eww/eww.yuck` | component | event-driven | eww is not installed anywhere in this repo yet — genuinely the first component of its kind (D-18/D-20's own framing: "the only one that adds a new component to the theme pipeline"). Follow `08-RESEARCH.md`'s "Yuck/window basics" section (`defwindow`/`defvar`/`defpoll`/`deflisten` primitives) and `08-UI-SPEC.md`'s Interaction Contract for the popup's exact geometry/anchoring/close-semantics, not an in-repo analog. |
| `hypr/.config/hypr/scripts/media-art-resolve.sh` | utility/script | file-I/O (URL-scheme branch + cache download) | No existing script in this repo does a scheme-conditional download-or-passthrough into a hash-keyed cache directory. Closest tangential precedent is `wallpaper-picker.sh`'s general "resolve then cache" shape (worth a skim for stylistic consistency — shebang/strict-mode/best-effort idiom only), but the actual logic (checking `artUrl`'s `file://` vs `https://` scheme, `curl -sL ... -o ...` on a cache miss) has no structural sibling. Follow `08-RESEARCH.md`'s "mpris/playerctl details" section directly. |

## Metadata

**Analog search scope:** `waybar/.config/waybar/`, `hypr/.config/hypr/scripts/`, `hypr/.config/hypr/config/`, `matugen/.config/matugen/templates/` + `config.toml`, `theme-engine/.config/theme-engine/`, `swaync/.config/swaync/`, `install.sh`
**Files scanned:** ~24 (all 3 waybar configs+styles, both waybar scripts, gaming-mode-toggle.sh, hypridle.conf, keybinds.conf, autostart.conf, all matugen templates list + config.toml + waybar-colors.css content, contract.json, theme-doctor's style-list section, swaync config.json + style.css mpris block, install.sh AUR_PKGS block)
**Pattern extraction date:** 2026-07-14
