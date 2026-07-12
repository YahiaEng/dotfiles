#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║     WALLPAPER PICKER — fzf + kitty graphics + awww   ║
# ║                                                      ║
# ║  - Left pane:  wallpaper list with fzf fuzzy search  ║
# ║                (restricted to the active static      ║
# ║                theme's set; Ctrl-A browses all)      ║
# ║  - Right pane: pixel-perfect kitty-graphics preview  ║
# ║  - Desktop:    live awww animated preview as you     ║
# ║                navigate through selections           ║
# ║                                                      ║
# ║  Enter    = confirm selection                        ║
# ║  Ctrl-A   = temporarily browse the full collection   ║
# ║  Esc/q    = cancel and restore previous wallpaper    ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CURRENT_LINK="$WALLPAPER_DIR/current.jpg"
STATE_FILE="$HOME/.local/state/theme/current-theme"
PREVIOUS_FILE="$HOME/.cache/wallpaper-picker-previous"
LAST_WALLPAPER_DIR="$HOME/.local/state/theme/last-wallpaper"
IMG_MATCH=(-iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif")
ACTIVE_MARKER=" ●"

# ── Pipeline-themed fzf colors (THM-04/D-15) ─────────
# Best-effort source of the engine-rendered fragment; the current
# catppuccin-mocha hex values survive only as ${VAR:-fallback} defaults
# below (fresh-install graceful degradation before the first theme-apply).
# shellcheck source=/dev/null
source "$HOME/.local/state/theme/fzf-colors.conf" 2>/dev/null || true

# ── Ensure directory exists ──────────────────────────
mkdir -p "$WALLPAPER_DIR"

# ── Save current wallpaper so we can restore on cancel
PREVIOUS_WALLPAPER=$(readlink -f "$CURRENT_LINK" 2>/dev/null || echo "")
echo "$PREVIOUS_WALLPAPER" > "$PREVIOUS_FILE"

# ── Human-readable theme display name (Copywriting Contract) ─────────
# Special-cased families first (upstream branding uses characters/spacing
# a generic hyphen-split can't reproduce), generic title-case fallback for
# everything else — never invent a mapping for a family not listed here.
theme_display_name() {
    local name="$1"
    case "$name" in
        rosepine) echo "Rosé Pine"; return ;;
        rosepine-dawn) echo "Rosé Pine Dawn"; return ;;
        tokyonight) echo "Tokyo Night"; return ;;
        tokyonight-day) echo "Tokyo Night Day"; return ;;
    esac
    local out="" part
    IFS='-' read -ra parts <<< "$name"
    for part in "${parts[@]}"; do
        out+="${part^} "
    done
    echo "${out% }"
}

# ── Enumeration script (THM-03/D-16/D-12) ────────────
# Security Domain V5: enumerate real files only via `find -printf`, never
# trust raw interpolation — same discipline as the pre-existing picker and
# lib/wallpaper.sh's autoset. Written to a standalone script (matches the
# existing PREVIEW_SCRIPT/LIVE_SCRIPT tmp-script convention) so the same
# logic serves both the initial listing and the Ctrl-A `reload()` action.
# Usage: wp-enum.sh full            -> full pool, relpath-based (maxdepth 2)
#        wp-enum.sh <theme-name>    -> that theme's folder only (maxdepth 1),
#                                       entries prefixed "<theme-name>/"
# The active wallpaper's entry gets the reserved marker glyph appended as a
# suffix (stripped again by the preview/live scripts and the selection
# handler before any path use).
# Resolve the real (symlink-followed) Wallpapers dir once here — WALLPAPER_DIR
# itself may sit behind a stow-managed directory symlink (e.g. ~/Pictures ->
# dotfiles/wallpapers/Pictures), so `readlink -f current.jpg` resolves to
# that real path, not the literal $WALLPAPER_DIR string. Compare against the
# resolved base so the active-marker prefix match actually succeeds.
WALLPAPER_DIR_REAL=$(readlink -f "$WALLPAPER_DIR" 2>/dev/null || echo "$WALLPAPER_DIR")

ENUM_SCRIPT=$(mktemp /tmp/wp-enum-XXXXXX.sh)
cat > "$ENUM_SCRIPT" << ENUM
#!/usr/bin/env bash
MODE="\$1"
WALLPAPER_DIR="$WALLPAPER_DIR"
WALLPAPER_DIR_REAL="$WALLPAPER_DIR_REAL"
ACTIVE_MARKER="$ACTIVE_MARKER"

