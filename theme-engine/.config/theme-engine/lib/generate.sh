#!/usr/bin/env bash
# theme-engine/lib/generate.sh — render step (D-03/D-14)
#
# Renders EITHER a static preset (matugen json) OR the wallpaper-driven
# Material You palette (matugen image) through the SAME matugen templates
# into a fresh temp prefix. Both branches use the same config.toml — parity
# by construction (D-03). Nothing here touches the live desktop; commit.sh
# only runs after this succeeds (D-14 atomic render-then-commit).

MATUGEN_CFG="$HOME/.config/matugen/config.toml"
WALLPAPER_LINK="$HOME/Pictures/Wallpapers/current.jpg"
GENERATE_LOG="$HOME/.local/state/theme/.last-render-error.log"

# theme_engine_generate <name> <tmp_dir>
# name: "materialyou" or a validated static preset name (theme-apply already
#       checked palettes/$name.json exists before calling this).
# Returns 0 on success (files rendered under $tmp_dir), 1 on failure. Full
# matugen stderr is captured to GENERATE_LOG (Security Domain — notification
# content injection: raw stderr must never go straight to notify-send).
theme_engine_generate() {
    local name="$1"
    local tmp="$2"

    mkdir -p "$(dirname "$GENERATE_LOG")"

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

    return 0
}
