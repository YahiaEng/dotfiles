#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           MEDIA POPUP OPEN (BAR-04 / D-22 / D-23)      ║
# ║  waybar's media segment `on-click` target. Cursor-      ║
# ║  anchored, monitor-clamped `eww open --toggle` wrapper,  ║
# ║  with D-23's pre-authorised fixed-position fallback as   ║
# ║  a single ANCHOR_MODE constant flip. Takes ZERO           ║
# ║  arguments and reads ZERO mpris metadata (T-08-81) — the  ║
# ║  only external data this script consumes is coordinates   ║
# ║  read from hyprctl.                                        ║
# ╚══════════════════════════════════════════════════════╝
#
# Frozen cross-plan interface (08-06/08-07 — do not change here):
#   window name    : media-popup
#   expected args  : [x y] — BOTH required. There is no working
#                    bare `eww open media-popup` on this build (a
#                    real eww 0.6.0 optional-expected-arg bug).
#   :geometry      : :width 300 :height 560 :anchor "top right"
#                    (eww/.config/eww/eww.yuck) — POPUP_W/POPUP_H
#                    below MUST equal these two numbers, or a
#                    correctly-clamped popup silently lands
#                    off-screen because the size it was clamped
#                    against doesn't match the size eww actually
#                    renders.
#
# COORDINATE SPACE (Step B finding — full reasoning recorded in
# 08-08-SUMMARY.md). eww's own configuration docs (quoted verbatim
# in 08-RESEARCH.md's VERDICT 2) state that a window's `x`/`y` are
# "relative to anchor". This window's `:anchor` is the fixed literal
# `"top right"` (08-07's shipped value, not something 08-08 may
# change) — so the `x` this script hands to `eww open` is NOT a
# left-edge offset, it is the distance from the MONITOR's right
# edge to the window's right edge; `y` is the distance from the
# monitor's top edge to the window's top edge. Passing a raw
# left-top screen coordinate straight through would misplace the
# popup by roughly (monitor_width - 2*x - POPUP_W) pixels on any
# monitor wider than the popup.
#
# This script therefore always computes the desired placement first
# as a normal, absolute (top-left-relative) screen rectangle — the
# same way every other coordinate in this repo is reasoned about —
# and converts to the anchor-relative pair immediately before the
# `eww open` call, in `_abs_to_anchor_offset_x/_y` below. Because
# both conversions subtract only quantities derived from the SAME
# monitor rectangle the point was resolved against, the conversion
# is correct for any monitor at any origin, not just a monitor at
# (0,0) — verified by hand for a synthetic second monitor at
# x-origin 1920 in this plan's offline arithmetic check (see
# 08-08-SUMMARY.md). If 08-07's `:anchor` value on `media-popup`
# ever changes, this conversion must be revisited to match it.
#
# ENVIRONMENT NOTE (recorded fully in 08-08-SUMMARY.md): this
# script's live, on-screen placement could not be empirically
# re-verified in the session that authored it — every physical
# display connector was DRM-`disconnected` at the time (confirmed:
# `/sys/class/drm/*/status`), so Hyprland reported zero monitors
# and every `eww open` attempt failed with "Failed to get monitor
# 0". `ANCHOR_MODE` below ships as `fixed` for exactly this reason,
# per D-23's own pre-authorised "take the fallback without debate"
# clause — flip it to `cursor` and re-verify with a real monitor
# attached (Super+B → any layout → click the media segment).

set -euo pipefail

# ── Tunable constants ────────────────────────────────────────────

# cursor | fixed — D-23's pre-authorised fallback switch. Flipping
# this ONE constant to `cursor` takes the cursor-anchored path with
# no other edit anywhere in the repo. Ships as `fixed` this plan —
# see the ENVIRONMENT NOTE above for why.
ANCHOR_MODE="fixed"

# MUST equal 08-07's `defwindow media-popup`'s `:geometry` :width /
# :height (eww/.config/eww/eww.yuck) — a mismatch here is precisely
# what pushes a clamped popup off-screen.
POPUP_W=300
POPUP_H=560

# Clamp inset from the monitor edge (UI-SPEC's `sm` 8px spacing token).
EDGE_MARGIN=8

# Vertical offset from the cursor to the popup's top edge (cursor mode).
CURSOR_GAP=20

# Fixed-mode's offset from the monitor's top-right corner — mirrors
# where swaync's control centre opens (UI-SPEC's own wording for
# this fallback).
FIXED_OFFSET=10

# The eww window this script opens/toggles — frozen, see header.
WINDOW_NAME="media-popup"

# ── Guards ───────────────────────────────────────────────────────
# A missing eww is a build/packaging concern, never a user-facing
# toast (UI-SPEC Copywriting Contract) — silent no-op.
command -v eww >/dev/null 2>&1 || exit 0

