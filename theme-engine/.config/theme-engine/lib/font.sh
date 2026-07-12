#!/usr/bin/env bash
# theme-engine/lib/font.sh — nerd-font theme-orthogonal state axis (UTIL-05, D-18/D-19)
#
# Font choice is independent of theme identity (D-19): its own state file
# under $STATE_DIR, excluded from commit.sh's rsync --delete (same pattern
# as last-wallpaper/), read here and re-rendered on EVERY theme-apply run
# regardless of which theme/mode is active. Mirrors theme-engine/lib/
# wallpaper.sh's per-axis state-file precedent (RESEARCH Pattern 1).
#
# This function only renders the two fragments that have no other owner:
# kitty-font.conf (consumed by kitty.conf's second `include`) and
# waybar-font.css (consumed by the three style-*.css files' second
# `@import`). The GTK gtk-font-name key is folded into generate.sh's
# EXISTING theme_engine_render_gtk_settings printf call instead of a
# separate write (Pitfall 6 discipline — never a second parallel settings
# writer for a key already owned by that function).

FONT_STATE_FILE="$HOME/.local/state/theme/font-choice"
FONT_DEFAULT="FiraCode Nerd Font"

# theme_engine_read_font
# Echoes the current font-choice state value, or the default when the axis
# has never been set (fresh install / before the first font-switch).
theme_engine_read_font() {
    cat "$FONT_STATE_FILE" 2>/dev/null || echo "$FONT_DEFAULT"
}

# theme_engine_render_font_files <tmp_dir>
# Renders kitty-font.conf + waybar-font.css into the tmp render tree from
# the font-choice state (called from generate.sh's theme_engine_generate,
# alongside theme_engine_render_gtk_settings — same call-site shape).
theme_engine_render_font_files() {
    local tmp="$1"
    local font_name
    font_name="$(theme_engine_read_font)"

    local out_dir="$tmp$STATE_DIR"
    mkdir -p "$out_dir"

    # kitty: included by kitty.conf's SECOND include line (added in Task 2)
    # — this fragment wins over the hardcoded fresh-install fallback lines
    # 12-16 since it is included after them.
    printf 'font_family      %s\nbold_font        %s Bold\nitalic_font      %s Italic\nbold_italic_font %s Bold Italic\n' \
        "$font_name" "$font_name" "$font_name" "$font_name" > "$out_dir/kitty-font.conf"

    # waybar: @import'd by the three style-*.css files' second @import line
    # (added in Task 2) — waybar-font.css is the SOLE owner of waybar's
    # font-family (the per-stylesheet `* { }` literal was removed in gap
    # plan 06-10/CR-01), so import ordering is no longer load-bearing here.
    # Font Awesome fallback kept so waybar's icon-font module glyphs keep
    # resolving regardless of the chosen nerd-font family.
    printf '* {\n    font-family: "%s", "Font Awesome 6 Free";\n}\n' \
        "$font_name" > "$out_dir/waybar-font.css"
}
