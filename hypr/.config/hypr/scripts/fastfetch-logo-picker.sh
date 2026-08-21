#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║  FASTFETCH LOGO PICKER — fzf + kitty graphics/ASCII   ║
# ║                                                        ║
# ║  Mirrors icon-theme-picker.sh's discipline exactly —   ║
# ║  every item below exists because that file's own       ║
# ║  history fixed a real, recorded bug (quick task        ║
# ║  260818-srl, Task 3).                                  ║
# ║                                                        ║
# ║  12 entries: 6 sprites, 4 ASCII arts, random, none.     ║
# ║  Left pane:  entries, fzf fuzzy search                 ║
# ║  Right pane: sprite = animated kitten icat preview;     ║
# ║              ASCII = the actual art, coloured through   ║
# ║              the SAME logo.color map the greeting uses  ║
# ║              (byte-identical, not a guess); random/none ║
# ║              = an explanatory card.                     ║
# ║                                                          ║
# ║  Enter    = confirm selection (writes state, generates  ║
# ║             the sprite GIF if needed, notifies)          ║
# ║  Esc/q    = cancel, no changes made                      ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

# ── Signal-vs-EXIT-trap gap (same fix icon-theme-picker.sh:24-42 already
# proved live against a real `hyprctl dispatch closewindow`) ────────────
for _sig in HUP INT TERM; do
    trap "exit 1" "$_sig"
done

STATE_DIR="$HOME/.local/state/theme"
LOGO_STATE="$STATE_DIR/fastfetch-logo"
FASTFETCH_JSONC="$STATE_DIR/fastfetch.jsonc"
SPRITE_DIR="$STATE_DIR/fastfetch"
SPRITES_PY="$HOME/.config/theme-engine/lib/fastfetch-sprites.py"
ART_DIR="$HOME/.config/fastfetch/art"
ACTIVE_MARKER=" ●"

SPRITE_NAMES=(pulse sweep glitch scan assemble orbit)
ASCII_NAMES=(arch star cyberpunk_mask illuminati)

# ── Non-interactive surface (quick-260821-6z1 Task 10, R-6) — `--list`/
#    `--set <name>`, handled BEFORE any interactive machinery, including
#    before the cache-warm background job below. `_persist_and_apply()`
#    is the SAME tail the interactive path runs on Enter (atomic state
#    write, sprite regen if needed, notify) — factored into one function
#    both paths call, so there is only one copy to keep correct. ────────
_all_names() {
    printf '%s\n' "${SPRITE_NAMES[@]}" "${ASCII_NAMES[@]}" random none
}

_persist_and_apply() {
    local selected="$1"
    mkdir -p "$(dirname "$LOGO_STATE")"
    printf '%s\n' "$selected" > "$LOGO_STATE.tmp" && mv "$LOGO_STATE.tmp" "$LOGO_STATE"

    # If a sprite was chosen and its GIF is missing or stale against the
    # current palette hash, generate it now — the ~250ms cost the
    # interactive path always paid, and the reason a write-only dropdown
    # would have been the wrong shape for this specific script.
    if [[ " ${SPRITE_NAMES[*]} " == *" $selected "* ]]; then
        if command -v python3 &>/dev/null && [[ -f "$SPRITES_PY" ]]; then
            python3 "$SPRITES_PY" "$selected" >/dev/null 2>&1 || \
                echo "fastfetch-logo-picker: sprite regen failed for '$selected' — will fall back to themed ASCII until it succeeds" >&2
        fi
    fi

    # 3d: deliberately NOT re-running theme-apply here — see the
    # interactive path's own note, preserved verbatim below.
    notify-send -a "Fastfetch Logo" "Logo Changed" \
        "Next shell will greet with: ${selected}" \
        -i preferences-desktop-theme -t 2500 2>/dev/null || true
}

case "${1:-}" in
    --list)
        _all_names
        exit 0
        ;;
    --set)
        NAME="${2:-}"
        [[ -n "$NAME" ]] || { echo "fastfetch-logo-picker.sh --set: name required" >&2; exit 1; }
        # Re-validate against the ACTUALLY-enumerated set — never trust
        # the argument as free text, exactly as the interactive path
        # already re-validates fzf's own return below.
        VALID=0
        while IFS= read -r _n; do
            [[ "$_n" == "$NAME" ]] && { VALID=1; break; }
        done < <(_all_names)
        [[ "$VALID" -eq 1 ]] \
            || { echo "fastfetch-logo-picker.sh --set: '$NAME' is not an enumerated entry" >&2; exit 1; }
        _persist_and_apply "$NAME"
        exit 0
        ;;
esac

# ── Pipeline-themed fzf colors (THM-04/D-15), same source + fallback
# discipline as icon-theme-picker.sh ──────────────────────────────────
# shellcheck source=/dev/null
source "$STATE_DIR/fzf-colors.conf" 2>/dev/null || true

