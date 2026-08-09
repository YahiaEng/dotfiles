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

# UTIL-05/D-19: font is a theme-orthogonal state axis (same shape as
# wallpaper.sh's last-wallpaper/ precedent) — lib/font.sh owns its own
# render path (kitty-font.conf, waybar-font.css) and the read helper this
# file's own theme_engine_render_gtk_settings uses for gtk-font-name below.
# shellcheck source=lib/font.sh
source "$LIB_DIR/font.sh"

# TOKEN-03/D-01: motion is the THIRD theme-orthogonal state axis (after
# icon-theme and font-choice) — lib/motion.sh owns its own render path
# (motion.json, gtk-4.0-motion.css, hyprland-tokens.lua) and its own
# render-time validation pass (D-02(a)/D-09), same call-site shape as
# font.sh directly above. (13.1-10: the sibling hyprland-motion.conf
# hyprlang fragment this comment used to also name was retired.)
# shellcheck source=lib/motion.sh
source "$LIB_DIR/motion.sh"

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

    # UTIL-05/D-19: font-choice is re-rendered on EVERY run regardless of
    # which theme/mode is active (independent axis, same call-site shape as
    # the gtk-settings render right above it).
    theme_engine_render_font_files "$tmp"

    # TOKEN-03/D-01: motion is the third theme-orthogonal axis, re-rendered
    # on EVERY run regardless of which theme/mode is active — same shape as
    # the font-choice render right above it. Its return is propagated (not
    # swallowed): a failed motion render must fail the whole generate step,
    # since the emitted hyprland-tokens.lua table is one Hyprland's
    # `require()` will load, and theme-apply already routes a non-zero
    # return here into .last-render-error.log while leaving the desktop
    # unchanged.
    theme_engine_render_motion_files "$tmp" || return 1

    # TOKEN-03/D-01/D-34: sass precompile of GTK3-consumed stylesheets — a
    # fourth sibling writer, same shape and same propagated-never-swallowed
    # discipline as motion_files right above it. Runs INSIDE
    # theme_engine_generate, against the tmp tree, so a failed compile
    # commits nothing and the atomic render-then-commit invariant holds
    # unchanged (commit.sh only runs after this whole function returns 0).
    # Must run AFTER theme_engine_render_motion_files: it consumes the
    # _motion.scss partial that call just wrote into this same tmp tree.
    theme_engine_compile_gtk3_stylesheets "$tmp" || return 1

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

    # UTIL-05/D-19/Pitfall 6: font is a second theme-orthogonal state axis,
    # same discipline as icon_theme directly above — read here (this SAME
    # function that owns every other GTK-signal write) so a later theme
    # switch never silently reverts a user's font pick back to the old
    # hardcoded "FiraCode Nerd Font 11" literal. lib/font.sh's read helper
    # (backed by ~/.local/state/theme/font-choice) is the single source of
    # truth for the default fallback value.
    local font_name
    font_name="$(theme_engine_read_font)"

    local out_dir="$tmp$STATE_DIR"
    mkdir -p "$out_dir"

    # gtk-3.0: mode-driven lines first, then the three remaining static
    # lines copied verbatim from the current stowed file (D-07: cursor/font
    # untouched by mode).
    # D-32 (Phase 17 plan 05, option-c): cursor theme moved from
    # Bibata-Modern-Classic to BreezeX-RosePine-Linux — the real installed
    # directory name of the `rose-pine-cursor` AUR package (NOT the
    # package name itself, confirmed by reading its PKGBUILD's package()
    # function and verified present on disk before this edit landed). This
    # is the XCursor-format half of the same BreezeX-remixed-to-Rose-Pine
    # shape family as `rose-pine-hyprcursor` (see that package's own
    # manifest.hl description) — the two are deliberately paired so every
    # consumer, XCursor or hyprcursor, renders the same shapes and colors.
    printf '[Settings]\ngtk-application-prefer-dark-theme=%s\ngtk-theme-name=%s\ngtk-icon-theme-name=%s\ngtk-cursor-theme-name=BreezeX-RosePine-Linux\ngtk-cursor-theme-size=24\ngtk-font-name=%s 11\n' \
        "$dark_theme_flag" "$gtk3_theme_name" "$icon_theme" "$font_name" > "$out_dir/gtk-3.0-settings.ini"

    # gtk-4.0: same key set minus gtk-theme-name (GTK4 does not use it,
    # matching the current stowed gtk-4.0/settings.ini).
    printf '[Settings]\ngtk-application-prefer-dark-theme=%s\ngtk-icon-theme-name=%s\ngtk-cursor-theme-name=BreezeX-RosePine-Linux\ngtk-cursor-theme-size=24\ngtk-font-name=%s 11\n' \
        "$dark_theme_flag" "$icon_theme" "$font_name" > "$out_dir/gtk-4.0-settings.ini"
}
