# Phase 9: wlogout to wleave Migration - Pattern Map

**Mapped:** 2026-07-25
**Files analyzed:** 15 (create/modify) + 1 delete-package
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|-----------------|---------------|
| `wleave/.config/wleave/layout.json` (new, replaces `wlogout/.config/wlogout/layout`) | config | CRUD (static declarative data) | `wlogout/.config/wlogout/layout` | exact (same data, new schema) |
| `wleave/.config/wleave/style.css` (new, replaces `wlogout/.config/wlogout/style.css`) | config/theming | transform (CSS `@import` + `@define-color` consumption) | `wlogout/.config/wlogout/style.css` (structure) + `ags/.config/ags/style.scss` (transparent-window/frost technique) + `waybar/.config/waybar/theme.css` (`mix()` hue derivation) | exact + role-match |
| `hypr/.config/hypr/scripts/wleave.sh` (new, replaces `wlogout.sh`) | utility (wrapper script) | request-response (spawn process) | `hypr/.config/hypr/scripts/wlogout.sh` | exact, but logic mostly deleted per research (no geometry math needed) |
| `matugen/.config/matugen/templates/wleave-colors.css` (new, replaces `wlogout-colors.css`) | config (template) | transform | `matugen/.config/matugen/templates/wlogout-colors.css` | exact |
| `matugen/.config/matugen/config.toml` (modify) | config | CRUD | itself, `[templates.wlogout]` block | exact |
| `theme-engine/.config/theme-engine/contract.json` (modify) | config | CRUD | itself, `wlogout.css` entry | exact |
| `theme-engine/.config/theme-engine/theme-doctor` (modify) | test/utility | request-response (parse-check) | itself, `GTK3_CSS_SHEETS`/`GTK4_CSS_SHEETS` arrays | exact |
| `theme-engine/.config/theme-engine/theme-stress-test` (modify) | test | batch | itself, `REPRESENTATIVE_FILES` array | exact |
| `hypr/.config/hypr/config/windowrules.conf` (modify) | config | event-driven (compositor layerrule) | itself, `logout_dialog` layerrule lines + `ags-media`/`eww-media-popup` layerrule blocks (frost/ignore_alpha precedent) | exact + role-match |
| `hypr/.config/hypr/config/keybinds.conf` (modify) | config | event-driven | itself, line 26 bind | exact |
| `waybar/.config/waybar/modules.jsonc` (modify) | config | event-driven | itself, `custom/power` module | exact |
| `waybar/.config/waybar/config-floating.jsonc` (modify) | config | event-driven | itself, `custom/power` module | exact |
| `elephant/.config/elephant/menus/main.toml` (modify) | config | event-driven | itself, Power `[[entries]]` block | exact |
| `install.sh` (modify) | config/script | batch (install) | itself, `AUR_PKGS` array line 233 | exact |
| `stow.sh` (modify) | config/script | batch (install) | itself, `PACKAGES` array line 38 | exact |
| `hypr/.config/hypr/config/autostart.conf` (modify, comment only) | config | n/a | itself, line 74 comment | exact |
| `wlogout/` stow package (delete) | — | — | n/a | n/a (deletion, not creation) |

## Pattern Assignments

### `wleave/.config/wleave/layout.json` (config, CRUD/declarative)

**Analog:** `wlogout/.config/wlogout/layout`

**Current pattern** (full file, legacy NDJSON — one JSON object per line):
```
{"label": "lock", "action": "uwsm app -- hyprlock", "text": "󰌾", "keybind": "l"}
{"label": "logout", "action": "cliphist wipe; uwsm stop", "text": "󰍃", "keybind": "e"}
{"label": "suspend", "action": "systemctl suspend", "text": "󰒲", "keybind": "u"}
{"label": "hibernate", "action": "systemctl hibernate", "text": "󰋊", "keybind": "h"}
{"label": "shutdown", "action": "cliphist wipe; hyprshutdown --post-cmd 'systemctl poweroff'", "text": "󰐥", "keybind": "s"}
{"label": "reboot", "action": "cliphist wipe; hyprshutdown --post-cmd 'systemctl reboot'", "text": "󰜉", "keybind": "r"}
```