ACTIVE_LOGO=$(cat "$LOGO_STATE" 2>/dev/null || echo "arch")

# ── Cache-warm on open (3e) — never block the list from appearing.
# Backgrounded; fzf renders the entry list immediately, and any sprite
# preview requested before its GIF lands just says so and asks the user
# to look again (fastfetch-sprites.py's own palette-hash sidecar makes
# this instant on every open after the first, T-srl-03). Not added to the
# EXIT trap deliberately: letting it finish after the picker closes only
# warms the cache for next time and touches nothing this script itself
# still owns on exit. ──────────────────────────────────────────────────
if [[ -x "$SPRITES_PY" || -f "$SPRITES_PY" ]] && command -v python3 &>/dev/null; then
    python3 "$SPRITES_PY" --all >/dev/null 2>&1 &
    disown
fi

# ── mktemp'd scripts (WR-04 idiom): all vars initialised before the
# first mktemp, ONE EXIT trap covering every one of them, installed
# right after the first mktemp call — never a second on-exit handler
# (icon-theme-picker.sh's own documented discipline). ─────────────────
PREVIEW_SCRIPT=""
PREVIEW_SCRIPT=$(mktemp /tmp/fastfetch-preview-XXXXXX.sh)
trap 'rm -f "$PREVIEW_SCRIPT"' EXIT

cat > "$PREVIEW_SCRIPT" << PREVIEW_HEADER
#!/usr/bin/env bash
STATE_DIR=$(printf '%q' "$STATE_DIR")
SPRITE_DIR=$(printf '%q' "$SPRITE_DIR")
ART_DIR=$(printf '%q' "$ART_DIR")
FASTFETCH_JSONC=$(printf '%q' "$FASTFETCH_JSONC")
ACTIVE_MARKER=$(printf '%q' "$ACTIVE_MARKER")
PREVIEW_HEADER

cat >> "$PREVIEW_SCRIPT" << 'PREVIEW'
RAW="$1"
MARKED=0
[[ "$RAW" == *" ●" ]] && MARKED=1
ENTRY="${RAW% ●}"

SPRITE_NAMES_P=(pulse sweep glitch scan assemble orbit)
ASCII_NAMES_P=(arch star cyberpunk_mask illuminati)

is_in() {
    local needle="$1"; shift
    local x
    for x in "$@"; do [[ "$x" == "$needle" ]] && return 0; done
    return 1
}

render_sprite_preview() {
    local name="$1"
    local gif="$SPRITE_DIR/${name}.gif"
    local COLS=${FZF_PREVIEW_COLUMNS:-40}
    local LINES=${FZF_PREVIEW_LINES:-20}
    local IMG_LINES=$((LINES - 2))
    [[ $IMG_LINES -lt 1 ]] && IMG_LINES=1

    if [[ ! -f "$gif" ]]; then
        echo ""
        echo -e " \e[1m$name\e[0m  (sprite)"
        echo ""
        echo "  generating — cache-warming in the background, look again in a moment"
        return
    fi

    # Deliberately NO --animate=off here (unlike the icon-theme-picker's
    # static-grid preview) — the whole point of this pane is previewing
    # motion. Whether kitten icat animates INSIDE an fzf preview pane
    # (which redraws on every keypress) is explicitly unverified and not
    # chased here (plan's own "known unverified, do not chase" note) — the
    # greeting itself is the protocol-verified animating path; a still
    # first frame here is an acceptable outcome.
    if [[ -n "${KITTY_WINDOW_ID:-}" ]] && command -v kitten &>/dev/null; then
        kitten icat --clear --transfer-mode=memory --unicode-placeholder \
            --stdin=no --place="${COLS}x${IMG_LINES}@0x0" "$gif" 2>/dev/null \
            | sed '$d' | sed $'$s/$/\e[m/'
    elif command -v chafa &>/dev/null && chafa --help 2>/dev/null | grep -q 'kitty'; then
        chafa --format=kitty --size="${COLS}x${IMG_LINES}" \
              --center=on \
              "$gif" 2>/dev/null
    else
        chafa --size="${COLS}x${IMG_LINES}" \
              --center=on \
              --color-space=din99d \
              --symbols=block+border+space \
              "$gif" 2>/dev/null
    fi
    echo ""
    echo -e " \e[1m$name\e[0m  (sprite)"
}

