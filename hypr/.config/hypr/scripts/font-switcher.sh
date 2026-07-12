#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║   NERD FONT SWITCHER — fzf + kitty graphics + font.sh  ║
# ║                                                        ║
# ║  D-20: fzf-in-floating-kitty with a live rendered      ║
# ║  specimen — the SAME pattern as wallpaper-picker.sh/   ║
# ║  icon-theme-picker.sh, NOT the walker dmenu picker.    ║
# ║                                                        ║
# ║  Left pane:  installed nerd fonts, fzf fuzzy search    ║
# ║  Right pane: live specimen (pangram + code sample +    ║
# ║              Nerd Font glyphs) rendered IN the font    ║
# ║                                                        ║
# ║  Enter = confirm selection (writes state + re-applies) ║
# ║  Esc/q = cancel, no changes made                       ║
# ╚══════════════════════════════════════════════════════╝
#
# UTIL-05/D-18/D-19: font choice is a theme-orthogonal state axis (same
# discipline as icon-theme-picker.sh/D-19's icon-theme axis) — this script
# WRITES the font-choice state file and re-runs theme-apply so lib/font.sh
# (kitty-font.conf/waybar-font.css) and generate.sh's gtk-font-name read
# own the actual render, never a bare one-off write to any surface.

set -euo pipefail

FONT_STATE="$HOME/.local/state/theme/font-choice"
CURRENT_THEME_FILE="$HOME/.local/state/theme/current-theme"
VSCODIUM_SETTINGS="$HOME/.config/VSCodium/User/settings.json"
ACTIVE_MARKER=" ●"

# ── Pipeline-themed fzf colors (THM-04/D-15) ─────────
# shellcheck source=/dev/null
source "$HOME/.local/state/theme/fzf-colors.conf" 2>/dev/null || true

ACTIVE_FONT=$(cat "$FONT_STATE" 2>/dev/null || echo "FiraCode Nerd Font")

# ── Enumeration script (D-18, Security Domain V5) ────
# Real installed nerd-font families only, via `fc-list : family` — never a
# hardcoded list. `cut -d',' -f1` collapses fontconfig's alias-grouped
# lines (e.g. "FiraCode Nerd Font,FiraCode Nerd Font Light") down to one
# entry per distinct family. "Symbols Nerd Font" is excluded (Rule 2
# defensive filter): it is the glyph-only supplemental font shipped by
# ttf-nerd-fonts-symbols with no letterforms — selecting it as a text/code
# font would render every surface as tofu, an obviously broken choice no
# user would intentionally want from this picker.
ENUM_SCRIPT=$(mktemp /tmp/font-enum-XXXXXX.sh)
printf '#!/usr/bin/env bash\nACTIVE_MARKER=%q\n' "$ACTIVE_MARKER" > "$ENUM_SCRIPT"
cat >> "$ENUM_SCRIPT" << 'ENUM'
ACTIVE="$1"
fc-list : family 2>/dev/null | cut -d',' -f1 | grep -i 'nerd' \
    | grep -vx 'Symbols Nerd Font' | sort -u | while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    if [[ "$name" == "$ACTIVE" ]]; then
        printf '%s%s\n' "$name" "$ACTIVE_MARKER"
    else
        printf '%s\n' "$name"
    fi
done
ENUM
chmod +x "$ENUM_SCRIPT"

FONTS=$("$ENUM_SCRIPT" "$ACTIVE_FONT")
FONT_COUNT=$(printf '%s\n' "$FONTS" | grep -c . || true)

# ── Empty state (UI-SPEC Copywriting Contract) ───────
# Should not occur given D-18's bundled 7-font floor (FiraCode/FiraMono
# already installed plus the 5-pack from install.sh) — defensive copy only.
if [[ "$FONT_COUNT" -eq 0 ]]; then
    rm -f "$ENUM_SCRIPT"
    echo "No nerd fonts detected — reinstall via install.sh"
    echo ""
    echo "Press any key to exit..."
    read -rn1
    exit 0
fi