**What carries over byte-identically (D-17):** the six `action` shell-command strings and the `keybind` letters. Order must become the D-05 severity gradient (lock, logout, suspend, hibernate, reboot, shutdown — note reboot/shutdown swapped relative to the current file's order).

**New target shape** (per RESEARCH.md Pattern 1, wleave 0.7.1 wrapped schema — verified against source at the pinned tag):
```json
{
  "buttons-per-row": "6",
  "close-on-lost-focus": false,
  "show-keybinds": false,
  "buttons": [
    { "label": "lock",      "action": "uwsm app -- hyprlock",                                      "text": "<glyph>", "keybind": "l", "height": 0.5 },
    { "label": "logout",    "action": "cliphist wipe; uwsm stop",                                   "text": "<glyph>", "keybind": "e", "height": 0.5 },
    { "label": "suspend",   "action": "systemctl suspend",                                          "text": "<glyph>", "keybind": "u", "height": 0.5 },
    { "label": "hibernate", "action": "systemctl hibernate",                                        "text": "<glyph>", "keybind": "h", "height": 0.5 },
    { "label": "reboot",    "action": "cliphist wipe; hyprshutdown --post-cmd 'systemctl reboot'",  "text": "<glyph>", "keybind": "r", "height": 0.5 },
    { "label": "shutdown",  "action": "cliphist wipe; hyprshutdown --post-cmd 'systemctl poweroff'","text": "<glyph>", "keybind": "s", "height": 0.5 }
  ]
}
```
`<glyph>` = new, cmap-verified Nerd Font codepoints (D-09) — do NOT reuse the current glyphs verbatim in the edit tool; re-verify each one with `fc-query`/cmap inspection per the Phase 6/8 discipline, then write the real UTF-8 codepoint. `"height": 0.5` is mandatory on every button (Pitfall 1 — default is 0.9, near-bottom).

---

### `wleave/.config/wleave/style.css` (config/theming, transform)

**Analogs:**
1. `wlogout/.config/wlogout/style.css` — existing structure: `@import`, `#id` selector-per-action pattern, hover/border color roles.
2. `ags/.config/ags/style.scss` lines 43-45 — the transparent-window frost prerequisite (D-01).
3. `waybar/.config/waybar/theme.css` lines 168-172 — `mix()` derived-hue technique (D-04).

**Current `@import` + window pattern** (`wlogout/.config/wlogout/style.css` lines 1-9):
```css
@import url("../../.local/state/theme/wlogout.css");

window {
    background-color: rgba(0, 0, 0, 0.45);
    font-family: "FiraCode Nerd Font";
    color: @on_surface;
}
```
**New target:** rename the imported file to `wleave.css`. Per RESEARCH.md Pattern 2/Pitfall 2, the old single `window { background-color: rgba(...) }` (D-07 scrim baked directly onto `window`) must split into two rules because GTK4's `GtkCenterBox` (wleave's content wrapper) shares the `box` CSS node name with the inner buttons row:

```css
/* transparent window (D-01) — mirrors ags/.config/ags/style.scss lines 43-45 */
window {
    background-color: transparent;
}
/* scrim on the outer CenterBox only (D-07) — direct-child combinator avoids
   also tinting the nested buttons box (Pitfall 2) */
window > box {
    background-color: rgba(0, 0, 0, 0.4);
}
```

**Transparent-window precedent** (`ags/.config/ags/style.scss` lines 35-44 — read the comment verbatim, it explains WHY this is required, not just the rule):
```scss
// GTK4 windows paint an OPAQUE theme background by default (libadwaita's
// @window_bg_color) — this was silently defeating every translucency value
// tuned below...
window {
  background-color: transparent;
}
```

