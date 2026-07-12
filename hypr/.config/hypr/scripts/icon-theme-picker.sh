#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║   ICON THEME PICKER — fzf + kitty graphics + gtk.sh   ║
# ║                                                        ║
# ║  D-20: fzf-in-floating-kitty with a rich icon-grid     ║
# ║  preview — the SAME pattern as wallpaper-picker.sh,    ║
# ║  not the walker dmenu picker pattern (Pitfall 6        ║
# ║  mandates a real state read/re-render, never a bare    ║
# ║  gsettings set).                                       ║
# ║                                                        ║
# ║  Left pane:  installed icon themes, fzf fuzzy search   ║
# ║  Right pane: montage icon-grid preview (kitten icat)   ║
# ║                                                        ║
# ║  Enter = confirm selection (writes state + re-applies) ║
# ║  Esc/q = cancel, no changes made                        ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

ICON_STATE="$HOME/.local/state/theme/icon-theme"
CURRENT_THEME_FILE="$HOME/.local/state/theme/current-theme"
ACTIVE_MARKER=" ●"

# ── Pipeline-themed fzf colors (THM-04/D-15) ─────────
# Best-effort source of the engine-rendered fragment — the current
# catppuccin-mocha hex values survive only as ${VAR:-fallback} defaults
# below (fresh-install graceful degradation before the first theme-apply).
# shellcheck source=/dev/null
source "$HOME/.local/state/theme/fzf-colors.conf" 2>/dev/null || true

ACTIVE_ICON=$(cat "$ICON_STATE" 2>/dev/null || echo "Adwaita")

