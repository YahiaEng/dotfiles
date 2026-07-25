# Phase 6: Themed Surfaces & Utility Suite - Pattern Map

**Mapped:** 2026-07-12
**Files analyzed:** 28 (new files + edited files, per CONTEXT.md/RESEARCH.md)
**Analogs found:** 26 / 28

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `matugen/.config/matugen/templates/hyprlock-colors.conf` | config (matugen template) | transform | `matugen/.config/matugen/templates/hyprland-colors.conf` | exact |
| `matugen/.config/matugen/templates/swayosd-colors.css` | config (matugen template) | transform | `matugen/.config/matugen/templates/swaync-colors.css` | exact |
| `matugen/.config/matugen/templates/zen-userchrome.css` | config (matugen template) | transform | `matugen/.config/matugen/templates/walker-style.css` (css-literal format) | role-match |
| `matugen/.config/matugen/templates/satty-colors.toml` | config (matugen template) | transform | `matugen/.config/matugen/templates/yazi-theme.toml` (toml format) | role-match |
| `matugen/.config/matugen/config.toml` (edit — 4 new `[templates.*]` entries) | config | transform | existing `[templates.hyprland]`/`[templates.swaync]` blocks in same file | exact |
| `theme-engine/.config/theme-engine/contract.json` (edit — 13→17 `files` entries) | config | CRUD | existing entries (`hyprland.conf`, `swaync.css`) | exact |
| `hypr/.config/hypr/hyprlock.conf` (edit — `source =` line + new indicator labels) | config (DSL) | transform | itself (existing file, FIX-02 block MUST survive) | exact |
| `wlogout/.config/wlogout/layout` (edit — glyph `text`, new center-bar hints) | config (JSON-per-line) | transform | itself (existing file) | exact |
| `wlogout/.config/wlogout/style.css` (edit — center bar layout, delete icon rules) | component (GTK CSS) | transform | itself (existing file) | exact |
| `swayosd/.config/swayosd/style.css` (new stow package) | component (GTK CSS) | transform | `swaync/.config/swaync/style.css` (`@import` from state dir pattern — same shape as `wlogout/style.css`'s first line) | role-match |
| `satty/.config/satty/config.toml` (new stow package) | config | transform | rendered-file-is-the-config pattern, closest existing analog is matugen output being consumed directly (no wrapper) — see `fzf-colors.conf` sourced by `wallpaper-picker.sh` | role-match |
| `theme-engine/.config/theme-engine/lib/font.sh` (new) | utility/service | transform | `theme-engine/.config/theme-engine/lib/wallpaper.sh` (per-theme state-dir file pattern) | exact |
| `theme-engine/.config/theme-engine/lib/icon-theme.sh` (new) | utility/service | event-driven | `theme-engine/.config/theme-engine/lib/gtk.sh` (`theme_engine_gtk4_accent` — hex→nearest-enum mapping) | exact |
| `theme-engine/.config/theme-engine/lib/generate.sh` (edit — call `font.sh`/render icon-theme-name) | service | transform | itself (`theme_engine_render_gtk_settings`) | exact |
| `theme-engine/.config/theme-engine/lib/commit.sh` (edit — new `--exclude=` for font-choice/icon-theme state files) | service | CRUD | itself (`--exclude=last-wallpaper/` block) | exact |
| `theme-engine/.config/theme-engine/lib/reload.sh` (edit — swayosd restart, zen notify, papirus-folders call, waybar font `@import`) | service | event-driven | itself (existing `pkill -SIGUSR2 waybar` / `swaync-client -rs` fan-out block) | exact |
| `hypr/.config/hypr/scripts/capture-region.sh` (new) | utility (CLI) | file-I/O | `hypr/.config/hypr/scripts/screenshot.sh` (replaced) | role-match |
| `hypr/.config/hypr/scripts/capture-window.sh` (new) | utility (CLI) | file-I/O | `hypr/.config/hypr/scripts/screenshot.sh` (replaced) | role-match |
| `hypr/.config/hypr/scripts/capture-full.sh` (new) | utility (CLI) | file-I/O | `hypr/.config/hypr/scripts/screenshot.sh` (replaced) | role-match |
| `hypr/.config/hypr/scripts/record-toggle.sh` (new) | utility (CLI) | streaming | `hypr/.config/hypr/scripts/theme-switch.sh` (walker `--dmenu` exit-130-cancel pattern) | role-match |
| `hypr/.config/hypr/scripts/gif-export.sh` (new) | utility (CLI) | file-I/O | none close — new notification-action callback shape | no analog |
| `hypr/.config/hypr/scripts/emoji-picker.sh` (new) | utility (CLI) | event-driven | `hypr/.config/hypr/scripts/theme-switch.sh` (walker `--dmenu` pattern) | role-match |
| `hypr/.config/hypr/scripts/color-picker.sh` (new) | utility (CLI) | request-response | `theme-engine/.config/theme-engine/lib/reload.sh` (sanitized notify-send error pattern) | partial-match |
| `hypr/.config/hypr/scripts/clipboard-wipe.sh` (new) | utility (CLI) | CRUD | `hypr/.config/hypr/scripts/theme-switch.sh` (walker `--dmenu` confirm pattern) | role-match |
| `hypr/.config/hypr/scripts/icon-theme-picker.sh` (new) | utility (CLI) | file-I/O | `hypr/.config/hypr/scripts/wallpaper-picker.sh` (fzf-in-kitty + graphics preview) | exact |
| `hypr/.config/hypr/scripts/font-switcher.sh` (new) | utility (CLI) | file-I/O | `hypr/.config/hypr/scripts/wallpaper-picker.sh` (fzf-in-kitty + graphics preview) | exact |
| `hypr/.config/hypr/config/keybinds.conf` (edit — Print family + X/Z chords) | config | transform | itself (existing bind blocks) | exact |
| `hypr/.config/hypr/config/autostart.conf` (edit — swayosd-libinput-backend enable, cliphist `-max-items`) | config | transform | itself (existing cliphist watcher lines) | exact |
| `install.sh` (edit — PACMAN_PKGS/AUR_PKGS additions) | config | batch | itself (existing `PACMAN_PKGS`/`AUR_PKGS` arrays) | exact |
| `waybar/.config/waybar/style-{full,minimal,floating}.css` (edit — add `@import waybar-font.css`) | component (GTK CSS) | transform | itself (existing `@import url(".../waybar.css")` line) | exact |

## Pattern Assignments

### `matugen/.config/matugen/templates/hyprlock-colors.conf` (config, transform)

**Analog:** `matugen/.config/matugen/templates/hyprland-colors.conf`

**Core pattern** — `hypr-vars` format, verbatim key set to copy (source: RESEARCH.md Code Examples, corroborated against the live file):
```
$primary = rgba({{colors.primary.default.hex_stripped}}ff)
$on_primary = rgba({{colors.on_primary.default.hex_stripped}}ff)
$secondary = rgba({{colors.secondary.default.hex_stripped}}ff)
$surface = rgba({{colors.surface.default.hex_stripped}}ff)
$on_surface = rgba({{colors.on_surface.default.hex_stripped}}ff)
$tertiary = rgba({{colors.tertiary.default.hex_stripped}}ff)
$error = rgba({{colors.error.default.hex_stripped}}ff)
# ... all 19 keys used by hyprland-colors.conf today, same rgba(...ff) wrapper
```
**Registration pattern** (`matugen/.config/matugen/config.toml`, copy shape from the existing `[templates.hyprland]` block, lines 16-19):
```toml
[templates.hyprland]
input_path = "~/.config/matugen/templates/hyprland-colors.conf"
output_path = "~/.local/state/theme/hyprland.conf"
```
New block:
```toml
[templates.hyprlock]
input_path = "~/.config/matugen/templates/hyprlock-colors.conf"
output_path = "~/.local/state/theme/hyprlock.conf"
```
**contract.json entry** (copy shape from `{ "name": "hyprland.conf", "format": "hypr-vars", "exempt_keys": ["image"] }`):
```json
{ "name": "hyprlock.conf", "format": "hypr-vars" }
```

---

### `matugen/.config/matugen/templates/swayosd-colors.css` (config, transform)

**Analog:** `matugen/.config/matugen/templates/swaync-colors.css` (full file, 19 lines, gtk-css format)

**Core pattern** — copy the `@define-color` block verbatim (same 19 keys, `gtk-css` format):
```css
/* Auto-generated by matugen — Material You */
@define-color primary {{colors.primary.default.hex}};
@define-color on_primary {{colors.on_primary.default.hex}};
@define-color primary_container {{colors.primary_container.default.hex}};
@define-color on_primary_container {{colors.on_primary_container.default.hex}};
@define-color secondary {{colors.secondary.default.hex}};
@define-color on_secondary {{colors.on_secondary.default.hex}};
@define-color surface {{colors.surface.default.hex}};
@define-color on_surface {{colors.on_surface.default.hex}};
@define-color background {{colors.background.default.hex}};
@define-color error {{colors.error.default.hex}};
/* ... remaining keys identical to swaync-colors.css */
```
**contract.json entry:**
```json
{ "name": "swayosd.css", "format": "gtk-css" }
```
**Registration:**
```toml
[templates.swayosd]
input_path = "~/.config/matugen/templates/swayosd-colors.css"
output_path = "~/.local/state/theme/swayosd.css"
```
**Stow package** `swayosd/.config/swayosd/style.css` — first line copies the `wlogout/style.css` import idiom (line 1):
```css
@import url("../../.local/state/theme/swayosd.css");
```

---

### `matugen/.config/matugen/templates/satty-colors.toml` (config, transform)

**Analog:** `matugen/.config/matugen/templates/yazi-theme.toml` (toml format registration shape)

**Core pattern** (verbatim from RESEARCH.md, D-31, sourced from upstream Satty `config.toml` schema):
```toml
[color-palette]
palette = [
  "{{colors.primary.default.hex_stripped}}ff",
  "{{colors.secondary.default.hex_stripped}}ff",
  "{{colors.tertiary.default.hex_stripped}}ff",
  "{{colors.on_surface.default.hex_stripped}}ff",
  "{{colors.background.default.hex_stripped}}ff",
  "E53935ff",
  "{{colors.outline.default.hex_stripped}}ff",
]
```
**Verify at execution:** exact satty TOML key names against installed `satty --help` (0.21.1) — RESEARCH.md Assumption A1/Open Question 3.
**contract.json entry:**
```json
{ "name": "satty.toml", "format": "toml" }
```

---

### `matugen/.config/matugen/templates/zen-userchrome.css` (config, transform)

**Analog:** `matugen/.config/matugen/templates/walker-style.css` (`css-literal` format — CSS custom properties, not `@define-color`; walker-style.css is matugen's only other css-literal target)

**Registration pattern** (copy shape from `[templates.walker]`):
```toml
[templates.walker]
input_path = "~/.config/matugen/templates/walker-style.css"
output_path = "~/.local/state/theme/walker-style.css"
```
New block:
```toml
[templates.zen]
input_path = "~/.config/matugen/templates/zen-userchrome.css"
output_path = "~/.local/state/theme/zen-userchrome.css"
```
**contract.json entry:**
```json
{ "name": "zen-userchrome.css", "format": "css-literal" }
```
Chrome-colors-only selectors (toolbar/tabs/sidebar/URL bar) per D-27 — no existing analog for Firefox-family selector scoping in this repo; author fresh against upstream `userChrome.css` conventions, palette values still come from the standard `{{colors.X.default.hex}}` substitution shown above.

---

### `theme-engine/.config/theme-engine/lib/font.sh` (new, utility/service, transform)

**Analog:** `theme-engine/.config/theme-engine/lib/wallpaper.sh` (per-theme state-dir file, excluded from `commit.sh --delete`)

**Core pattern** (verbatim from RESEARCH.md Pattern 1, the authoritative shape to implement):
```bash
theme_engine_render_font_files() {
    local tmp="$1"
    local font_state="$HOME/.local/state/theme/font-choice"
    local font_name
    font_name="$(cat "$font_state" 2>/dev/null || echo "FiraCode Nerd Font")"

    local out_dir="$tmp$STATE_DIR"
    mkdir -p "$out_dir"

    printf 'font_family      %s\nbold_font        %s Bold\nitalic_font      %s Italic\nbold_italic_font %s Bold Italic\n' \
        "$font_name" "$font_name" "$font_name" "$font_name" > "$out_dir/kitty-font.conf"
}
```
**Called from `generate.sh`** alongside the existing `theme_engine_render_gtk_settings "$mode" "$tmp"` call (`generate.sh` line ~76) — same call-site shape, add `theme_engine_render_font_files "$tmp"` right after it.
**GTK font-name key**: fold into the EXISTING `theme_engine_render_gtk_settings` printf calls in `generate.sh` (lines ~106-112) rather than a separate write — replace the hardcoded `gtk-font-name=FiraCode Nerd Font 11` literal with the state-read `$font_name 11`.

---

### `theme-engine/.config/theme-engine/lib/icon-theme.sh` (new, utility/service, event-driven)

**Analog:** `theme-engine/.config/theme-engine/lib/gtk.sh` function `theme_engine_gtk4_accent` (hex→nearest-fixed-enum mapping, "Don't Hand-Roll" table entry) — full function read, lines ~180-215 of `gtk.sh`.

**Core pattern to adapt** (nearest-hue-bucket dispatch shape):
```bash
theme_engine_gtk4_accent() {
    local colors_file="$HOME/.local/state/theme/gtk-4.0-colors.css"
    [[ -f "$colors_file" ]] || return 0
    command -v python3 >/dev/null 2>&1 || return 0
    local hex
    hex=$(grep -m1 '@define-color accent_color ' "$colors_file" 2>/dev/null | grep -oE '#[0-9a-fA-F]{6}')
    [[ -n "$hex" ]] || return 0
    local accent
    accent=$(python3 - "$hex" <<'PYEOF'
import colorsys, sys
# ... hue bucket dispatch, deg thresholds -> named enum
PYEOF
)
    [[ -n "$accent" ]] || return 0
    gsettings set org.gnome.desktop.interface accent-color "$accent" 2>/dev/null || true
}
```
Adapt to: `papirus-folders -C <nearest-named-color> -t <ThemeVariant>` for Papirus (D-17, fixed enumeration: `black, blue, breeze, ... yellow` + `cat-*`), and a Tela/Colloid-specific "nearest full-theme-name swap" branch (Pitfall 3 — architecturally different, NOT a folder-recolor call; do `gsettings set org.gnome.desktop.interface icon-theme "Tela-<name>"` instead).
**Icon-theme state must be read inside `theme_engine_render_gtk_settings`** (Pitfall 6) — same function in `generate.sh`, add a `cat icon-theme-state || echo "Adwaita"` line, never a bare standalone `gsettings set` from the picker script.

---

### `hypr/.config/hypr/scripts/icon-theme-picker.sh` / `font-switcher.sh` (new, utility CLI, file-I/O)

**Analog:** `hypr/.config/hypr/scripts/wallpaper-picker.sh` (full file read — 230 lines)

**Imports/sourcing pattern** (lines 1-30):
```bash
#!/usr/bin/env bash
set -euo pipefail
STATE_FILE="$HOME/.local/state/theme/current-theme"
# shellcheck source=/dev/null
source "$HOME/.local/state/theme/fzf-colors.conf" 2>/dev/null || true
```
**Enumeration pattern** (Security Domain V5 — validate via `find -printf`, never trust raw interpolation; lines ~65-110): copy the `mktemp` heredoc-script idiom used for `ENUM_SCRIPT`/`PREVIEW_SCRIPT` — write a small standalone bash script to `/tmp` via `mktemp`, interpolate only the safe constant paths via `printf '%q'`, keep the body in a quoted heredoc.
**fzf invocation pattern** (lines ~200-215) — copy directly, swap `--preview` script body for icon-grid (`kitten icat` on a rendered icon-set PNG) or font specimen (pangram + code sample rendered via `kitty +kitten icat` or a generated image):
```bash
SELECTED=$(echo "$ITEMS" | fzf \
    --preview "$PREVIEW_SCRIPT {}" \
    --preview-window "right,60%,border-left" \
    --header "$HEADER" --header-first \
    --prompt "  " --pointer "▶" --marker "●" \
    --color="bg:${FZF_COLOR_BG:--1},bg+:${FZF_COLOR_BG_PLUS:-#313244},fg:${FZF_COLOR_FG:-#cdd6f4},..." \
    --border rounded --margin 1,2 --padding 1 --no-scrollbar --cycle --reverse) || true
```
**Cancel handling** (lines ~218-228): copy the `[[ -z "$SELECTED" ]]` → restore-and-exit-0 branch verbatim; **Post-selection**: write the state file (font-choice / icon-theme), then re-run `~/.config/theme-engine/theme-apply "$CURRENT_THEME"` exactly like wallpaper-picker.sh's dynamic-mode branch (line ~220) — never a bare `gsettings set`.
**Validation pattern** (Security Domain V5, lines ~205-213): re-validate the fzf-returned entry resolves to a real, existing file/name before any path/gsettings use — copy the `[[ ! -f "$FULL_PATH" ]]` defense-in-depth check verbatim, adapted to enumerated font-family/icon-theme names.

---

### `hypr/.config/hypr/scripts/record-toggle.sh` / `emoji-picker.sh` / `clipboard-wipe.sh` (new, utility CLI)

**Analog:** `hypr/.config/hypr/scripts/theme-switch.sh` (walker `--dmenu` exit-130-cancel pattern, lines 46-56)

**Core pattern** — exact exit-code-130 cancel handling (D-06 explicitly requires reuse):
```bash
# an empty line) are exit status 130 with NO stdout — never exit 0 +
# ...
SELECTED=$(printf '%s\n' "${DISPLAYS[@]}" | walker --dmenu --placeholder "Select Theme") || rc=$?
if (( rc == 130 )); then
    exit 0   # user cancelled — silent no-op, same convention record-toggle/emoji/clipboard must follow
fi
```
Adapt: `emoji-picker.sh` swaps `--dmenu` args for `-s symbols` (elephant-symbols provider, D-21) and pipes selection to `wtype "$EMOJI"` + `wl-copy` (RESEARCH.md Code Examples has the full script — copy verbatim, flagged for a live-format verification spike per Assumption A3). `record-toggle.sh` swaps the walker prompt for the silent/desktop-audio/desktop+mic 3-option picker (D-06) before invoking `gpu-screen-recorder` (RESEARCH.md Pattern 5, Omarchy-sourced).

---

### `theme-engine/.config/theme-engine/lib/commit.sh` (edit — new excludes)

**Analog:** itself — the existing `--exclude=last-wallpaper/` block (lines ~44-61, full rationale comment block read)

**Core pattern** to extend (copy the exact `rsync` flag-add convention used for `last-wallpaper/`/`current-theme`):
```bash
rsync -a --delete --exclude=logs/ --exclude=last-wallpaper/ \
    --exclude=current-theme --exclude=.last-render-error.log \
    "$rendered_dir"/ "$STATE_DIR"/
```
Add `--exclude=font-choice --exclude=icon-theme` to this same line — same engine-owned-root-level-file class as `current-theme` (WR-02/CR-01 bug class already fixed twice; do not repeat by omission).

---

### `theme-engine/.config/theme-engine/lib/reload.sh` (edit — swayosd/zen/papirus-folders/waybar-font fan-out)

**Analog:** itself — the existing fan-out block (lines 40-48)

**Core pattern** to extend (copy the exact idiom: `pkill -SIGUSR2`/guarded `pgrep -x` + `timeout N <client> <flag>`):
```bash
pkill -SIGUSR2 waybar 2>/dev/null || true
pkill -SIGUSR1 kitty 2>/dev/null || true
if pgrep -x swaync >/dev/null 2>&1; then
    timeout 5 swaync-client -rs >/dev/null 2>&1 || true
fi
```
Add analogous guarded blocks: `if pgrep -x swayosd-server >/dev/null 2>&1; then systemctl --user restart swayosd-libinput-backend.service 2>/dev/null || true; fi` (style CSS reloads live on next OSD trigger, no explicit reload call needed per swayosd's own CSS-on-launch model — verify); Zen: `pgrep -x zen-bin >/dev/null 2>&1 && notify-send -a "Zen" "Restart Zen to apply theme" ...` (D-28 notify-only, never kill); papirus-folders accent call (from `icon-theme.sh`); all wrapped in the file's documented **headless guard** convention (top-of-file comment, lines 15-24) — copy that guard shape verbatim for every new fan-out addition so the container gate stays green.

---

### `wlogout/.config/wlogout/layout` + `style.css` (edit)

**Analog:** itself (both files read in full — 30 lines JSON-per-line, 108 lines CSS)

**Layout `text` field is a real GTK label** (RESEARCH.md Pattern 3, confirmed against upstream `ArtsyMacaw/wlogout` README) — swap each `"text": "Lock"` etc. for a Nerd Font glyph codepoint (exact codepoints Claude's discretion at execution, verify via `fc-list | grep NerdFont`, do not copy an unverified codepoint).
**CSS `@import` line 1 stays unchanged** (`@import url("../../.local/state/theme/wlogout.css");`) — no contract.json change, this is an edit to the existing `wlogout.css` target, NOT a new entry (Pitfall 1 resolution).
**Delete**: every `#<id> { background-image: url("icons/....svg"); }` rule (e.g. `#lock { background-image: ... }`, lines 45-90) — replace with `button label { font-family: "FiraCode Nerd Font"; font-size: 28px; }` (RESEARCH.md Pattern 3) plus the center-bar layout rules on `window`/`button` (D-09 — author fresh, no existing center-bar analog in this repo; base structure keeps the existing `button:hover`/`button:focus` transition block, lines 20-35, unchanged).

---

### `hypr/.config/hypr/hyprlock.conf` (edit)

**Analog:** itself (full file read, 110 lines)

**MUST preserve verbatim** — the `general { }` block (`immediate_render`, `ignore_empty_input`) and every `check_text`/`fail_text`/`fail_color` key in the `input-field { }` block (FIX-02 hardening, lines 18-24 and 95-105) — D-14 launch requirement.
**Source line swap** (line 5): `source = ~/.local/state/theme/hyprland.conf` → `source = ~/.local/state/theme/hyprlock.conf` (D-30 decoupling).
**New `label {}` blocks for avatar/now-playing/battery/capslock/failed-attempts** — copy the exact block shape from the existing Time/Date/Greeting labels (lines 59-84: `monitor =`, `text = cmd[update:N] ...`, `color = $var`, `font_size`, `position`, `halign`/`valign`, `shadow_passes`/`shadow_size`) for each new indicator; `now-playing` and `failed-attempts` need `cmd[update:N]` polling scripts (author fresh, one-shot CLI wrapping `playerctl metadata`/hyprlock's own fail-counter exposure — no existing analog).

## Shared Patterns

### Walker `--dmenu` exit-130 cancel handling
**Source:** `hypr/.config/hypr/scripts/theme-switch.sh` lines 46-56
**Apply to:** `record-toggle.sh` (audio picker, D-06), `emoji-picker.sh` (D-21), any new dmenu-based utility flow
```bash
SELECTED=$(... | walker --dmenu --placeholder "...") || rc=$?
if (( rc == 130 )); then
    exit 0
fi
```

### fzf-in-floating-kitty with kitty-graphics preview
**Source:** `hypr/.config/hypr/scripts/wallpaper-picker.sh` (full file — enum-script/preview-script `mktemp` + heredoc pattern, `kitten icat` primary / `chafa --format=kitty` fallback / block-symbols last resort)
**Apply to:** `icon-theme-picker.sh`, `font-switcher.sh` (D-20 explicitly locks this as the pattern to replicate, NOT walker dmenu)

### Rendered-file + state-dir + atomic commit
**Source:** `theme-engine/.config/theme-engine/lib/generate.sh` + `commit.sh` (full files read)
**Apply to:** every new matugen template target (`hyprlock`, `swayosd`, `zen`, `satty`) — render into `$tmp$STATE_DIR` first, `commit.sh`'s single `rsync -a --delete` moves atomically only after full render success; independent state axes (font-choice, icon-theme) get `--exclude=` entries, never live inside the rendered tree.

### Headless-safe reload fan-out
**Source:** `theme-engine/.config/theme-engine/lib/reload.sh` lines 15-48 (guard comment block + `pgrep -x <proc> >/dev/null 2>&1 &&` gating before every client call)
**Apply to:** swayosd restart, Zen notify, papirus-folders invocation — each must no-op cleanly under the container verify gate (no live Wayland session).

### Sanitized error → notify-send truncation
**Source:** referenced in RESEARCH.md Security Domain (theme-apply's own error path — `head -c 200 | tr -d '\000-\011\013\014\016-\037'`)
**Apply to:** any new script surfacing subprocess stderr (satty/hyprshot/ffmpeg/ddcutil) in a `notify-send` call — never pipe raw stderr in.

### GTK settings.ini mode-aware printf render
**Source:** `theme-engine/.config/theme-engine/lib/generate.sh` function `theme_engine_render_gtk_settings` (full function, ~25 lines)
**Apply to:** icon-theme-name and gtk-font-name keys — fold new state reads into this SAME function/printf call, never a second parallel settings.ini writer (Pitfall 6).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `hypr/.config/hypr/scripts/gif-export.sh` | utility (CLI) | file-I/O | No existing notification-action-callback script in this repo; ffmpeg palette-pass is new territory. Use RESEARCH.md's cited Omarchy `finalize_recording()` shape and standard two-pass palettegen/paletteuse ffmpeg idiom as the reference instead of a codebase analog. |
| `hypr/.config/hypr/scripts/color-picker.sh` (hyprpicker wrapper) | utility (CLI) | request-response | No existing hyprpicker integration; closest is the sanitized-notify pattern (Shared Patterns above), not a full script analog — author fresh, short (~10 lines). |
| Zen `userChrome.css` selector authoring + `installs.ini`/`profiles.ini` self-heal logic (theme-apply integration point) | service | file-I/O | No Firefox-family profile-resolution code exists anywhere in this repo; RESEARCH.md Pitfall 4/5 and Code Examples are the only guidance — treat as genuinely new engineering, not a pattern-copy task. |

## Metadata

**Analog search scope:** `hypr/.config/hypr/scripts/`, `theme-engine/.config/theme-engine/lib/`, `matugen/.config/matugen/templates/` + `config.toml`, `wlogout/.config/wlogout/`, `hypr/.config/hypr/hyprlock.conf`, `swaync/.config/swaync/`
**Files scanned:** 06-CONTEXT.md, 06-RESEARCH.md (full), contract.json, matugen/config.toml, all templates/, wlogout layout+style.css, hyprlock.conf, theme-engine lib/{generate,commit,reload,gtk,wallpaper}.sh, hypr/scripts/{wallpaper-picker,theme-switch}.sh
**Pattern extraction date:** 2026-07-12