ACTIVE_RELPATH=""
if [[ -f "\$WALLPAPER_DIR/current.jpg" ]]; then
    ACTIVE_TARGET=\$(readlink -f "\$WALLPAPER_DIR/current.jpg" 2>/dev/null || echo "")
    if [[ -n "\$ACTIVE_TARGET" && "\$ACTIVE_TARGET" == "\$WALLPAPER_DIR_REAL"/* ]]; then
        ACTIVE_RELPATH="\${ACTIVE_TARGET#"\$WALLPAPER_DIR_REAL"/}"
    fi
fi

if [[ "\$MODE" == "full" ]]; then
    LIST=\$(find "\$WALLPAPER_DIR" -maxdepth 2 \\
        -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \\) \\
        ! -name "current.jpg" \\
        -printf "%P\\n" 2>/dev/null | sort)
else
    LIST=\$(find "\$WALLPAPER_DIR/\$MODE" -maxdepth 1 \\
        -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \\) \\
        ! -name "current.jpg" \\
        -printf "%f\\n" 2>/dev/null | sort | sed "s|^|\$MODE/|")
fi

while IFS= read -r line; do
    [[ -z "\$line" ]] && continue
    if [[ -n "\$ACTIVE_RELPATH" && "\$line" == "\$ACTIVE_RELPATH" ]]; then
        printf '%s%s\n' "\$line" "\$ACTIVE_MARKER"
    else
        printf '%s\n' "\$line"
    fi
done <<< "\$LIST"
ENUM
chmod +x "$ENUM_SCRIPT"

# ── Mode selection (THM-03/D-16/D-12/D-05) ───────────
CURRENT_THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "")
STANDARD_HEADER=" 🖼  Wallpaper Picker  │  ↑↓ browse  │  Enter confirm  │  Esc cancel"
HEADER="$STANDARD_HEADER"
MODE_ARG="full"
RESTRICTED=0

if [[ -n "$CURRENT_THEME" && "$CURRENT_THEME" != "materialyou" && "$CURRENT_THEME" != "materialyou-light" ]]; then
    THEME_DISPLAY=$(theme_display_name "$CURRENT_THEME")
    THEME_FOLDER="$WALLPAPER_DIR/$CURRENT_THEME"
    THEME_HAS_IMAGES=0
    if [[ -d "$THEME_FOLDER" ]]; then
        if find "$THEME_FOLDER" -maxdepth 1 -type f \( "${IMG_MATCH[@]}" \) ! -name "current.jpg" -print -quit 2>/dev/null | grep -q .; then
            THEME_HAS_IMAGES=1
        fi
    fi

    if [[ "$THEME_HAS_IMAGES" == "1" ]]; then
        MODE_ARG="$CURRENT_THEME"
        RESTRICTED=1
        HEADER=" 🖼  ${THEME_DISPLAY} Wallpapers  │  Ctrl-A browse all  │  ↑↓ browse  │  Enter confirm  │  Esc cancel"
    else
        MODE_ARG="full"
        HEADER=" 🖼  ${THEME_DISPLAY} Wallpapers (none yet — showing full library)  │  ↑↓ browse  │  Enter confirm  │  Esc cancel"
    fi
fi

# ── Gather images ────────────────────────────────────
IMAGES=$("$ENUM_SCRIPT" "$MODE_ARG")

if [[ -z "$IMAGES" ]]; then
    rm -f "$ENUM_SCRIPT"
    echo "No wallpapers found in $WALLPAPER_DIR"
    echo "Add images and try again."
    echo ""
    echo "Press any key to exit..."
    read -rn1
    exit 1
fi

# ── Preview script (written to tmp) ─────────────────
# THM-04/D-13/D-14: pixel-perfect preview via the kitty graphics protocol,
# reusing fzf's own upstream fzf-preview.sh technique verbatim (RESEARCH
# Pattern 4) rather than re-deriving the kitten icat invocation — the
# trailing `sed '$d'` + ANSI-reset pair is the exact fix fzf's maintainers
# ship for the "stale image on scroll" / "reset code confuses fzf's line
# count" artifacts. chafa -f kitty (same protocol) is the fallback when
# kitten is unavailable; the original block-symbols chafa call is the last
# resort for non-kitty-graphics terminals.
PREVIEW_SCRIPT=$(mktemp /tmp/wp-preview-XXXXXX.sh)
# WR-02: interpolate the single WALLPAPER_DIR constant into the generated
# script's prologue (printf %q — safe against spaces/metachars) so the
# quoted heredoc body below references it instead of hardcoding a second
# divergent copy of the path (same discipline as the ENUM heredoc above).
printf '#!/usr/bin/env bash\nWALLPAPER_DIR=%q\n' "$WALLPAPER_DIR" > "$PREVIEW_SCRIPT"
cat >> "$PREVIEW_SCRIPT" << 'PREVIEW'
ENTRY="$1"
ENTRY="${ENTRY% ●}"
FILE="$WALLPAPER_DIR/$ENTRY"
[[ ! -f "$FILE" ]] && exit 0

# Get preview pane dimensions from fzf — reserve 2 rows for the metadata
# line printed below the image.
COLS=${FZF_PREVIEW_COLUMNS:-40}
LINES=${FZF_PREVIEW_LINES:-20}
IMG_LINES=$((LINES - 2))
[[ $IMG_LINES -lt 1 ]] && IMG_LINES=1

if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten &>/dev/null; then
    # Primary: kitty graphics protocol via kitten icat (verbatim fzf
    # upstream pattern — RESEARCH.md Pattern 4).
    kitten icat --clear --transfer-mode=memory --unicode-placeholder \
        --stdin=no --place="${COLS}x${IMG_LINES}@0x0" "$FILE" 2>/dev/null \
        | sed '$d' | sed $'$s/$/\e[m/'
elif command -v chafa &>/dev/null && chafa --help 2>/dev/null | grep -q 'kitty'; then
    # Fallback 1: chafa's own kitty-graphics-protocol output format — same
    # pixel-perfect protocol, different tool.
    chafa --format=kitty --size="${COLS}x${IMG_LINES}" \
          --animate=off --center=on \
          "$FILE" 2>/dev/null
else
    # Fallback 2 (last resort): character-block-art rendering.
    chafa --size="${COLS}x${IMG_LINES}" \
          --animate=off \
          --center=on \
          --color-space=din99d \
          --symbols=block+border+space \
          "$FILE" 2>/dev/null
fi

# Print filename and dimensions below preview (single ANSI-bold emphasis
# convention, UI-SPEC Typography), plus an active indicator when the
# previewed file is the currently active wallpaper.
echo ""
DIMS=$(identify -format "%wx%h" "$FILE" 2>/dev/null || echo "unknown")
SIZE=$(du -h "$FILE" 2>/dev/null | cut -f1)
ACTIVE_MARK=""
CURRENT_LINK="$WALLPAPER_DIR/current.jpg"
if [[ -f "$CURRENT_LINK" ]]; then
    # Compare fully-resolved (readlink -f) targets on both sides — WALLPAPER_DIR
    # itself may sit behind a stow-managed directory symlink, so resolving only
    # one side would never match.
    ACTIVE_TARGET=$(readlink -f "$CURRENT_LINK" 2>/dev/null || echo "")
    FILE_TARGET=$(readlink -f "$FILE" 2>/dev/null || echo "")
    [[ -n "$ACTIVE_TARGET" && "$ACTIVE_TARGET" == "$FILE_TARGET" ]] && ACTIVE_MARK="  │  ● active"
fi
echo -e " \e[1m$ENTRY\e[0m  │  ${DIMS}  │  ${SIZE}${ACTIVE_MARK}"
PREVIEW
chmod +x "$PREVIEW_SCRIPT"

# ── Live preview script (awww on desktop) ────────────
# THM-04/D-13 keeper feature: awww live-preview on navigate. Strips the
# active-wallpaper marker suffix (D-14) before path use, exactly like the
# preview script above. Second arg selects the transition (default: the
# focus-navigate wipe; "random" for the Ctrl-R random-transition binding).
LIVE_SCRIPT=$(mktemp /tmp/wp-live-XXXXXX.sh)
# WR-02: same interpolated-prologue pattern as PREVIEW_SCRIPT above.
printf '#!/usr/bin/env bash\nWALLPAPER_DIR=%q\n' "$WALLPAPER_DIR" > "$LIVE_SCRIPT"
cat >> "$LIVE_SCRIPT" << 'LIVE'
ENTRY="$1"
ENTRY="${ENTRY% ●}"
FILE="$WALLPAPER_DIR/$ENTRY"
[[ ! -f "$FILE" ]] && exit 0
if [[ "${2:-}" == "random" ]]; then
    awww img "$FILE" \
        --transition-type random \
        --transition-duration 1 \
        --transition-fps 165 2>/dev/null &
else
    awww img "$FILE" \
        --transition-type wipe \
        --transition-angle 30 \
        --transition-duration 1 \
        --transition-fps 165 \
        --transition-step 90 2>/dev/null &
fi
LIVE
chmod +x "$LIVE_SCRIPT"

# ── Ctrl-A browse-all binding (THM-03/D-16) ──────────
# Only meaningful (and only added) when the picker opened restricted to a
# static theme's folder — reload()s the full relpath-based pool and swaps
# the header back to the standard unrestricted copy.
CTRL_A_BIND=()
if [[ "$RESTRICTED" == "1" ]]; then
    CTRL_A_BIND=(--bind "ctrl-a:reload(\"$ENUM_SCRIPT\" full)+change-header($STANDARD_HEADER)")
fi

# ── Run fzf ──────────────────────────────────────────
SELECTED=$(echo "$IMAGES" | fzf \
    --preview "$PREVIEW_SCRIPT {}" \
    --preview-window "right,60%,border-left" \
    --bind "focus:execute-silent($LIVE_SCRIPT {})" \
    --bind "ctrl-r:execute-silent($LIVE_SCRIPT {} random)" \
    "${CTRL_A_BIND[@]}" \
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
rm -f "$PREVIEW_SCRIPT" "$LIVE_SCRIPT" "$ENUM_SCRIPT"

# ── Handle selection or cancellation ─────────────────
if [[ -z "$SELECTED" ]]; then
    # Cancelled — restore previous wallpaper
    if [[ -n "$PREVIOUS_WALLPAPER" && -f "$PREVIOUS_WALLPAPER" ]]; then
        awww img "$PREVIOUS_WALLPAPER" \
            --transition-type center \
            --transition-duration 1 \
            --transition-fps 165 2>/dev/null
    fi
    rm -f "$PREVIOUS_FILE"
    exit 0
fi

# Strip the active-wallpaper marker suffix before any path use (D-14).
SELECTED="${SELECTED% ●}"

# ── Confirm selection ────────────────────────────────
FULL_PATH="$WALLPAPER_DIR/$SELECTED"
if [[ ! -f "$FULL_PATH" ]]; then
    # Defense in depth (T-05-09) — entries come exclusively from the
    # enumeration script's find output above, never free text, but the
    # joined path is re-validated as an existing regular file under the
    # Wallpapers root before any symlink operation.
    echo "wallpaper-picker: selected entry does not resolve to a file: $SELECTED" >&2
    rm -f "$PREVIOUS_FILE"
    exit 1
fi
ln -sfr "$FULL_PATH" "$CURRENT_LINK"

# Final animated set (in case live preview didn't fire)
awww img "$FULL_PATH" \
    --transition-type center \
    --transition-duration 2 \
    --transition-fps 165

# ── Post-selection branching (D-05/D-11/D-20) ────────
# In dynamic mode, wallpaper and palette must always match — re-run the
# single shared engine entrypoint (theme-apply) with the exact active
# variant name (never hardcode the dark variant), never reimplement
# apply+reload here (this used to be a third duplication site, D-01).
# In static mode, picking a wallpaper changes only the wallpaper, and —
# when the selection lives inside the active theme's own folder — records
# it as that theme's last-used wallpaper (D-11; Ctrl-A selections from
# outside the folder are not recorded).
if [[ "$CURRENT_THEME" == "materialyou" || "$CURRENT_THEME" == "materialyou-light" ]]; then
    sleep 0.5
    ~/.config/theme-engine/theme-apply "$CURRENT_THEME"
else
    notify-send -a "Wallpaper Picker" "Wallpaper Changed" \
        "Set to $SELECTED" \
        -i preferences-desktop-wallpaper -t 2000

    if [[ -n "$CURRENT_THEME" && "$SELECTED" == "$CURRENT_THEME/"* ]]; then
        BARE_FILENAME="${SELECTED#"$CURRENT_THEME"/}"
        if [[ "$BARE_FILENAME" != */* ]]; then
            mkdir -p "$LAST_WALLPAPER_DIR" 2>/dev/null || true
            printf '%s\n' "$BARE_FILENAME" > "$LAST_WALLPAPER_DIR/$CURRENT_THEME.tmp" 2>/dev/null \
                && mv "$LAST_WALLPAPER_DIR/$CURRENT_THEME.tmp" "$LAST_WALLPAPER_DIR/$CURRENT_THEME" 2>/dev/null || true
        fi
    fi
fi

rm -f "$PREVIOUS_FILE"
