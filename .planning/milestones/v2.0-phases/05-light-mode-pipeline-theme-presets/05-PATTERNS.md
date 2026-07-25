# Phase 5: Light Mode Pipeline & Theme Presets - Pattern Map

**Mapped:** 2026-07-11
**Files analyzed:** 15 (new + modified)
**Analogs found:** 15 / 15 (all have an in-repo analog — this phase is pure extension of an existing pipeline)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `theme-engine/.config/theme-engine/lib/mode.sh` (NEW) | utility (compute) | transform | `theme-engine/.config/theme-engine/lib/gtk.sh` (`theme_engine_gtk4_accent`) | role-match (same "hex → computed classification via python3 colorsys" shape) |
| `theme-engine/.config/theme-engine/lib/gtk.sh` (MODIFIED) | middleware (signal propagation) | event-driven | itself (existing file, extend in place) | exact |
| `theme-engine/.config/theme-engine/lib/generate.sh` (MODIFIED) | service (render step) | transform | itself (existing file, extend in place) | exact |
| `theme-engine/.config/theme-engine/lib/commit.sh` (MODIFIED) | service (atomic commit) | CRUD (file write) | itself (existing file, extend in place) | exact |
| `theme-engine/.config/theme-engine/theme-apply` (MODIFIED) | controller (entrypoint) | request-response | itself (existing file, extend in place) | exact |
| `theme-engine/.config/theme-engine/theme-parity` (MODIFIED) | test (parity gate) | batch | itself (existing file, extend `TARGETS` array / dynamic enumeration) | exact |
| `theme-engine/.config/theme-engine/theme-stress-test` (MODIFIED) | test (stress harness) | batch | itself (existing file, extend `STATIC_PRESETS` array) | exact |
| `theme-engine/.config/theme-engine/contract.json` (MODIFIED) | config | CRUD | itself (existing file, append entries) | exact |
| `theme-engine/.config/theme-engine/palettes/<new-preset>.json` (14 NEW: 9 dark Omarchy lineup + 5 canonical light) | model (data) | CRUD | `theme-engine/.config/theme-engine/palettes/rosepine.json` | exact |
| `matugen/.config/matugen/templates/gtk3-settings.ini` (NEW) | config (template) | transform | `matugen/.config/matugen/templates/*` (existing gtk-colors templates — same dir, same matugen templating convention) | role-match |
| `matugen/.config/matugen/templates/fzf-colors.conf` (NEW) | config (template) | transform | same as above | role-match |
| `gtk/.config/gtk-3.0/settings.ini` (MODIFIED → becomes symlink target, removed from stow tracking) | config | CRUD (file I/O) | `commit.sh`'s existing walker/yazi symlink wiring (lines 69-78) | exact (same symlink pattern, new target) |
| `hypr/.config/hypr/scripts/wallpaper-picker.sh` (MODIFIED) | component (TUI script) | request-response + file-I/O | itself (existing file, extend in place) | exact |
| `stow.sh` (MODIFIED) | config (install script) | batch | itself (existing file — extend `PACKAGES` array removal + settings.ini symlink seed, alongside existing catppuccin seed at lines 99-105) | exact |
| `themes/.config/themes/**` (DELETE — legacy package) | — | — | n/a (deletion target, D-04) | n/a |

## Pattern Assignments

### `theme-engine/.config/theme-engine/lib/mode.sh` (NEW utility, transform)

**Analog:** `theme-engine/.config/theme-engine/lib/gtk.sh` — `theme_engine_gtk4_accent()` (lines 192-236)