**Per-action `#id` hover/border pattern** (`wlogout/.config/wlogout/style.css` lines 66-108, reusable verbatim structure — wleave sets the same widget `name` from `layout`'s `label` field per RESEARCH.md Pattern 3):
```css
#lock {
    border-color: @primary;
}
#lock:hover {
    background-color: @primary;
    color: @on_primary;
    border-color: @secondary;
}
```
Adapt per D-03: capsule background becomes the *container* role at translucent alpha (`rgba(@primary_container, ...)` is NOT valid GTK CSS syntax for named colors — use `@define-color` intermediate + `alpha()` function, or a literal rgba built from the container hex at build time via matugen if `alpha()` on a named color proves unreliable at the D-14 render check), glyph color uses `@on_primary_container` (not `@on_primary`).

**`mix()` derived-hue pattern** (`waybar/.config/waybar/theme.css` lines 168-172 — exact precedent for D-04's two extra hues beyond the four native M3 roles):
```css
/* mix() blends role colours into extra DISTINCT "the same two colours" */
@define-color vhue-purple mix(@primary, @error, 0.4);
@define-color vhue-teal mix(@secondary, @tertiary, 0.5);
```
Reuse this exact `@define-color ... mix(@a, @b, ratio);` idiom for the two derived hues needed to cover all six capsules (four native + two derived).

**Button base/hover/label pattern to adapt** (`wlogout/.config/wlogout/style.css` lines 27-63 — capsule sizing, radius, transition, and the load-bearing glyph-centering comment explaining the GTK3 vertical-centering issue; **note this specific mechanism does NOT carry to wleave** — wleave's label centering is via JSON `"height"`, per Pitfall 1, not a CSS `margin-bottom` hack):
```css
button {
    background-color: @background;
    color: @on_surface;
    border: 3px solid @outline;
    border-radius: 20px;
    min-width: 72px;
    min-height: 72px;
    padding: 10px;
    box-shadow: none;
    text-shadow: none;
    transition: all 0.3s cubic-bezier(0.55, 0, 0.28, 1.68);
}
```
Adjust dimensions to D-02 (~96px, ~20-24px radius, ~24px gaps via `margin`/`buttons-per-row` config fields, not CSS `--column-spacing` since that flag doesn't exist on wleave).

---

### `hypr/.config/hypr/scripts/wleave.sh` (utility, request-response)

**Analog:** `hypr/.config/hypr/scripts/wlogout.sh` (full file read above)

**What is explicitly NOT ported** (per RESEARCH.md's Anti-Patterns and Pitfall 3 of the current script's own comments): the `CONTENT/PAD/BORDER/GAP/COLS` outer-size derivation, the `hyprctl -j monitors | jq` focused-monitor logical-size query, `centre_margin()`, and all `--margin-*`/`--column-spacing`/`--no-span` CLI flags — wleave self-sizes via `GtkCenterBox` + config-file `margin`/`buttons-per-row`, so none of this geometry math applies to the new engine.

**What is kept (as a pattern to follow), from other capture-script guard idioms** (`command -v` guard, per D-23) — RESEARCH.md's own recommended shape is the closest available analog and should be used directly:
```bash
#!/usr/bin/env bash
set -euo pipefail

if ! command -v wleave >/dev/null 2>&1; then
    notify-send "Power menu" "wleave is not installed" -u critical
    exit 1
fi

if ! wleave & then
    notify-send "Power menu" "wleave failed to launch" -u critical
    exit 1
fi
```
**Also drop:** the `pgrep -x wlogout / pkill -x wlogout` toggle block (D-18 — open-only semantics, no toggle logic in the new script at all).

---

### `matugen/.config/matugen/templates/wleave-colors.css` (config template, transform)

**Analog:** `matugen/.config/matugen/templates/wlogout-colors.css` (full file read above, 19 lines)

**Current pattern (all 19 `@define-color` lines) — reuse verbatim as the base, then extend:**
```css
/* Auto-generated by matugen — Material You */
@define-color primary {{colors.primary.default.hex}};
@define-color on_primary {{colors.on_primary.default.hex}};
@define-color primary_container {{colors.primary_container.default.hex}};
@define-color on_primary_container {{colors.on_primary_container.default.hex}};
@define-color secondary {{colors.secondary.default.hex}};
@define-color on_secondary {{colors.on_secondary.default.hex}};
@define-color secondary_container {{colors.secondary_container.default.hex}};
@define-color on_secondary_container {{colors.on_secondary_container.default.hex}};
@define-color tertiary {{colors.tertiary.default.hex}};
@define-color on_tertiary {{colors.on_tertiary.default.hex}};
...
@define-color error {{colors.error.default.hex}};
@define-color on_error {{colors.on_error.default.hex}};
```
**Must add** (per Pitfall 5 — not yet proven to resolve in this repo, requires a dry-run verification per RESEARCH.md before committing):
```css
@define-color tertiary_container {{colors.tertiary_container.default.hex}};
@define-color on_tertiary_container {{colors.on_tertiary_container.default.hex}};
@define-color error_container {{colors.error_container.default.hex}};
@define-color on_error_container {{colors.on_error_container.default.hex}};
```

---

### `matugen/.config/matugen/config.toml` (config, CRUD)

**Analog:** itself — `[templates.wlogout]` block (lines 46-48), pattern shared by every other `[templates.*]` entry (e.g. `[templates.swaync]` lines 30-32):
```toml
# ── Wlogout colors ──────────────────────────────────
[templates.wlogout]
input_path = "~/.config/matugen/templates/wlogout-colors.css"
output_path = "~/.local/state/theme/wlogout.css"
```
**Rename to:**
```toml
# ── Wleave colors ───────────────────────────────────
[templates.wleave]
input_path = "~/.config/matugen/templates/wleave-colors.css"
output_path = "~/.local/state/theme/wleave.css"
```

---

### `theme-engine/.config/theme-engine/contract.json` (config, CRUD)

**Analog:** itself, line 7 entry, same array as `waybar.css`/`swaync.css`:
```json
{ "name": "wlogout.css", "format": "gtk-css" },
```
Rename in place to `{ "name": "wleave.css", "format": "gtk-css" }` — same position, same format, file count unchanged (D-12).

---

### `theme-engine/.config/theme-engine/theme-doctor` (test/utility, request-response)

**Analog:** itself. Current `GTK3_CSS_SHEETS`/`GTK4_CSS_SHEETS` arrays (lines ~204-217):
```bash
GTK3_CSS_SHEETS=(
    "$HOME/.config/wlogout/style.css"
    "$HOME/.config/gtk-3.0/gtk.css"
    "$HOME/.config/swaync/style.css"
)
...
GTK4_CSS_SHEETS=(
    "$HOME/.config/gtk-4.0/gtk.css"
    "$HOME/.config/swayosd/style.css"
    "$HOME/.config/walker/themes/rice/style.css"
)
```
**Change (D-16, exact move not addition):** remove the `wlogout/style.css` line from `GTK3_CSS_SHEETS`, add `"$HOME/.config/wleave/style.css"` to `GTK4_CSS_SHEETS` (wleave is GTK4, so it moves array families, not just renames in place).

---

### `theme-engine/.config/theme-engine/theme-stress-test` (test, batch)

**Analog:** itself, `REPRESENTATIVE_FILES` array (line 291):
```bash
REPRESENTATIVE_FILES=(hyprland.conf waybar.css swaync.css wlogout.css gtk-4.0-colors.css kitty.conf)
```
Rename `wlogout.css` → `wleave.css` in place (same array position).

---

### `hypr/.config/hypr/config/windowrules.conf` (config, event-driven)

**Analogs:** itself (`logout_dialog` lines) + `ags-media`/`eww-media-popup` layerrule blocks (closest role+data-flow match for a translucent, blurred, click-through-tuned layer-shell surface).

**Current wlogout layerrules** (lines 191, 230 + explanatory block 224-229):
```
layerrule = blur on, match:namespace logout_dialog
...
layerrule = ignore_alpha 0.5, match:namespace walker
...
# wlogout's scrim is a single uniform-alpha fill, so ignore_alpha acts as an
# all-or-nothing blur switch for the whole backdrop...
layerrule = ignore_alpha 0.3, match:namespace logout_dialog
```
**Analog for the ignore_alpha-tuning discipline** (`ags-media` block, lines ~200-221 — the exact "compound alpha across two layered translucent surfaces, tune ignore_alpha to stay above the composited value" reasoning that will need to be re-derived for wleave's new transparent-window + separate-scrim split, since D-01 changes wleave away from wlogout's single-fill approach):
```
layerrule = blur on, match:namespace ags-media
...
layerrule = ignore_alpha 0.25, match:namespace ags-media
```
**Change:** replace both `match:namespace logout_dialog` occurrences with `match:namespace wleave` (confirmed namespace string per RESEARCH.md's source verification). Re-tune the `ignore_alpha` threshold at the D-14 render gate against the NEW window/scrim split's composited alpha (do not just carry the old 0.3 value forward unchecked — the old value was tuned for a single-layer fill, the new design has two).

---

### `hypr/.config/hypr/config/keybinds.conf` (config, event-driven)

**Analog:** itself, line 26:
```
bind = $mainMod SHIFT, Q, exec, ~/.config/hypr/scripts/wlogout.sh # Open power menu
```
Change to `~/.config/hypr/scripts/wleave.sh`; bind combo and description text unchanged (keybind-doctor only requires a description to be present, per RESEARCH.md).

---

### `waybar/.config/waybar/modules.jsonc` (config, event-driven)

**Analog:** itself, `custom/power` module (lines ~251-257):
```jsonc
"custom/power": {
    "format": "",
    "tooltip-format": "Power Menu",
    "on-click": "~/.config/hypr/scripts/wlogout.sh"
},
```
Change `on-click` value to `~/.config/hypr/scripts/wleave.sh`.

---

### `waybar/.config/waybar/config-floating.jsonc` (config, event-driven)

**Analog:** itself, `custom/power` module (lines ~80-83):
```jsonc
"custom/power": {
    "format": " ",
    "on-click": "bash ~/.config/hypr/scripts/wlogout.sh"
},
```
Change `on-click` value to `bash ~/.config/hypr/scripts/wleave.sh`.

---

### `elephant/.config/elephant/menus/main.toml` (config, event-driven)

**Analog:** itself, Power entry (lines ~32-35):
```toml
[[entries]]
text = "  Power"
# D-19: delegates to the ONE existing power surface (same as Super+Shift+Q).
# D-09: shell script, invoked bare — never uwsm app --.
actions = { "open" = "~/.config/hypr/scripts/wlogout.sh" }
```
Change the `actions.open` value to `~/.config/hypr/scripts/wleave.sh`. **Note:** `wleave/` is a *new* stow package (unlike this file's own package, `elephant/`, which is pre-existing) — re-run stow / verify symlinks after adding the package, per the 07-05 stow-parity lesson cited in CONTEXT.md.

---

### `install.sh` (config/script, batch)

**Analog:** itself, `AUR_PKGS` array (line 233, inside the block starting at line 212, under the comment `# Logout menu (AUR-only; not in official repos)`):
```
    wlogout
```
Replace with `wleave` in the same array position/comment context — RESEARCH.md's Runtime State Inventory confirms this is `AUR_PKGS`, not `PACMAN_PKGS` (a correction to CONTEXT.md's canonical_refs line-label). D-13 requires the human package-legitimacy gate at execution time even though research pre-cleared the PKGBUILD.

---

### `stow.sh` (config/script, batch)

**Analog:** itself, `PACKAGES` array (line 38, alphabetically between `waybar`/`walker` and `yazi`):
```
    wlogout
```
Rename in place to `wleave` — alphabetical position is unchanged (`w-l-e-a-v-e` still sorts in the same slot).

---

### `hypr/.config/hypr/config/autostart.conf` (config, comment-only)

**Analog:** itself, line 74 comment:
```
# session-end wipe (wlogout logout/shutdown/reboot actions) and a manual
```
Update wording to say "wleave" — comment-only, no behavior change.

## Shared Patterns

### Transparent-window + separate-scrim frost (D-01/D-07)
**Source:** `ags/.config/ags/style.scss` lines 35-44 (`window { background-color: transparent; }` + the load-bearing comment explaining GTK4's opaque-by-default `@window_bg_color` problem)
**Apply to:** `wleave/.config/wleave/style.css` — this is the ONLY GTK4 precedent in the repo for this exact problem; wlogout (GTK3) never needed it because it painted its scrim directly on `window` with no CenterBox collision risk.
```scss
window {
  background-color: transparent;
}
```
Then scope the scrim to the outer content node only, using a direct-child combinator (`window > box`), per RESEARCH.md Pattern 2/Pitfall 2 — bare `box { }` would also catch the nested buttons row since `GtkCenterBox` and `GtkBox` share the same CSS node name in GTK4.

### `mix()` derived-hue technique (D-04)
**Source:** `waybar/.config/waybar/theme.css` lines 168-172
**Apply to:** `wleave/.config/wleave/style.css`'s two non-native hues (beyond primary/secondary/tertiary/error)
```css
@define-color vhue-purple mix(@primary, @error, 0.4);
@define-color vhue-teal mix(@secondary, @tertiary, 0.5);
```

### `[templates.*]` matugen registration
**Source:** `matugen/.config/matugen/config.toml` — every existing block (e.g. `[templates.swaync]`, `[templates.gtk3]`) follows the identical two-line `input_path`/`output_path` shape under a one-line comment header.
**Apply to:** `[templates.wleave]` replacing `[templates.wlogout]`.

### Rename-sweep discipline (honest-rename precedent)
**Source:** CONTEXT.md's own citation — Phase 5 `themes/` deletion, Phase 10-06 eww template removal.
**Apply to:** All matugen/contract.json/theme-doctor/theme-stress-test touchpoints — D-12's rename must land in the SAME commit/plan as the layout/style rewrite, not as a follow-up, to keep the `grep -rIn "wlogout"` check (D-11) meaningfully atomic.

### `command -v` launch-failure guard (D-23)
**Source:** RESEARCH.md's own derived `wleave.sh` shape (no closer existing analog script was found using this exact idiom in this repo's capture-scripts family at time of this pattern map; treat the RESEARCH.md Code Examples section as the primary source for this specific pattern since it was already derived from repo conventions).
**Apply to:** `hypr/.config/hypr/scripts/wleave.sh`.

## No Analog Found

None. All 15 create/modify files have a direct or role-matched analog in the existing codebase (the previous `wlogout` version of the same file, in most cases). The two RESEARCH.md-flagged landmines (D-22 multi-monitor, D-10 reverse-stagger exit) have no analog because they are architecturally unavailable in wleave 0.7.1, not because of missing repo precedent — see RESEARCH.md Pitfalls 3-4 for the recommended degradation path (single-monitor-only behavior; fast whole-window fade via `layerrule = animation`).

## Metadata

**Analog search scope:** `wlogout/`, `hypr/.config/hypr/scripts/`, `hypr/.config/hypr/config/`, `matugen/.config/matugen/`, `theme-engine/.config/theme-engine/`, `waybar/.config/waybar/`, `elephant/.config/elephant/menus/`, `ags/.config/ags/`, `install.sh`, `stow.sh` — all files were already exhaustively enumerated by RESEARCH.md's own Runtime State Inventory grep (`grep -rIn "wlogout" --exclude-dir=.planning --exclude-dir=.git .`, 20 matches); this pattern map read each touchpoint's current content directly rather than re-deriving the file list.
**Files scanned:** 15 target files + `ags/.config/ags/style.scss` + `waybar/.config/waybar/theme.css` (cross-cutting pattern sources)
**Pattern extraction date:** 2026-07-25