HAVE_HYPRCTL=1
command -v hyprctl >/dev/null 2>&1 || HAVE_HYPRCTL=0
HAVE_JQ=1
command -v jq >/dev/null 2>&1 || HAVE_JQ=0

# ── Single-flight guard (T-08-82) ────────────────────────────────
# A burst of clicks on the segment must not spawn racing open/close
# calls that leave the popup in an indeterminate state (two
# surfaces, or a surface that will not close).
LOCK_DIR="${XDG_RUNTIME_DIR:-$HOME/.cache}"
mkdir -p "$LOCK_DIR" 2>/dev/null || true
LOCKFILE="$LOCK_DIR/media-popup-open.lock"
{ exec 9>"$LOCKFILE"; } 2>/dev/null || exit 0
flock -n 9 || exit 0

# ── Helpers ──────────────────────────────────────────────────────

# Anchored, optional-minus integer only (T-08-80) — no unvalidated
# string ever reaches an `eww` argument.
_is_int() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

# _clamp <value> <lo> <hi> — degenerate ranges (hi<lo: a popup wider
# than the whole monitor) clamp flush to <lo> rather than computing
# an inverted range and emitting garbage coordinates.
_clamp() {
    local v="$1" lo="$2" hi="$3"
    if (( hi < lo )); then
        printf '%s' "$lo"
    elif (( v < lo )); then
        printf '%s' "$lo"
    elif (( v > hi )); then
        printf '%s' "$hi"
    else
        printf '%s' "$v"
    fi
}

# See the COORDINATE SPACE header note — converts an absolute,
# top-left-relative screen point into the offset this window's
# fixed `:anchor "top right"` expects.
_abs_to_anchor_offset_x() {
    local abs_x="$1" mon_x="$2" mon_w="$3"
    printf '%s' "$(( mon_x + mon_w - abs_x - POPUP_W ))"
}

_abs_to_anchor_offset_y() {
    local abs_y="$1" mon_y="$2"
    printf '%s' "$(( abs_y - mon_y ))"
}

# Invoked in ARRAY FORM — every value quoted, no eval, no `sh -c`,
# no unquoted command substitution in an argument position. `2>&1`
# is folded into `/dev/null` so a transient eww failure can never
# propagate a nonzero exit back into waybar's click handler.
_open_eww() {
    local eww_x="$1" eww_y="$2"
    _is_int "$eww_x" && _is_int "$eww_y" || return 1
    # Open the click-away backdrop first (behind the popup), then the popup.
    eww open media-backdrop >/dev/null 2>&1 || true
    eww open "$WINDOW_NAME" --arg "x=${eww_x}" --arg "y=${eww_y}" >/dev/null 2>&1 || true
}

