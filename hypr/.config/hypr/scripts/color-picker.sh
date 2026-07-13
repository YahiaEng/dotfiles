#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              COLOR PICKER (hyprpicker)                ║
# ║  Grabs a screen color as hex, copies it to the         ║
# ║  clipboard, and shows a swatch notification (D-22).    ║
# ╚══════════════════════════════════════════════════════╝
set -euo pipefail

# Security Domain T-06-18: truncate + strip control chars before any
# subprocess error text reaches notify-send (theme-apply's own
# sanitized-error pattern, reused verbatim per 06-PATTERNS.md).
sanitize() {
    head -c 200 | tr -d '\000-\011\013\014\016-\037'
}

if ! command -v hyprpicker >/dev/null 2>&1; then
    notify-send -a "Color Picker" "Error" "hyprpicker not installed" -i dialog-error -t 6000 2>/dev/null || true
    exit 1
fi

ERR_FILE=$(mktemp /tmp/color-picker-err-XXXXXX)
trap 'rm -f "$ERR_FILE"' EXIT

OUT=""
if ! OUT=$(hyprpicker -a -f hex 2>"$ERR_FILE"); then
    # WR-01: hyprpicker only logs to stdout (upstream Log.cpp), never
    # stderr — classify failure by the COMBINED stream content, not by
    # empty stderr alone, or every genuine failure silently takes the
    # cancel path.
    ERR=$(printf '%s\n%s' "$(cat "$ERR_FILE")" "$OUT" | sanitize)
    if [[ -z "$ERR" ]]; then
        exit 0 # user cancelled (Esc) — hyprpicker exits nonzero silently
    fi
    notify-send -a "Color Picker" "Error" "$ERR" -i dialog-error -t 6000 2>/dev/null || true
    exit 1
fi

# WR-01 secondary: a compositor that emits WARN lines to stdout during a
# successful pick would otherwise concatenate them into HEX — take only
# the last line before stripping whitespace, then require a genuine
# six-hex-digit colour before it is ever handed to wl-copy.
HEX=$(printf '%s\n' "$OUT" | tail -n1 | tr -d '[:space:]')
[[ "$HEX" =~ ^#?[0-9a-fA-F]{6}$ ]] || exit 1

printf '%s' "$HEX" | wl-copy

# Swatch image hint: generate a small solid-color PNG for the notification
# icon when ImageMagick is available; degrade to the plain "color-picker"
# freedesktop icon (text-only hex) otherwise — no hard dependency on
# image-hint support (UI-SPEC Copywriting).
ICON="color-picker"
if command -v convert >/dev/null 2>&1; then
    SWATCH=$(mktemp --suffix=.png /tmp/color-picker-swatch-XXXXXX)
    HEX_CSS="$HEX"
    [[ "$HEX_CSS" != \#* ]] && HEX_CSS="#$HEX_CSS"
    if convert -size 64x64 "xc:${HEX_CSS}" "$SWATCH" 2>/dev/null; then
        ICON="$SWATCH"
    else
        rm -f "$SWATCH"
    fi
fi

notify-send -a "Color Picker" "Color Copied" "$HEX copied to clipboard" -i "$ICON" -t 2500 2>/dev/null || true

if [[ "$ICON" != "color-picker" ]]; then
    rm -f "$ICON"
fi
