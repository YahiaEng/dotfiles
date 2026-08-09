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
# D-17: distinct from ACTIVE_MARKER by construction ("this one moves" vs
# "this one is active") — the two must never collide, since an entry can
# carry both at once (a live active pick). Glyph is Claude's discretion
# per CONTEXT.md.
LIVE_MARKER=" ▶"

# ── Source the theme-engine's wallpaper library (AMB-01/17-03 Task 1a) ──
# Guarded source, following gaming-mode-toggle.sh:38-40's CONTRACT_LIB
# idiom. This assigns WALLPAPER_DIR/LAST_WALLPAPER_DIR to the exact same
# literals this file already defines above — a same-value collision, not
# a conflict, and is exactly what this plan's "library constants match
# the picker's" acceptance criterion (17-03-PLAN.md Task 1) asserts so a
# future divergence introduced by editing only one file cannot land
# silently. Gives us theme_engine_wallpaper_is_live_ref,
# theme_engine_wallpaper_frame_path, theme_engine_wallpaper_frame_offset,
# theme_engine_wallpaper_extract_frame and FRAME_DIR — the one source of
# truth for the live/ shape test and the extraction command; 17-02
# already applied this same rule when theme-doctor sourced this library
# instead of re-implementing the regex, and nothing in THIS file may
# re-derive either.
WALLPAPER_LIB="$HOME/.config/theme-engine/lib/wallpaper.sh"
# shellcheck source=/dev/null
[[ -r "$WALLPAPER_LIB" ]] && source "$WALLPAPER_LIB"

# ── One order-independent marker-strip helper (D-17) ────────────────
# An entry can carry BOTH markers at once (a live active pick), so a
# single open-coded trailing-active-marker strip is no longer sufficient
# — this loops, stripping ACTIVE_MARKER then LIVE_MARKER off the tail,
# until the value
# stops changing, so the two-marker case strips regardless of order.
# Defined ONCE here; emitted into the PREVIEW_SCRIPT/LIVE_SCRIPT
# generated-script prologues below via `declare -f` (same definition,
# never a second hand-copy).
wp_strip_markers() {
    local entry="$1" prev
    while :; do
        prev="$entry"
        entry="${entry%"$ACTIVE_MARKER"}"
        entry="${entry%"$LIVE_MARKER"}"
        [[ "$entry" == "$prev" ]] && break
    done
    printf '%s' "$entry"
}

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
# Same resolution for the frame directory (D-06/D-18) — after a live pick,
# current.jpg resolves under HERE, not under WALLPAPER_DIR_REAL (17-02
# handoff (b)). FRAME_DIR comes from the sourced library; fall back to its
# known literal if the source above failed (fresh-install degradation).
FRAME_DIR_REAL=$(readlink -f "${FRAME_DIR:-$HOME/.local/state/theme/wallpaper-frames}" 2>/dev/null || echo "${FRAME_DIR:-$HOME/.local/state/theme/wallpaper-frames}")

# ── Current theme (moved above ENUM_SCRIPT — the active-entry regression
# fix (17-02 handoff (b)) needs it interpolated into the generated script) ──
CURRENT_THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "")

ENUM_SCRIPT=$(mktemp /tmp/wp-enum-XXXXXX.sh)
cat > "$ENUM_SCRIPT" << ENUM
#!/usr/bin/env bash
MODE="\$1"
WALLPAPER_DIR="$WALLPAPER_DIR"
WALLPAPER_DIR_REAL="$WALLPAPER_DIR_REAL"
FRAME_DIR_REAL="$FRAME_DIR_REAL"
CURRENT_THEME="$CURRENT_THEME"
LAST_WALLPAPER_DIR="$LAST_WALLPAPER_DIR"
ACTIVE_MARKER="$ACTIVE_MARKER"
LIVE_MARKER="$LIVE_MARKER"
WALLPAPER_LIB="$WALLPAPER_LIB"
# shellcheck source=/dev/null
[[ -r "\$WALLPAPER_LIB" ]] && source "\$WALLPAPER_LIB"