# Prints "mon_x mon_y logical_w logical_h" for the monitor whose
# logical rectangle contains (cx,cy), or the focused monitor if none
# contains it, or nothing at all if neither resolves. Logical
# width/height divide the mode's physical pixels by scale — x/y are
# already logical layout coordinates but width/height are not, so a
# fractional-scale display would otherwise be sized wrong and the
# clamp computed against the wrong rectangle.
_monitor_rect_for_point() {
    local cx="$1" cy="$2" mons
    mons="$(hyprctl monitors -j 2>/dev/null)" || return 1
    jq -r --argjson cx "$cx" --argjson cy "$cy" '
        [ .[] | select(.disabled != true) |
          { x: .x, y: .y,
            w: ((.width  / .scale) | floor),
            h: ((.height / .scale) | floor),
            focused: (.focused // false) } ] as $m
        | ( [ $m[] | select(.x <= $cx and $cx < (.x + .w) and .y <= $cy and $cy < (.y + .h)) ][0]
            // [ $m[] | select(.focused) ][0] )
        | select(. != null)
        | "\(.x) \(.y) \(.w) \(.h)"
    ' <<<"$mons" 2>/dev/null
}

# Prints "mon_x mon_y logical_w logical_h" for the focused monitor
# (falling back to the first monitor in the list if none reports
# `focused`), or nothing if the monitor list can't be resolved.
_focused_monitor_rect() {
    local mons
    mons="$(hyprctl monitors -j 2>/dev/null)" || return 1
    jq -r '
        [ .[] | select(.disabled != true) |
          { x: .x, y: .y,
            w: ((.width  / .scale) | floor),
            h: ((.height / .scale) | floor),
            focused: (.focused // false) } ] as $m
        | ( [ $m[] | select(.focused) ][0] // $m[0] )
        | select(. != null)
        | "\(.x) \(.y) \(.w) \(.h)"
    ' <<<"$mons" 2>/dev/null
}

# ── `cursor` mode — read the pointer, clamp inside its monitor ──
_try_cursor_mode() {
    [[ "$HAVE_HYPRCTL" == "1" && "$HAVE_JQ" == "1" ]] || return 1

    local pos cx cy
    pos="$(hyprctl cursorpos 2>/dev/null)" || return 1
    # Verified live shape: "<int>, <int>" (observed: "1352, 941").
    # If it doesn't match this shape, never use it.
    [[ "$pos" =~ ^(-?[0-9]+),[[:space:]]*(-?[0-9]+)$ ]] || return 1
    cx="${BASH_REMATCH[1]}"
    cy="${BASH_REMATCH[2]}"
    _is_int "$cx" && _is_int "$cy" || return 1

    local rect mon_x mon_y mon_w mon_h
    rect="$(_monitor_rect_for_point "$cx" "$cy")" || return 1
    [[ -n "$rect" ]] || return 1
    read -r mon_x mon_y mon_w mon_h <<<"$rect"
    _is_int "$mon_x" && _is_int "$mon_y" && _is_int "$mon_w" && _is_int "$mon_h" || return 1

    local abs_x abs_y lo_x hi_x lo_y hi_y eww_x eww_y
    # Centre horizontally on the cursor, drop below it by CURSOR_GAP.
    abs_x=$(( cx - POPUP_W / 2 ))
    abs_y=$(( cy + CURSOR_GAP ))
    lo_x=$(( mon_x + EDGE_MARGIN )); hi_x=$(( mon_x + mon_w - POPUP_W - EDGE_MARGIN ))
    lo_y=$(( mon_y + EDGE_MARGIN )); hi_y=$(( mon_y + mon_h - POPUP_H - EDGE_MARGIN ))
    abs_x="$(_clamp "$abs_x" "$lo_x" "$hi_x")"
    abs_y="$(_clamp "$abs_y" "$lo_y" "$hi_y")"

    eww_x="$(_abs_to_anchor_offset_x "$abs_x" "$mon_x" "$mon_w")"
    eww_y="$(_abs_to_anchor_offset_y "$abs_y" "$mon_y")"
    _open_eww "$eww_x" "$eww_y"
}

# ── `fixed` mode — D-23's pre-authorised fallback ────────────────
_try_fixed_mode() {
    if [[ "$HAVE_HYPRCTL" == "1" && "$HAVE_JQ" == "1" ]]; then
        local rect mon_x mon_y mon_w mon_h
        rect="$(_focused_monitor_rect)" || rect=""
        if [[ -n "$rect" ]]; then
            read -r mon_x mon_y mon_w mon_h <<<"$rect"
            if _is_int "$mon_x" && _is_int "$mon_y" && _is_int "$mon_w" && _is_int "$mon_h"; then
                local abs_x abs_y lo_x hi_x lo_y hi_y eww_x eww_y
                abs_x=$(( mon_x + mon_w - POPUP_W - FIXED_OFFSET ))
                abs_y=$(( mon_y + FIXED_OFFSET ))
                lo_x=$(( mon_x + EDGE_MARGIN )); hi_x=$(( mon_x + mon_w - POPUP_W - EDGE_MARGIN ))
                lo_y=$(( mon_y + EDGE_MARGIN )); hi_y=$(( mon_y + mon_h - POPUP_H - EDGE_MARGIN ))
                abs_x="$(_clamp "$abs_x" "$lo_x" "$hi_x")"
                abs_y="$(_clamp "$abs_y" "$lo_y" "$hi_y")"
                eww_x="$(_abs_to_anchor_offset_x "$abs_x" "$mon_x" "$mon_w")"
                eww_y="$(_abs_to_anchor_offset_y "$abs_y" "$mon_y")"
                if _open_eww "$eww_x" "$eww_y"; then
                    return 0
                fi
            fi
        fi
    fi
    # Degraded path — hyprctl/jq unavailable, or monitor data
    # unusable: this window's own static `:anchor "top right"`
    # already IS "near the top-right corner", so a bare FIXED_OFFSET
    # pair needs no monitor geometry at all (RESEARCH VERDICT 2's own
    # "zero new moving parts" framing for this fallback).
    _open_eww "$FIXED_OFFSET" "$FIXED_OFFSET"
}

# ── Toggle ───────────────────────────────────────────────────────
# If the popup is already open, this click means "close" — tear down
# BOTH the popup and its backdrop and exit. Handled here (rather than
# `eww open --toggle`) so the backdrop is never orphaned open.
if eww active-windows 2>/dev/null | grep -q '^media-popup:'; then
    eww close media-popup media-backdrop >/dev/null 2>&1 || true
    exit 0
fi

# ── Dispatch ─────────────────────────────────────────────────────
# Never send waybar a hide/reload signal from here — 08-03 is the
# sole owner of waybar visibility (D-08: overlays are not a
# visibility intent). Opening this popup leaves the bar's own state
# untouched in both directions.
if [[ "$ANCHOR_MODE" == "cursor" ]]; then
    _try_cursor_mode || _try_fixed_mode
else
    _try_fixed_mode
fi

exit 0