**Existing hex→classification pattern to copy** (`lib/gtk.sh:198-235`):
```bash
theme_engine_gtk4_accent() {
    local colors_file="$HOME/.local/state/theme/gtk-4.0-colors.css"
    [[ -f "$colors_file" ]] || return 0
    command -v python3 >/dev/null 2>&1 || return 0

    local hex
    hex=$(grep -m1 '@define-color accent_color ' "$colors_file" 2>/dev/null | grep -oE '#[0-9a-fA-F]{6}')
    [[ -n "$hex" ]] || return 0

    local accent
    accent=$(python3 - "$hex" <<'PYEOF' 2>/dev/null
import colorsys, sys
hexv = sys.argv[1].lstrip('#')
r, g, b = (int(hexv[i:i+2], 16) / 255.0 for i in (0, 2, 4))
h, s, l = colorsys.rgb_to_hls(r, g, b)[0], colorsys.rgb_to_hls(r, g, b)[2], colorsys.rgb_to_hls(r, g, b)[1]
...
PYEOF
)
    [[ -n "$accent" ]] || return 0
    gsettings set org.gnome.desktop.interface accent-color "$accent" 2>/dev/null || true
}
```

**What to copy:** the `[[ -f ... ]] || return 0` guard style, `command -v python3` guard, `python3 - "$arg" <<'PYEOF' ... PYEOF` heredoc-with-positional-arg technique, and "never block/fail the caller" best-effort semantics (`|| true` throughout).