# ── Preview script (live rendered specimen) ──────────
# Pangram + code sample + representative Nerd Font glyphs, rendered IN the
# previewed family via ImageMagick (`fc-match -f '%{file}'` resolves the
# family name to its actual font file — IM's own `-font` type-name lookup
# only recognizes its internal type.xml aliases, not fontconfig family
# names, so the file-path indirection is required), then displayed with
# the exact same fzf-upstream kitten-icat idiom wallpaper-picker.sh/
# icon-theme-picker.sh use (RESEARCH Pattern 4) — chafa --format=kitty /
# block-symbols are the same two-tier fallback.
PREVIEW_SCRIPT=$(mktemp /tmp/font-preview-XXXXXX.sh)
CACHE_DIR=$(mktemp -d /tmp/font-preview-cache-XXXXXX)
printf '#!/usr/bin/env bash\nCACHE_DIR=%q\nFG=%q\n' "$CACHE_DIR" "${FZF_COLOR_FG:-#cdd6f4}" > "$PREVIEW_SCRIPT"
cat >> "$PREVIEW_SCRIPT" << 'PREVIEW'
ENTRY="$1"
ENTRY="${ENTRY% ●}"

FONT_FILE=$(fc-match -f '%{file}' "$ENTRY" 2>/dev/null)

COLS=${FZF_PREVIEW_COLUMNS:-40}
LINES=${FZF_PREVIEW_LINES:-20}
IMG_LINES=$((LINES - 2))
[[ $IMG_LINES -lt 1 ]] && IMG_LINES=1

SAFE_NAME=$(echo "$ENTRY" | tr -c 'A-Za-z0-9' '_')
SPECIMEN_PNG="$CACHE_DIR/${SAFE_NAME}.png"
if [[ ! -f "$SPECIMEN_PNG" && -n "$FONT_FILE" && -f "$FONT_FILE" ]] && command -v convert &>/dev/null; then
    # Glyphs: home (U+F015), folder (U+F07B), git-branch (U+E725),
    # terminal (U+F489), gear (U+F013) — verified present in the installed
    # FiraCode Nerd Font's cmap via direct TTF cmap-table parsing this
    # session (not an unverified cheat-sheet copy); these come from the
    # Font Awesome/Devicons/Octicons ranges the Nerd Fonts patcher injects
    # verbatim into every patched build, so they carry over across families.
    SPECIMEN_TEXT=$'The quick brown fox jumps over the lazy dog\nfn main() { let x = 42; println!("{}", x); }\n        '
    convert -background none -fill "$FG" \
        -font "$FONT_FILE" -pointsize 22 \
        -size "$((COLS * 11))x$((IMG_LINES * 20))" \
        -gravity NorthWest -kerning 1 \
        caption:"$SPECIMEN_TEXT" "$SPECIMEN_PNG" 2>/dev/null || true
fi

if [[ -f "$SPECIMEN_PNG" ]]; then
    if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten &>/dev/null; then
        kitten icat --clear --transfer-mode=memory --unicode-placeholder \
            --stdin=no --place="${COLS}x${IMG_LINES}@0x0" "$SPECIMEN_PNG" 2>/dev/null \
            | sed '$d' | sed $'$s/$/\e[m/'
    elif command -v chafa &>/dev/null && chafa --help 2>/dev/null | grep -q 'kitty'; then
        chafa --format=kitty --size="${COLS}x${IMG_LINES}" \
              --animate=off --center=on \
              "$SPECIMEN_PNG" 2>/dev/null
    else
        chafa --size="${COLS}x${IMG_LINES}" \
              --animate=off --center=on \
              --color-space=din99d \
              --symbols=block+border+space \
              "$SPECIMEN_PNG" 2>/dev/null
    fi
else
    # Defensive fallback if convert/fc-match are unavailable — the preview
    # pane must never be blank.
    printf '%s\n' "The quick brown fox jumps over the lazy dog"
    printf '%s\n' 'fn main() { let x = 42; println!("{}", x); }'
fi

echo ""
ACTIVE_MARK=""
[[ -f "$HOME/.local/state/theme/font-choice" ]] && \
    [[ "$(cat "$HOME/.local/state/theme/font-choice" 2>/dev/null)" == "$ENTRY" ]] && \
    ACTIVE_MARK="  │  ● active"
echo -e " \e[1m$ENTRY\e[0m${ACTIVE_MARK}"
PREVIEW
chmod +x "$PREVIEW_SCRIPT"