# ── Enumeration script (Security Domain V5) ──────────
# Real installed icon themes only, via a directory scan for index.theme
# files carrying a non-empty Directories= key (excludes cursor themes
# like Bibata, which have no Directories= key, and the non-selectable
# hicolor/default fallback buckets) — never trust raw interpolation, same
# discipline as wallpaper-picker.sh's ENUM_SCRIPT/lib/wallpaper.sh.
ENUM_SCRIPT=$(mktemp /tmp/icon-enum-XXXXXX.sh)
printf '#!/usr/bin/env bash\nACTIVE_MARKER=%q\n' "$ACTIVE_MARKER" > "$ENUM_SCRIPT"
cat >> "$ENUM_SCRIPT" << 'ENUM'
ACTIVE="$1"
declare -A seen
for base in /usr/share/icons "$HOME/.local/share/icons"; do
    [[ -d "$base" ]] || continue
    for dir in "$base"/*/; do
        [[ -d "$dir" ]] || continue
        name=$(basename "$dir")
        [[ -n "${seen[$name]:-}" ]] && continue
        [[ "$name" == "hicolor" || "$name" == "default" ]] && continue
        idx="$dir/index.theme"
        [[ -f "$idx" ]] || continue
        dirs_line=$(grep -m1 '^Directories=' "$idx" 2>/dev/null)
        [[ -n "$dirs_line" ]] || continue
        seen[$name]=1
        if [[ "$name" == "$ACTIVE" ]]; then
            printf '%s%s\n' "$name" "$ACTIVE_MARKER"
        else
            printf '%s\n' "$name"
        fi
    done
done | sort
ENUM
chmod +x "$ENUM_SCRIPT"

THEMES=$("$ENUM_SCRIPT" "$ACTIVE_ICON")
THEME_COUNT=$(printf '%s\n' "$THEMES" | grep -c . || true)

# ── Empty state (UI-SPEC Copywriting): only Adwaita installed ────────
if [[ "$THEME_COUNT" -le 1 ]]; then
    rm -f "$ENUM_SCRIPT"
    echo "No extra icon themes installed"
    echo "Run install.sh to add Papirus, Tela, or Colloid."
    echo ""
    echo "Press any key to exit..."
    read -rn1
    exit 0
fi

# ── Preview script (montage icon-grid + kitten icat) ──────────────────
# Renders a small grid of representative icons from the previewed theme
# via ImageMagick `montage` (available on this system: magick/convert/
# rsvg-convert), then displays it with the exact same fzf upstream
# kitten-icat idiom wallpaper-picker.sh uses (RESEARCH Pattern 4) — chafa
# --format=kitty / block-symbols are the same two-tier fallback.
PREVIEW_SCRIPT=$(mktemp /tmp/icon-preview-XXXXXX.sh)
CACHE_DIR=$(mktemp -d /tmp/icon-preview-cache-XXXXXX)
printf '#!/usr/bin/env bash\nCACHE_DIR=%q\n' "$CACHE_DIR" > "$PREVIEW_SCRIPT"
cat >> "$PREVIEW_SCRIPT" << 'PREVIEW'
ENTRY="$1"
ENTRY="${ENTRY% ●}"

THEME_DIR=""
for base in /usr/share/icons "$HOME/.local/share/icons"; do
    if [[ -d "$base/$ENTRY" ]]; then
        THEME_DIR="$base/$ENTRY"
        break
    fi
done
[[ -z "$THEME_DIR" ]] && exit 0

COLS=${FZF_PREVIEW_COLUMNS:-40}
LINES=${FZF_PREVIEW_LINES:-20}
IMG_LINES=$((LINES - 2))
[[ $IMG_LINES -lt 1 ]] && IMG_LINES=1

GRID_PNG="$CACHE_DIR/${ENTRY}.png"
if [[ ! -f "$GRID_PNG" ]] && command -v montage &>/dev/null; then
    # Prefer a curated set of near-universal freedesktop icon names so the
    # grid is recognizable (folder/home/apps/mimetypes) rather than
    # whatever sorts first alphabetically. Every candidate is validated as
    # an existing file before use (Security Domain V5 — real files only).
    NAMES=(folder user-home network-server drive-harddisk applications-system utilities-terminal text-x-generic image-x-generic audio-x-generic video-x-generic package-x-generic preferences-system)
    ICONS=()
    for n in "${NAMES[@]}"; do
        f=$(find "$THEME_DIR" -type f \( -iname "${n}.svg" -o -iname "${n}.png" \) -path "*48x48*" 2>/dev/null | head -1)
        [[ -z "$f" ]] && f=$(find "$THEME_DIR" -type f \( -iname "${n}.svg" -o -iname "${n}.png" \) 2>/dev/null | head -1)
        [[ -n "$f" ]] && ICONS+=("$f")
    done
    if [[ ${#ICONS[@]} -lt 4 ]]; then
        mapfile -t ICONS < <(find "$THEME_DIR" -type f \( -iname "*.svg" -o -iname "*.png" \) -path "*/48x48/apps/*" 2>/dev/null | sort | head -12)
    fi
    if [[ ${#ICONS[@]} -gt 0 ]]; then
        montage "${ICONS[@]}" -tile 4x3 -geometry 48x48+4+4 -background none "$GRID_PNG" 2>/dev/null || true
    fi
fi

if [[ -f "$GRID_PNG" ]]; then
    if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten &>/dev/null; then
        kitten icat --clear --transfer-mode=memory --unicode-placeholder \
            --stdin=no --place="${COLS}x${IMG_LINES}@0x0" "$GRID_PNG" 2>/dev/null \
            | sed '$d' | sed $'$s/$/\e[m/'
    elif command -v chafa &>/dev/null && chafa --help 2>/dev/null | grep -q 'kitty'; then
        chafa --format=kitty --size="${COLS}x${IMG_LINES}" \
              --animate=off --center=on \
              "$GRID_PNG" 2>/dev/null
    else
        chafa --size="${COLS}x${IMG_LINES}" \
              --animate=off --center=on \
              --color-space=din99d \
              --symbols=block+border+space \
              "$GRID_PNG" 2>/dev/null
    fi
fi

echo ""
ACTIVE_MARK=""
[[ -f "$HOME/.local/state/theme/icon-theme" ]] && \
    [[ "$(cat "$HOME/.local/state/theme/icon-theme" 2>/dev/null)" == "$ENTRY" ]] && \
    ACTIVE_MARK="  │  ● active"
echo -e " \e[1m$ENTRY\e[0m${ACTIVE_MARK}"
PREVIEW
chmod +x "$PREVIEW_SCRIPT"

# ── Run fzf ──────────────────────────────────────────
HEADER=" 🎨 Icon Theme Picker  │  ↑↓ browse  │  Enter confirm  │  Esc cancel"
SELECTED=$(echo "$THEMES" | fzf \
    --preview "$PREVIEW_SCRIPT {}" \
    --preview-window "right,60%,border-left" \
    --header "$HEADER" \
    --header-first \
    --prompt "  " \
    --pointer "▶" \
    --marker "●" \
    --color="bg:${FZF_COLOR_BG:--1},bg+:${FZF_COLOR_BG_PLUS:-#313244},fg:${FZF_COLOR_FG:-#cdd6f4},fg+:${FZF_COLOR_FG_PLUS:-#cba6f7},hl:${FZF_COLOR_HL:-#f5c2e7},hl+:${FZF_COLOR_HL_PLUS:-#f5c2e7}" \
    --color="info:${FZF_COLOR_INFO:-#94e2d5},prompt:${FZF_COLOR_PROMPT:-#cba6f7},pointer:${FZF_COLOR_POINTER:-#f5c2e7},marker:${FZF_COLOR_MARKER:-#f5c2e7},spinner:${FZF_COLOR_SPINNER:-#94e2d5}" \
    --color="header:${FZF_COLOR_HEADER:-#a6adc8},border:${FZF_COLOR_BORDER:-#585b70},gutter:-1" \
    --border rounded \
    --margin 1,2 \
    --padding 1 \
    --no-scrollbar \
    --cycle \
    --reverse) || true

# ── Cleanup ──────────────────────────────────────────
rm -f "$PREVIEW_SCRIPT" "$ENUM_SCRIPT"
rm -rf "$CACHE_DIR"

# ── Handle cancellation ───────────────────────────────
if [[ -z "$SELECTED" ]]; then
    exit 0
fi

# Strip the active-theme marker suffix before any use (same discipline as
# wallpaper-picker.sh).
SELECTED="${SELECTED% ●}"

# ── Validate against the real enumerated set (Security Domain V5 /
# T-06-12) — defense in depth: the fzf return must resolve to one of the
# entries the enumeration script actually found, never free text, before
# any gsettings/path use. ────────────────────────────────────────────
VALID=0
while IFS= read -r entry; do
    entry="${entry% ●}"
    [[ "$entry" == "$SELECTED" ]] && { VALID=1; break; }
done <<< "$THEMES"

if [[ "$VALID" -ne 1 ]]; then
    echo "icon-theme-picker: selected entry did not resolve to an enumerated icon theme: $SELECTED" >&2
    exit 1
fi

# ── Persist as a theme-orthogonal state axis (Pitfall 6/D-19) ────────
# Never a bare standalone `gsettings set` here — write the state file and
# re-run theme-apply so generate.sh's render_gtk_settings and gtk.sh's
# theme_engine_apply_icon_theme own the actual write (same discipline as
# wallpaper-picker.sh's post-selection theme-apply re-run, D-05/D-11/D-20).
mkdir -p "$(dirname "$ICON_STATE")"
printf '%s\n' "$SELECTED" > "$ICON_STATE.tmp" && mv "$ICON_STATE.tmp" "$ICON_STATE"

ACTIVE_PRESET=$(cat "$CURRENT_THEME_FILE" 2>/dev/null || echo "")
if [[ -n "$ACTIVE_PRESET" ]]; then
    ~/.config/theme-engine/theme-apply "$ACTIVE_PRESET"
else
    echo "icon-theme-picker: no active theme recorded yet — icon-theme state saved, will apply on the next theme-apply run" >&2
fi

notify-send -a "Icon Theme" "Icon Theme Changed" \
    "Applied $SELECTED" \
    -i preferences-desktop-icons -t 2000 2>/dev/null || true