**New function shape** (per RESEARCH.md Pattern 1, same file-header comment style as `gtk.sh`'s top-of-file doc comment):
```bash
theme_engine_detect_mode() {
    local palette_json="$1"
    local rendered_bg_hex="$2"

    local override
    override=$(jq -r '.mode // empty' "$palette_json" 2>/dev/null)
    if [[ "$override" == "light" || "$override" == "dark" ]]; then
        echo "$override"
        return 0
    fi

    python3 - "$rendered_bg_hex" <<'PYEOF'
import colorsys, sys
hexv = sys.argv[1].lstrip('#')
r, g, b = (int(hexv[i:i+2], 16) / 255.0 for i in (0, 2, 4))
l = colorsys.rgb_to_hls(r, g, b)[1]
print("light" if l > 0.5 else "dark")
PYEOF
}
```
Must be sourced from `theme-apply` alongside `lib/generate.sh`/`lib/commit.sh`/`lib/gtk.sh`/`lib/reload.sh` (see `theme-apply` lines 21-28).

---

### `theme-engine/.config/theme-engine/lib/gtk.sh` (MODIFIED, mode-aware)

**Analog:** itself — the two hardcoded literals to replace are at lines 21 and 24:
```bash
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null || true
sleep 0.1
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null || true
```
**Pattern to follow:** keep the exact same `gsettings set ... 2>/dev/null || true` call shape (best-effort, non-blocking) but branch the two string literals (`prefer-dark`/`prefer-light`, `adw-gtk3-dark`/`adw-gtk3`) on a mode value read from the new state-dir mode marker (written by `mode.sh` via `commit.sh`, same read-pattern as `theme_engine_gtk4_accent` reads `gtk-4.0-colors.css`). Do not add a second gsettings-writing call site elsewhere — `gtk.sh` is the documented single owner (Don't-Hand-Roll table in RESEARCH.md).

---

### `theme-engine/.config/theme-engine/lib/generate.sh` (MODIFIED)

**Analog:** itself (lines 24-52) — existing `if/else` branch on `name == "materialyou"` is the exact shape to extend:
```bash
if [[ "$name" == "materialyou" ]]; then
    local wallpaper
    wallpaper=$(readlink -f "$WALLPAPER_LINK" 2>/dev/null || echo "$WALLPAPER_LINK")
    if [[ ! -f "$wallpaper" ]]; then
        echo "No wallpaper found. Use the wallpaper picker first." > "$GENERATE_LOG"
        return 1
    fi
    if ! matugen image "$wallpaper" --source-color-index 0 \
            -c "$MATUGEN_CFG" -p "$tmp" 2>"$GENERATE_LOG"; then
        return 1
    fi
else
    local palette="$PALETTES_DIR/$name.json"
    if ! matugen json "$palette" -c "$MATUGEN_CFG" -p "$tmp" 2>"$GENERATE_LOG"; then
        return 1
    fi
fi
```
**Extend to:** `[[ "$name" == "materialyou" || "$name" == "materialyou-light" ]]` sibling branch passing `-m light`/`-m dark` to `matugen image` per RESEARCH.md Pattern 2 (matugen `-m` is a no-op for the static-JSON `else` branch — do not add `-m` there, per Pitfall 1).

---

### `theme-engine/.config/theme-engine/lib/commit.sh` (MODIFIED)

**Analog:** itself (lines 69-78) — the exact symlink-wiring pattern to replicate for `settings.ini`:
```bash
local walker_dir="$HOME/.config/walker/themes/rice"
mkdir -p "$walker_dir"
ln -sf "$STATE_DIR/walker-style.css" "$walker_dir/style.css"

mkdir -p "$HOME/.config/yazi"
ln -sf "$STATE_DIR/yazi.toml" "$HOME/.config/yazi/theme.toml"
```
**Copy this exact idiom** for D-08: `mkdir -p "$HOME/.config/gtk-3.0"` then `ln -sf "$STATE_DIR/gtk-3.0-settings.ini" "$HOME/.config/gtk-3.0/settings.ini"`. Also write the computed mode value to a state-dir marker file here using the same temp-file+mv atomicity already used for `current-theme` (lines 66-67):
```bash
printf '%s\n' "$name" > "$STATE_DIR/current-theme.tmp" \
    && mv "$STATE_DIR/current-theme.tmp" "$STATE_DIR/current-theme"
```

---

### `theme-engine/.config/theme-engine/theme-apply` (MODIFIED — allowlist extension)

**Analog:** itself (lines 45-58) — Security Domain V5 allowlist check:
```bash
if [[ "$NAME" != "materialyou" ]]; then
    if [[ ! -f "$PALETTES_DIR/$NAME.json" ]]; then
        notify-send -a "Theme Switcher" "Error" \
            "Unknown theme: ${NAME}. Desktop left unchanged." \
            -i dialog-error -t 5000 2>/dev/null || true
        echo "theme-apply: unknown theme '$NAME'" >&2
        usage
        exit 1
    fi
fi
```
**Change to:** `[[ "$NAME" != "materialyou" && "$NAME" != "materialyou-light" ]]` (RESEARCH.md "Preset-name allowlist extension" code example). The `usage()` function (lines 30-36) already dynamically enumerates `palettes/*.json` — new preset JSONs are automatically listed, no further change needed there.

---

### `theme-engine/.config/theme-engine/theme-parity` / `theme-stress-test` (MODIFIED — Pitfall 2 fix)

**Analog:** itself — hardcoded arrays at `theme-parity:77` and `theme-stress-test:83`:
```bash
TARGETS=(materialyou catppuccin dracula gruvbox nord rosepine tokyonight)
STATIC_PRESETS=(catppuccin dracula gruvbox nord rosepine tokyonight)
```
**Recommended fix (per RESEARCH.md Pitfall 2):** convert both to dynamic enumeration matching `theme-apply`'s own `usage()` pattern (`theme-apply` lines 33-35):
```bash
for f in "$PALETTES_DIR"/*.json; do
    [[ -f "$f" ]] && echo "  - $(basename "$f" .json)" >&2
done
```
Apply the same `for f in "$PALETTES_DIR"/*.json; do TARGETS+=("$(basename "$f" .json)"); done` idiom, then append `materialyou` and `materialyou-light` literals. This also naturally adds a light fixture to `theme-parity` once a light preset JSON exists in `palettes/`.

---

### `theme-engine/.config/theme-engine/palettes/<new-preset>.json` (14 NEW files, model/CRUD)

**Analog:** `theme-engine/.config/theme-engine/palettes/rosepine.json` (full file, 26 lines) — the canonical 20-key schema every new preset (dark or light) must match exactly:
```json
{
  "colors": {
    "image": "",
    "primary": { "default": { "color": "#ebbcba" } },
    "on_primary": { "default": { "color": "#191724" } },
    "primary_container": { "default": { "color": "#26233a" } },
    "on_primary_container": { "default": { "color": "#e0def4" } },
    "secondary": { "default": { "color": "#f6c177" } },
    "on_secondary": { "default": { "color": "#191724" } },
    "secondary_container": { "default": { "color": "#26233a" } },
    "on_secondary_container": { "default": { "color": "#f6c177" } },
    "tertiary": { "default": { "color": "#c4a7e7" } },
    "on_tertiary": { "default": { "color": "#191724" } },
    "tertiary_container": { "default": { "color": "#65587f" } },
    "surface": { "default": { "color": "#191724" } },
    "on_surface": { "default": { "color": "#e0def4" } },
    "surface_variant": { "default": { "color": "#26233a" } },
    "on_surface_variant": { "default": { "color": "#908caa" } },
    "background": { "default": { "color": "#191724" } },
    "on_background": { "default": { "color": "#e0def4" } },
    "outline": { "default": { "color": "#524f67" } },
    "error": { "default": { "color": "#eb6f92" } },
    "on_error": { "default": { "color": "#191724" } }
  }
}
```
**For light variants specifically:** RESEARCH.md Pattern 5 — copy the dark sibling's exact key→upstream-color-name role mapping, substitute the light upstream hex values; never re-derive role assignments from scratch. Add the optional top-level `"mode": "light"` key (D-06) only where lightness auto-detection would be ambiguous — otherwise rely on background/surface auto-detection via the new `mode.sh`.

---

### `matugen/.config/matugen/templates/gtk3-settings.ini` (NEW template)

**Analog:** existing `matugen/.config/matugen/templates/` directory conventions (gtk-colors css templates) plus the current static `gtk/.config/gtk-3.0/settings.ini` (7 lines, full file shown above) — static lines to preserve verbatim per D-07 (icon/cursor/font untouched):
```ini
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Adwaita
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-font-name=FiraCode Nerd Font 11
```
**Open decision (RESEARCH.md Open Question 3):** whether the two mode-sensitive lines (`gtk-application-prefer-dark-theme`, `gtk-theme-name`) are matugen-templated or shell-patched post-render by `gtk.sh`/`commit.sh` — lean toward shell-side per the "single owner" convention already established by `gtk.sh` owning all gsettings/GTK-signal writes.

---

### `matugen/.config/matugen/templates/fzf-colors.conf` (NEW template)

**Analog:** none directly in-repo (first fzf-color render target) — pattern instead follows the existing `contract.json` structural convention (`{"name": ..., "format": ...}` entries, contract.json lines 2-13) plus the existing wallpaper-picker's own `--color=` hardcoded literals (lines 96-98) as the exact slot list to templatize:
```bash
--color="bg:-1,bg+:#313244,fg:#cdd6f4,fg+:#cba6f7,hl:#f5c2e7,hl+:#f5c2e7"
--color="info:#94e2d5,prompt:#cba6f7,pointer:#f5c2e7,marker:#f5c2e7,spinner:#94e2d5"
--color="header:#a6adc8,border:#585b70,gutter:-1"
```
Render these as shell-exportable `FZF_COLOR_*` vars per RESEARCH.md's Code Examples section (fully worked template + consumer snippet provided there) — `source` it from `wallpaper-picker.sh` with graceful `2>/dev/null || true` fallback to today's literals.

---

### `hypr/.config/hypr/scripts/wallpaper-picker.sh` (MODIFIED)

**Analog:** itself (full 147-line file, read above) — three areas change in place, same script structure kept:

1. **Preview script** (lines 44-67, heredoc `PREVIEW_SCRIPT`): replace the `chafa --size=... --symbols=block+border+space` call (line 55-60) with `kitten icat`/`chafa -f kitty` per RESEARCH.md Pattern 4 (verbatim fzf upstream `fzf-preview.sh` technique, `--clear` flag to avoid stale images).
2. **fzf `--color` args** (lines 96-98): replace hardcoded catppuccin hex literals with `source`d `$FZF_COLOR_*` vars from the new state-dir fragment (D-15).
3. **Wallpaper enumeration** (lines 29-32, `find "$WALLPAPER_DIR" -maxdepth 1 ... -printf "%f\n"`): keep this exact "enumerate real files, never trust raw interpolation" security pattern, but add per-theme subfolder scanning + fall-open logic (D-12/D-16) — same `find ... -printf "%f\n" | sort` idiom, scoped to `$WALLPAPER_DIR/$CURRENT_THEME/` first, falling back to the existing root-level scan.
4. **Post-selection re-apply** (lines 137-145): the `CURRENT_THEME=$(cat "$STATE_FILE" ...)` + `[[ "$CURRENT_THEME" == "materialyou" ]]` branch already delegates back to `theme-apply` — extend the equality check to also match `materialyou-light` (call `theme-apply materialyou-light` when that's active, not unconditionally `materialyou`), preserving the "never reimplement apply+reload here" comment at lines 132-136.

---

### `stow.sh` (MODIFIED)

**Analog:** itself (lines 90-105) — existing first-boot seed pattern:
```bash
THEME_APPLY="$HOME/.config/theme-engine/theme-apply"
if [[ -x "$THEME_APPLY" ]]; then
    "$THEME_APPLY" catppuccin || true
else
    echo "  ⚠ theme-apply not found at $THEME_APPLY — skipping seed"
fi
```
**Two changes:** (1) remove `themes` from the `PACKAGES` array (line 19 block) as part of D-04 deletion, after verifying no references (RESEARCH.md already confirms zero references via repo-wide grep); (2) the `theme-apply catppuccin` seed call already exercises `commit.sh`'s full symlink wiring including the new `gtk-3.0/settings.ini` symlink — no separate seed step needed since `commit.sh` owns that wiring (per commit.sh pattern above), just confirm `gtk/.config/gtk-3.0/settings.ini` is no longer stow-tracked so the symlink isn't clobbered by `stow`.

## Shared Patterns

### Best-effort, never-block error handling
**Source:** `theme-engine/.config/theme-engine/lib/gtk.sh` (every gsettings/notify-send call ends `2>/dev/null || true`)
**Apply to:** `mode.sh`, extended `gtk.sh` branches, `commit.sh`'s new symlink/mode-marker writes — none of these should ever fail `theme-apply`'s overall exit code for a cosmetic/best-effort step.

### Atomic temp-file + mv for state files
**Source:** `theme-engine/.config/theme-engine/lib/commit.sh` lines 66-67 (`current-theme.tmp` → `mv`)
**Apply to:** any new state-dir marker file (mode marker, last-used-wallpaper-per-theme files per D-11/Open Question 4) — never write the live file directly, always temp+rename for reader-atomicity.

### Security Domain V5 — allowlist before path interpolation
**Source:** `theme-engine/.config/theme-engine/theme-apply` lines 45-58 (validate against real `palettes/*.json` filenames before building a path)
**Apply to:** `materialyou-light` literal in `theme-apply`/`theme-parity`; new per-theme wallpaper subfolder scan in `wallpaper-picker.sh` (must stay `find ... -printf "%f\n"` filename-only enumeration, never raw interpolation of a user/fzf-selected string with `..`-traversal potential).

### Single-owner-per-concern discipline
**Source:** `reload.sh`'s header comment ("no other file may invoke reload — this is the single owner") and `gtk.sh` being the sole gsettings writer
**Apply to:** mode-writing logic must live in exactly one place (lean `gtk.sh`/`commit.sh`, not matugen templating — RESEARCH.md Open Question 3); `theme-apply` remains the sole re-apply entrypoint called by `wallpaper-picker.sh`, never duplicated.

## No Analog Found

None — every file in this phase's scope is either an in-place extension of an existing file or a new file following an already-established sibling convention in the same directory (`palettes/*.json`, `matugen/.config/matugen/templates/*`).

## Metadata

**Analog search scope:** `theme-engine/.config/theme-engine/` (full), `matugen/.config/matugen/`, `gtk/.config/gtk-{3,4}.0/`, `hypr/.config/hypr/scripts/`, `stow.sh`, `themes/.config/themes/`
**Files scanned:** 15 (theme-apply, contract.json, theme-parity, theme-stress-test, lib/{generate,commit,gtk,reload}.sh, palettes/rosepine.json + directory listing, gtk-3.0/settings.ini, wallpaper-picker.sh, stow.sh)
**Pattern extraction date:** 2026-07-11