# ── Run fzf ──────────────────────────────────────────
HEADER=" 🔤 Font Switcher  │  ↑↓ browse  │  Enter confirm  │  Esc cancel"
SELECTED=$(echo "$FONTS" | fzf \
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

# Strip the active-font marker suffix before any use (same discipline as
# wallpaper-picker.sh/icon-theme-picker.sh).
SELECTED="${SELECTED% ●}"

# ── Validate against the real enumerated set (Security Domain V5 /
# T-06-14) — defense in depth: the fzf return must resolve to one of the
# entries the enumeration script actually found, never free text, before
# any state-file/config write. ────────────────────────────────────────
VALID=0
while IFS= read -r entry; do
    entry="${entry% ●}"
    [[ "$entry" == "$SELECTED" ]] && { VALID=1; break; }
done <<< "$FONTS"

if [[ "$VALID" -ne 1 ]]; then
    echo "font-switcher: selected entry did not resolve to an enumerated nerd font: $SELECTED" >&2
    exit 1
fi

# ── Persist as a theme-orthogonal state axis (D-19) ──────────────────
# Atomic temp-file + mv, same idiom as commit.sh's current-theme write.
# Never a bare one-off write to any single surface — the state file plus
# the theme-apply re-run below is the sole write path (mirrors
# wallpaper-picker.sh/icon-theme-picker.sh's post-selection re-run,
# D-05/D-11/D-20).
mkdir -p "$(dirname "$FONT_STATE")"
printf '%s\n' "$SELECTED" > "$FONT_STATE.tmp" && mv "$FONT_STATE.tmp" "$FONT_STATE"

# ── VSCodium: jq-merge the chosen family in (mirrors reload.sh's
# theme_engine_reload_vscodium jq -s '.[0] * .[1]' idiom) — the engine's
# reload fan-out has no font key of its own (font is not matugen-rendered
# for vscodium), so this script owns the one-time write here, same as it
# owns the font-choice state file above. ──────────────────────────────
if command -v jq >/dev/null 2>&1; then
    mkdir -p "$(dirname "$VSCODIUM_SETTINGS")"
    [[ -f "$VSCODIUM_SETTINGS" ]] || echo '{}' > "$VSCODIUM_SETTINGS"

    FONT_FRAGMENT_FILE=$(mktemp /tmp/font-vscodium-fragment-XXXXXX.json)
    jq -n --arg editor "'${SELECTED}', 'Fira Code', monospace" \
          --arg term "'${SELECTED}'" \
          '{ "editor.fontFamily": $editor, "terminal.integrated.fontFamily": $term }' \
        > "$FONT_FRAGMENT_FILE"

    jq -s '.[0] * .[1]' "$VSCODIUM_SETTINGS" "$FONT_FRAGMENT_FILE" > "${VSCODIUM_SETTINGS}.tmp" 2>/dev/null \
        && mv "${VSCODIUM_SETTINGS}.tmp" "$VSCODIUM_SETTINGS" \
        || rm -f "${VSCODIUM_SETTINGS}.tmp"
    rm -f "$FONT_FRAGMENT_FILE"
fi

# ── Re-run theme-apply so font.sh re-renders kitty-font.conf/
# waybar-font.css/gtk-font-name and the reload fan-out picks it up (kitty
# SIGUSR1 live-reloads, waybar SIGUSR2, GTK reload) — never reimplement
# render/reload here. ──────────────────────────────────────────────────
ACTIVE_PRESET=$(cat "$CURRENT_THEME_FILE" 2>/dev/null || echo "")
if [[ -n "$ACTIVE_PRESET" ]]; then
    ~/.config/theme-engine/theme-apply "$ACTIVE_PRESET"
else
    echo "font-switcher: no active theme recorded yet — font-choice saved, will apply on the next theme-apply run" >&2
fi

# UI-SPEC Copywriting Contract: worded generically since kitty live-reloads
# and vscodium needs a restart — never overpromise instant effect
# everywhere.
notify-send -a "Font Switcher" "Font Changed" \
    "Applied $SELECTED — restart apps to see the full effect" \
    -i preferences-desktop-font -t 2500 2>/dev/null || true