ACTIVE_RELPATH=""
if [[ -f "\$WALLPAPER_DIR/current.jpg" ]]; then
    ACTIVE_TARGET=\$(readlink -f "\$WALLPAPER_DIR/current.jpg" 2>/dev/null || echo "")
    if [[ -n "\$ACTIVE_TARGET" && "\$ACTIVE_TARGET" == "\$WALLPAPER_DIR_REAL"/* ]]; then
        ACTIVE_RELPATH="\${ACTIVE_TARGET#"\$WALLPAPER_DIR_REAL"/}"
    elif [[ -n "\$ACTIVE_TARGET" && -n "\$FRAME_DIR_REAL" && "\$ACTIVE_TARGET" == "\$FRAME_DIR_REAL"/* && -n "\$CURRENT_THEME" ]]; then
        # 17-02 handoff (b): current.jpg resolves under the frame dir for a
        # live choice. The recorded state is the authority here, never a
        # reverse-derivation of the frame filename.
        if [[ -f "\$LAST_WALLPAPER_DIR/\$CURRENT_THEME" ]]; then
            RECORDED=\$(head -n1 "\$LAST_WALLPAPER_DIR/\$CURRENT_THEME" 2>/dev/null || true)
            if [[ -n "\$RECORDED" ]] && declare -F theme_engine_wallpaper_is_live_ref >/dev/null 2>&1 \\
                && theme_engine_wallpaper_is_live_ref "\$RECORDED" \\
                && [[ -f "\$WALLPAPER_DIR/\$CURRENT_THEME/\$RECORDED" ]]; then
                ACTIVE_RELPATH="\$CURRENT_THEME/\$RECORDED"
            fi
        fi
    fi
fi

if [[ "\$MODE" == "full" ]]; then
    LIST=\$(find "\$WALLPAPER_DIR" -maxdepth 2 \\
        -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \\) \\
        ! -name "current.jpg" \\
        -printf "%P\\n" 2>/dev/null | sort)
    # D-03: separate, unfiltered live/ enumeration pass — no -iname test
    # at all (D-01 defines "live" by folder, not extension), NEVER merged
    # into \$LIST above.
    LIVE_LIST=\$(find "\$WALLPAPER_DIR" -mindepth 3 -maxdepth 3 -type f -path '*/live/*' \\
        -printf "%P\\n" 2>/dev/null | sort)
else
    LIST=\$(find "\$WALLPAPER_DIR/\$MODE" -maxdepth 1 \\
        -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \\) \\
        ! -name "current.jpg" \\
        -printf "%f\\n" 2>/dev/null | sort | sed "s|^|\$MODE/|")
    LIVE_LIST=\$(find "\$WALLPAPER_DIR/\$MODE/live" -maxdepth 1 -type f \\
        -printf "%f\\n" 2>/dev/null | sort | sed "s|^|\$MODE/live/|")
fi

while IFS= read -r line; do
    [[ -z "\$line" ]] && continue
    if [[ -n "\$ACTIVE_RELPATH" && "\$line" == "\$ACTIVE_RELPATH" ]]; then
        printf '%s%s\n' "\$line" "\$ACTIVE_MARKER"
    else
        printf '%s\n' "\$line"
    fi
done <<< "\$LIST"

# Live entries are listed after the stills (D-17: grouped at the end,
# discoverable) and always carry LIVE_MARKER; the active one carries
# LIVE_MARKER FIRST then ACTIVE_MARKER (renders as "... ▶ ●" — matches
# wp_strip_markers' stripping order, which peels ACTIVE_MARKER's suffix
# before LIVE_MARKER's).
while IFS= read -r line; do
    [[ -z "\$line" ]] && continue
    if [[ -n "\$ACTIVE_RELPATH" && "\$line" == "\$ACTIVE_RELPATH" ]]; then
        printf '%s%s%s\n' "\$line" "\$LIVE_MARKER" "\$ACTIVE_MARKER"
    else
        printf '%s%s\n' "\$line" "\$LIVE_MARKER"
    fi
done <<< "\$LIVE_LIST"
ENUM
chmod +x "$ENUM_SCRIPT"

# ── Mode selection (THM-03/D-16/D-12/D-05) ───────────
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
        # D-03 live-only-theme fix: a theme whose wallpapers are ALL live
        # must not fall through to the unrestricted full library — mirrors
        # theme_engine_wallpaper_autoset's identical fix (17-02c); the
        # picker and the engine must never disagree about whether a theme
        # has wallpapers.
        elif find "$THEME_FOLDER/live" -maxdepth 1 -type f -print -quit 2>/dev/null | grep -q .; then
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
# WR-02: interpolate the shared constants into the generated script's
# prologue (printf %q — safe against spaces/metachars) so the quoted
# heredoc body below references them instead of hardcoding a second
# divergent copy (same discipline as the ENUM heredoc above). D-18 adds
# the library source (for is_live_ref/frame_path/frame_offset/
# extract_frame) and `declare -f wp_strip_markers` — the SAME definition
# emitted here and into LIVE_SCRIPT below, never a second hand-copy.
printf '#!/usr/bin/env bash\nWALLPAPER_DIR=%q\nACTIVE_MARKER=%q\nLIVE_MARKER=%q\nWALLPAPER_LIB=%q\n' \
    "$WALLPAPER_DIR" "$ACTIVE_MARKER" "$LIVE_MARKER" "$WALLPAPER_LIB" > "$PREVIEW_SCRIPT"
declare -f wp_strip_markers >> "$PREVIEW_SCRIPT"
printf '\n[[ -r "$WALLPAPER_LIB" ]] && source "$WALLPAPER_LIB"\n' >> "$PREVIEW_SCRIPT"
cat >> "$PREVIEW_SCRIPT" << 'PREVIEW'
ENTRY="$1"
ENTRY="$(wp_strip_markers "$ENTRY")"
FILE="$WALLPAPER_DIR/$ENTRY"
[[ ! -f "$FILE" ]] && exit 0

# D-18: a live entry's remainder (theme stripped) satisfies
# theme_engine_wallpaper_is_live_ref — the SAME shape test the engine and
# theme-doctor use, never re-derived here.
THEME="${ENTRY%%/*}"
REMAINDER="${ENTRY#*/}"
IS_LIVE=0
if [[ "$ENTRY" == */* ]] && declare -F theme_engine_wallpaper_is_live_ref >/dev/null 2>&1 \
    && theme_engine_wallpaper_is_live_ref "$REMAINDER"; then
    IS_LIVE=1
fi

RENDER_FILE="$FILE"
if [[ "$IS_LIVE" == "1" ]]; then
    # Extract-on-first-preview, cache warm (D-18): the exact frame that
    # becomes the lock-screen background, produced ONLY through the
    # library's functions — never a second ffmpeg invocation here (both
    # RESEARCH-reproduced silent-failure traps stay closed inside 17-02's
    # function, and re-deriving even one of them at a second call site
    # would risk reproducing only one).
    FRAME="$(theme_engine_wallpaper_frame_path "$THEME" "$REMAINDER")"
    if [[ ! -s "$FRAME" ]]; then
        OFFSET="$(theme_engine_wallpaper_frame_offset "$THEME" "$REMAINDER")"
        theme_engine_wallpaper_extract_frame "$FILE" "$FRAME" "$OFFSET" || true
    fi
    if [[ -s "$FRAME" ]]; then
        RENDER_FILE="$FRAME"
    else
        # Degrade visibly, never blankly, and never fall through to the
        # graphics protocol with the source video (T-17-09-adjacent: the
        # pane must never attempt to render a video through the kitty
        # graphics protocol).
        echo ""
        echo " ${ENTRY}: no frame could be extracted"
        exit 0
    fi
fi

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
        --stdin=no --place="${COLS}x${IMG_LINES}@0x0" "$RENDER_FILE" 2>/dev/null \
        | sed '$d' | sed $'$s/$/\e[m/'
elif command -v chafa &>/dev/null && chafa --help 2>/dev/null | grep -q 'kitty'; then
    # Fallback 1: chafa's own kitty-graphics-protocol output format — same
    # pixel-perfect protocol, different tool.
    chafa --format=kitty --size="${COLS}x${IMG_LINES}" \
          --animate=off --center=on \
          "$RENDER_FILE" 2>/dev/null
else
    # Fallback 2 (last resort): character-block-art rendering.
    chafa --size="${COLS}x${IMG_LINES}" \
          --animate=off \
          --center=on \
          --color-space=din99d \
          --symbols=block+border+space \
          "$RENDER_FILE" 2>/dev/null
fi

# Print filename and dimensions below preview (single ANSI-bold emphasis
# convention, UI-SPEC Typography), plus a live badge and an active
# indicator when the previewed file is the currently active wallpaper.
# Dimensions come from the rendered frame; byte size stays the SOURCE
# video's, which is what the picker's metadata line has always meant.
echo ""
DIMS=$(identify -format "%wx%h" "$RENDER_FILE" 2>/dev/null || echo "unknown")
SIZE=$(du -h "$FILE" 2>/dev/null | cut -f1)
LIVE_BADGE=""
[[ "$IS_LIVE" == "1" ]] && LIVE_BADGE="  │  ▶ live"
ACTIVE_MARK=""
CURRENT_LINK="$WALLPAPER_DIR/current.jpg"
if [[ -f "$CURRENT_LINK" ]]; then
    # Compare fully-resolved (readlink -f) targets on both sides — WALLPAPER_DIR
    # itself may sit behind a stow-managed directory symlink, so resolving only
    # one side would never match. For a live entry this compares against the
    # FRAME, never the video (17-02 handoff (b)'s regression, closed here too).
    ACTIVE_TARGET=$(readlink -f "$CURRENT_LINK" 2>/dev/null || echo "")
    FILE_TARGET=$(readlink -f "$RENDER_FILE" 2>/dev/null || echo "")
    [[ -n "$ACTIVE_TARGET" && "$ACTIVE_TARGET" == "$FILE_TARGET" ]] && ACTIVE_MARK="  │  ● active"
fi
echo -e " \e[1m$ENTRY\e[0m  │  ${DIMS}  │  ${SIZE}${LIVE_BADGE}${ACTIVE_MARK}"
PREVIEW
chmod +x "$PREVIEW_SCRIPT"

# ── Live preview script (awww on desktop) ────────────
# THM-04/D-13 keeper feature: awww live-preview on navigate. Strips the
# active-wallpaper marker suffix (D-14) before path use, exactly like the
# preview script above. Second arg selects the transition (default: the
# focus-navigate wipe; "random" for the Ctrl-R random-transition binding).
LIVE_SCRIPT=$(mktemp /tmp/wp-live-XXXXXX.sh)
# WR-02: same interpolated-prologue pattern as PREVIEW_SCRIPT above. Task
# 1 changes only this shared prologue and the strip helper — the D-19
# debounce and the live/still branch are Task 3's.
printf '#!/usr/bin/env bash\nWALLPAPER_DIR=%q\nACTIVE_MARKER=%q\nLIVE_MARKER=%q\nWALLPAPER_LIB=%q\n' \
    "$WALLPAPER_DIR" "$ACTIVE_MARKER" "$LIVE_MARKER" "$WALLPAPER_LIB" > "$LIVE_SCRIPT"
declare -f wp_strip_markers >> "$LIVE_SCRIPT"
printf '\n[[ -r "$WALLPAPER_LIB" ]] && source "$WALLPAPER_LIB"\n' >> "$LIVE_SCRIPT"
cat >> "$LIVE_SCRIPT" << 'LIVE'
ENTRY="$1"
ENTRY="$(wp_strip_markers "$ENTRY")"
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

# Strip both marker suffixes before any path use (D-14/D-17), via the one
# order-independent helper — never a second open-coded strip.
SELECTED="$(wp_strip_markers "$SELECTED")"

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
# D-06/D-18: is the confirmed selection live? Same shape test as the
# preview pane and the writer guard below — the remainder after the
# theme prefix satisfies theme_engine_wallpaper_is_live_ref.
SEL_THEME="${SELECTED%%/*}"
SEL_REMAINDER="${SELECTED#*/}"
SEL_IS_LIVE=0
if [[ "$SELECTED" == */* ]] && declare -F theme_engine_wallpaper_is_live_ref >/dev/null 2>&1 \
    && theme_engine_wallpaper_is_live_ref "$SEL_REMAINDER"; then
    SEL_IS_LIVE=1
fi

if [[ "$SEL_IS_LIVE" == "1" ]]; then
    # Live selection (D-06/17-02 handoff (b)): current.jpg must point at
    # the extracted FRAME, never the source video — awww cannot play
    # video, and generate.sh's Material You branch would otherwise hand a
    # video to the colour extractor. Resolve/extract ONLY through the
    # sourced library functions — never a second ffmpeg call site here.
    # On failure, leave current.jpg completely untouched and warn: never
    # a dangling lock-screen pointer (T-17-09).
    SEL_FRAME="$(theme_engine_wallpaper_frame_path "$SEL_THEME" "$SEL_REMAINDER")"
    if [[ ! -s "$SEL_FRAME" ]]; then
        SEL_OFFSET="$(theme_engine_wallpaper_frame_offset "$SEL_THEME" "$SEL_REMAINDER")"
        theme_engine_wallpaper_extract_frame "$FULL_PATH" "$SEL_FRAME" "$SEL_OFFSET" || true
    fi
    if [[ -s "$SEL_FRAME" ]]; then
        ln -sfr "$SEL_FRAME" "$CURRENT_LINK"
        # awww owns the static-image path (D-04) — the frame, never the
        # video, which awww cannot play.
        awww img "$SEL_FRAME" \
            --transition-type center \
            --transition-duration 2 \
            --transition-fps 165
    else
        echo "wallpaper-picker: no frame could be extracted for $SELECTED — lock-screen pointer left unchanged" >&2
    fi
else
    ln -sfr "$FULL_PATH" "$CURRENT_LINK"

    # Final animated set (in case live preview didn't fire)
    awww img "$FULL_PATH" \
        --transition-type center \
        --transition-duration 2 \
        --transition-fps 165
fi

# ── Post-selection branching (D-05/D-11/D-20/D-21) ───
# In dynamic mode, wallpaper and palette must always match — re-run the
# single shared engine entrypoint (theme-apply) with the exact active
# variant name (never hardcode the dark variant), never reimplement
# apply+reload here (this used to be a third duplication site, D-01).
# theme-apply's own D-21 call site reaches the SAME sync_owner function
# this branch calls directly below — do not add a second owner call
# inside this branch.
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

    SYNC_REF=""
    if [[ -n "$CURRENT_THEME" && "$SELECTED" == "$CURRENT_THEME/"* ]]; then
        BARE_FILENAME="${SELECTED#"$CURRENT_THEME"/}"
        # T-17-12/D-12 writer half: WIDEN, never relax — the pre-existing
        # no-slash branch stays byte-identical, and exactly one
        # alternative branch is added, delegating to the SAME shape
        # function 17-02's reader uses, so the writer and reader can
        # never drift into accepting different shapes. Never a prefix
        # test, never a fresh regex here.
        if [[ "$BARE_FILENAME" != */* ]] || theme_engine_wallpaper_is_live_ref "$BARE_FILENAME"; then
            mkdir -p "$LAST_WALLPAPER_DIR" 2>/dev/null || true
            printf '%s\n' "$BARE_FILENAME" > "$LAST_WALLPAPER_DIR/$CURRENT_THEME.tmp" 2>/dev/null \
                && mv "$LAST_WALLPAPER_DIR/$CURRENT_THEME.tmp" "$LAST_WALLPAPER_DIR/$CURRENT_THEME" 2>/dev/null || true
            SYNC_REF="$BARE_FILENAME"
        fi
    fi

    # D-21: the ONE sync path — reach the owner through the SAME function
    # theme-apply calls, exactly once. An empty SYNC_REF (an out-of-theme
    # Ctrl-A pick, or a shape the guard above rejected) makes the owner
    # `clear` — correct: picking a still from another theme must stop a
    # playing video.
    if declare -F theme_engine_wallpaper_sync_owner >/dev/null 2>&1; then
        theme_engine_wallpaper_sync_owner "$CURRENT_THEME" "$SYNC_REF" || true
    fi
fi

rm -f "$PREVIOUS_FILE"
