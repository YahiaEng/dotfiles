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
# WR-04: report-only callers (theme-parity) must not truncate the LIVE
# error log — it may hold the diagnosis of a real theme-apply failure.
# They can redirect renders elsewhere via THEME_ENGINE_RENDER_LOG, set
# before sourcing this file. Default (theme-apply path) is unchanged.
GENERATE_LOG="${THEME_ENGINE_RENDER_LOG:-$HOME/.local/state/theme/.last-render-error.log}"

# THM-01: mode.sh is the single source of truth for light/dark
# classification. LIB_DIR is defined by every caller (theme-apply,
# theme-parity) before sourcing this file.
# shellcheck source=lib/mode.sh
source "$LIB_DIR/mode.sh"

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

    if [[ "$name" == "materialyou" || "$name" == "materialyou-light" ]]; then
        local wallpaper
        wallpaper=$(readlink -f "$WALLPAPER_LINK" 2>/dev/null || echo "$WALLPAPER_LINK")

        if [[ ! -f "$wallpaper" ]]; then
            echo "No wallpaper found. Use the wallpaper picker first." > "$GENERATE_LOG"
            return 1
        fi

        # D-05: materialyou-light is an explicit user choice — matugen's -m
        # flag genuinely changes the M3 tonal-palette derivation for the
        # image branch (verified empirically, RESEARCH Pattern 2). materialyou
        # stays implicitly dark, matching the pre-existing default behavior.
        local mode_flag="dark"
        [[ "$name" == "materialyou-light" ]] && mode_flag="light"

        if ! matugen image "$wallpaper" --source-color-index 0 -m "$mode_flag" \
                -c "$MATUGEN_CFG" -p "$tmp" 2>"$GENERATE_LOG"; then
            return 1
        fi
    else
        local palette="$PALETTES_DIR/$name.json"

        # RESEARCH Pitfall 1: matugen's -m flag is a verified no-op when
        # every color key already has a literal hex value — never add it
        # here. Mode for static presets is a wholly separate computation
        # (theme_engine_detect_mode), decoupled from matugen entirely.
        if ! matugen json "$palette" -c "$MATUGEN_CFG" -p "$tmp" 2>"$GENERATE_LOG"; then
            return 1
        fi
    fi

    # THM-01: mode resolves during render, before commit, so a failed
    # render never reaches this point and the desktop stays on the old
    # mode until a successful switch (atomic render-then-commit invariant).
    local mode
    mode="$(theme_engine_detect_mode "$name")"

    mkdir -p "$tmp$STATE_DIR"
    printf '%s\n' "$mode" > "$tmp$STATE_DIR/mode"

    theme_engine_render_gtk_settings "$mode" "$tmp"

    return 0
}

# theme_engine_render_gtk_settings <mode> <tmp_dir>
# Renders both gtk-3.0/settings.ini and gtk-4.0/settings.ini into the tmp
# render tree (D-07/D-08). Shell-side printf, not a matugen template — mode
# is a computed engine value (theme_engine_detect_mode), and matugen has no
# mode-conditional templating (RESEARCH Open Question 3). Keeps GTK-signal
# content in engine shell code, same place gtk.sh already owns every other
# GTK-signal write.
theme_engine_render_gtk_settings() {
    local mode="$1"
    local tmp="$2"

    local dark_theme_flag="1"
    local gtk3_theme_name="adw-gtk3-dark"
    if [[ "$mode" == "light" ]]; then
        dark_theme_flag="0"
        gtk3_theme_name="adw-gtk3"
    fi

    # D-19/UTIL-04/Pitfall 6: icon-theme is a theme-orthogonal state axis,
    # not a mode-derived value — read it here (same function that owns every
    # other GTK-signal write) so a later theme switch never silently reverts
    # a user's icon-theme pick back to the old hardcoded "Adwaita" literal.
    # commit.sh excludes this state file from its rsync --delete so it
    # survives every switch (D-19 pattern, same shape as last-wallpaper/).
    local icon_theme
    icon_theme="$(cat "$HOME/.local/state/theme/icon-theme" 2>/dev/null || echo Adwaita)"

    local out_dir="$tmp$STATE_DIR"
    mkdir -p "$out_dir"

    # gtk-3.0: mode-driven lines first, then the three remaining static
    # lines copied verbatim from the current stowed file (D-07: cursor/font
    # untouched by mode).
    printf '[Settings]\ngtk-application-prefer-dark-theme=%s\ngtk-theme-name=%s\ngtk-icon-theme-name=%s\ngtk-cursor-theme-name=Bibata-Modern-Classic\ngtk-cursor-theme-size=24\ngtk-font-name=FiraCode Nerd Font 11\n' \
        "$dark_theme_flag" "$gtk3_theme_name" "$icon_theme" > "$out_dir/gtk-3.0-settings.ini"

    # gtk-4.0: same key set minus gtk-theme-name (GTK4 does not use it,
    # matching the current stowed gtk-4.0/settings.ini).
    printf '[Settings]\ngtk-application-prefer-dark-theme=%s\ngtk-icon-theme-name=%s\ngtk-cursor-theme-name=Bibata-Modern-Classic\ngtk-cursor-theme-size=24\ngtk-font-name=FiraCode Nerd Font 11\n' \
        "$dark_theme_flag" "$icon_theme" > "$out_dir/gtk-4.0-settings.ini"
}