render_ascii_preview() {
    local name="$1"
    local art_file="$ART_DIR/${name}.txt"

    if [[ ! -f "$art_file" ]]; then
        echo "art file missing: $art_file"
        return
    fi

    echo ""

    if [[ ! -f "$FASTFETCH_JSONC" ]]; then
        # Fresh-install degradation: no theme-apply has run yet — show the
        # art unthemed rather than erroring the preview pane.
        cat "$art_file"
    else
        # Byte-identical to what the greeting will draw: read the SAME
        # logo.color map out of the SAME rendered fastfetch.jsonc, via jq,
        # and substitute the $N markers with real 24-bit SGR sequences —
        # never a hardcoded palette (plan's own "do not hardcode a
        # palette" instruction).
        local sed_args=()
        local n hex r g b
        for n in 1 2 3 4 5 6 7 8 9; do
            hex=$(jq -r --arg n "$n" '.logo.color[$n] // empty' "$FASTFETCH_JSONC" 2>/dev/null)
            [[ -z "$hex" ]] && continue
            hex="${hex#\#}"
            [[ "$hex" =~ ^[0-9a-fA-F]{6}$ ]] || continue
            r=$((16#${hex:0:2})); g=$((16#${hex:2:2})); b=$((16#${hex:4:2}))
            sed_args+=(-e "s/\\\$${n}/$(printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b")/g")
        done
        if [[ ${#sed_args[@]} -gt 0 ]]; then
            sed "${sed_args[@]}" "$art_file"
        else
            cat "$art_file"
        fi
        printf '\033[m\n'
    fi

    echo ""
    echo -e " \e[1m$name\e[0m  (ASCII art)"
}

if [[ "$ENTRY" == "random" ]]; then
    echo ""
    echo -e " \e[1mrandom\e[0m"
    echo ""
    echo "  picks a random SPRITE inside kitty, a random ASCII art"
    echo "  everywhere else — re-rolled on every shell start"
    exit 0
elif [[ "$ENTRY" == "none" ]]; then
    echo ""
    echo -e " \e[1mnone\e[0m"
    echo ""
    echo "  box only — no logo column at all"
    exit 0
elif is_in "$ENTRY" "${SPRITE_NAMES_P[@]}"; then
    render_sprite_preview "$ENTRY"
elif is_in "$ENTRY" "${ASCII_NAMES_P[@]}"; then
    render_ascii_preview "$ENTRY"
else
    echo "unrecognised entry: $ENTRY"
fi
PREVIEW
chmod +x "$PREVIEW_SCRIPT"

# ── Build the 12-entry list, active one marked ────────────────────────
ENTRIES=""
for name in "${SPRITE_NAMES[@]}" "${ASCII_NAMES[@]}" random none; do
    if [[ "$name" == "$ACTIVE_LOGO" ]]; then
        ENTRIES+="${name}${ACTIVE_MARKER}"$'\n'
    else
        ENTRIES+="${name}"$'\n'
    fi
done
ENTRIES="${ENTRIES%$'\n'}"

SELECTED=$(printf '%s\n' "$ENTRIES" | fzf \
    --preview "$PREVIEW_SCRIPT {}" \
    --preview-window "right,60%,border-left" \
    --header " 󰢹 Fastfetch Logo Picker  │  6 sprites + 5 ASCII + random + none  │  ↑↓ browse  │  Enter confirm  │  Esc cancel" \
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

# ── Handle cancellation ───────────────────────────────
if [[ -z "$SELECTED" ]]; then
    exit 0
fi

# Strip the active-entry marker before any use (same discipline as
# icon-theme-picker.sh).
SELECTED="${SELECTED% ●}"

# ── T-srl-02: re-validate against the ACTUALLY-enumerated set — never
# trust fzf's return as free text, exactly as icon-theme-picker.sh:573-582
# does for its own selection. ───────────────────────────────────────────
VALID=0
while IFS= read -r entry; do
    entry="${entry% ●}"
    [[ "$entry" == "$SELECTED" ]] && { VALID=1; break; }
done <<< "$ENTRIES"

if [[ "$VALID" -ne 1 ]]; then
    echo "fastfetch-logo-picker: selected entry did not resolve to an enumerated entry: $SELECTED" >&2
    exit 1
fi

# ── Persist as a theme-orthogonal state axis (same shape as icon-theme,
# font-choice, motion-scale), regen the sprite if needed, notify — the
# SAME tail `--set` runs, factored into `_persist_and_apply()` above so
# there is only one copy. The cache-warm background job earlier in this
# file makes the sprite-regen call a no-op here if it already finished
# (fastfetch-sprites.py's own hash-sidecar check), never a duplicate
# ~250ms regen. 3d: deliberately NOT re-running theme-apply — colours
# did not change, only which logo the NEXT shell draws (a
# theme-orthogonal axis exactly like icon-theme/font-choice/
# motion-scale), unlike icon-theme-picker.sh's re-apply, which exists
# because an icon-theme change on THAT axis needs settings.ini rewritten
# by the engine.
_persist_and_apply "$SELECTED"
