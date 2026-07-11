#!/usr/bin/env bash
# theme-engine/lib/mode.sh — light/dark mode classification (THM-01, D-05/D-06)
#
# Single source of truth for "is this theme name light or dark". Every other
# file that needs a light/dark signal (generate.sh's render-time marker,
# gtk.sh's gsettings/GTK_THEME propagation) calls theme_engine_detect_mode
# rather than re-deriving the classification itself (single-owner discipline,
# same as lib/gtk.sh's theme_engine_gtk4_accent for accent-color mapping).

# theme_engine_detect_mode <name>
# name: "materialyou", "materialyou-light", or a validated static preset name
#       (theme-apply/generate.sh already checked palettes/$name.json exists).
# Echoes exactly "light" or "dark", always exit 0 (best-effort — a missing
# jq/python3 or an unreadable palette file must never fail the caller; it
# falls back to "dark", the pre-existing behavior).
theme_engine_detect_mode() {
    local name="$1"

    # D-05: materialyou/materialyou-light are explicit user choices, never
    # computed from palette contents.
    if [[ "$name" == "materialyou" ]]; then
        echo "dark"
        return 0
    fi
    if [[ "$name" == "materialyou-light" ]]; then
        echo "light"
        return 0
    fi

    local palette_json="$PALETTES_DIR/$name.json"

    if ! command -v jq >/dev/null 2>&1 || [[ ! -r "$palette_json" ]]; then
        echo "dark"
        return 0
    fi

    # D-06: optional top-level "mode" override key wins when present.
    local override
    override=$(jq -r '.mode // empty' "$palette_json" 2>/dev/null)
    if [[ "$override" == "light" || "$override" == "dark" ]]; then
        echo "$override"
        return 0
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        echo "dark"
        return 0
    fi

    local bg_hex
    bg_hex=$(jq -r '.colors.background.default.color // empty' "$palette_json" 2>/dev/null)
    if [[ -z "$bg_hex" ]]; then
        echo "dark"
        return 0
    fi

    # Perceptual lightness via the same python3 colorsys heredoc-with-
    # positional-arg technique already proven in theme_engine_gtk4_accent
    # (lib/gtk.sh) — lightness channel index [1], threshold 0.5 (05-UI-SPEC.md
    # mode-detection contract).
    local mode
    mode=$(python3 - "$bg_hex" <<'PYEOF' 2>/dev/null
import colorsys, sys
hexv = sys.argv[1].lstrip('#')
r, g, b = (int(hexv[i:i+2], 16) / 255.0 for i in (0, 2, 4))
l = colorsys.rgb_to_hls(r, g, b)[1]
print("light" if l > 0.5 else "dark")
PYEOF
)
    if [[ -z "$mode" ]]; then
        echo "dark"
        return 0
    fi

    echo "$mode"
}
