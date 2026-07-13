#!/usr/bin/env bash
# Toggle wlogout — kill if running, launch if not.
#
# GEOMETRY (D-09, 06-UI-SPEC "wlogout bar"):
# wlogout's buttons ALWAYS stretch to fill their grid cell inside the
# layer-shell window. CSS min-width/min-height are only a floor, so the
# compact center bar cannot be produced from the stylesheet alone — the
# window itself has to be constrained, which is what the margin flags below
# do. (06-UI-SPEC claimed "no position override needed"; that was wrong, and
# is why the redesign still rendered as the old full-screen tile grid — with
# 426x640px buttons on a 1440p display.)
#
# Margins are derived from the focused monitor's logical size so the bar
# stays 72x72px buttons at any resolution, not just this machine's.
set -euo pipefail

if pgrep -x wlogout >/dev/null 2>&1; then
    pkill -x wlogout
    exit 0
fi

# These MUST stay in sync with wlogout/style.css. GTK3 applies min-width /
# min-height to the CONTENT box, then ADDS padding and border on top -- so the
# button's real on-screen size is CONTENT + 2*PAD + 2*BORDER, not CONTENT.
# Sizing the window to CONTENT alone (the first attempt at this fix) made the
# buttons overflow the window and get clipped at the bottom, which is what
# pushed the glyphs off-centre. Derive the outer size instead of hardcoding it.
CONTENT=72   # style.css: button { min-width / min-height }
PAD=10       # style.css: button { padding }
BORDER=3     # style.css: button { border-width }
GAP=16       # gap between buttons (06-UI-SPEC `md`) -> --column-spacing
COLS=6       # one row of six actions

BTN=$(( CONTENT + 2 * PAD + 2 * BORDER ))    # 72 + 20 + 6 = 98 on screen
BAR_W=$(( COLS * BTN + (COLS - 1) * GAP ))   # 6*98 + 5*16 = 668
BAR_H=$BTN                                   # 98

# Layer-shell margins are in LOGICAL px, so divide pixel size by scale.
MON_W=""; MON_H=""
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    read -r MON_W MON_H < <(
        hyprctl -j monitors 2>/dev/null |
        jq -r 'first(.[] | select(.focused)) |
               "\(((.width / .scale)) | floor) \(((.height / .scale)) | floor)"' 2>/dev/null
    ) || true
fi
# Fall back to a common logical size if the compositor can't be queried.
[[ "$MON_W" =~ ^[0-9]+$ ]] || MON_W=1920
[[ "$MON_H" =~ ^[0-9]+$ ]] || MON_H=1080

centre_margin() {
    # NOTE: assign first, compute second. `local a=$1 m=$((a-1))` expands every
    # word before running the assignments, so the arithmetic would see `a` as
    # unset and trip `set -u`.
    local total="$1"
    local bar="$2"
    local m=$(( (total - bar) / 2 ))
    (( m < 0 )) && m=0
    printf '%s' "$m"
}
MX="$(centre_margin "$MON_W" "$BAR_W")"
MY="$(centre_margin "$MON_H" "$BAR_H")"

wlogout --protocol layer-shell \
        --buttons-per-row "$COLS" \
        --column-spacing "$GAP" \
        --margin-left "$MX"  --margin-right "$MX" \
        --margin-top "$MY"   --margin-bottom "$MY" \
        --no-span &
