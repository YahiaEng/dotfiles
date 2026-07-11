#!/usr/bin/env bash
# theme-engine/lib/wallpaper.sh — static-preset wallpaper auto-set (D-11/D-12)
#
# Only called for static presets, after theme_engine_commit succeeds and
# before theme_engine_reload — so a themed desktop lands with a matching
# wallpaper in one action (CONTEXT "Omarchy-style one-action coherence").
# Material You keeps the existing wallpaper-drives-palette direction (D-11):
# this function is a no-op for both materialyou and materialyou-light.
#
# Every step here is best-effort (`|| true`) — auto-set is cosmetic and must
# never fail theme-apply's exit code (Shared Patterns: best-effort, never-
# block error handling).

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
LAST_WALLPAPER_DIR="$HOME/.local/state/theme/last-wallpaper"

# theme_engine_wallpaper_autoset <name>
theme_engine_wallpaper_autoset() {
    local name="$1"

    # D-11: dynamic mode keeps wallpaper -> palette direction; auto-set is
    # static-only. Never touch current.jpg for either Material You name.
    if [[ "$name" == "materialyou" || "$name" == "materialyou-light" ]]; then
        return 0
    fi

    local theme_dir="$WALLPAPER_DIR/$name"
    [[ -d "$theme_dir" ]] || return 0

    # Same extension filter + enumeration idiom as wallpaper-picker.sh
    # (maxdepth 1, filename-only, exclude current.jpg — Security Domain V5:
    # never trust raw interpolation, enumerate real files only).
    local images
    images=$(find "$theme_dir" -maxdepth 1 \
        -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) \
        ! -name "current.jpg" \
        -printf "%f\n" 2>/dev/null | sort)

    # Empty/missing set — keep the current wallpaper untouched (D-12 never-
    # a-dead-end semantics on the apply side).
    [[ -n "$images" ]] || return 0

    # Candidate selection: prefer the recorded last-used file for this
    # theme, validated as a bare filename that actually exists inside the
    # theme's folder (T-05-07 mitigation — never interpolate untrusted
    # state-file content into a path without validation).
    local chosen=""
    local last_used_file="$LAST_WALLPAPER_DIR/$name"
    if [[ -f "$last_used_file" ]]; then
        local recorded
        recorded=$(head -n1 "$last_used_file" 2>/dev/null || true)
        if [[ -n "$recorded" && "$recorded" != */* && -f "$theme_dir/$recorded" ]]; then
            chosen="$recorded"
        fi
    fi

    # Fall back to the first image in the folder by sorted name (D-11).
    if [[ -z "$chosen" ]]; then
        chosen=$(head -n1 <<< "$images")
    fi

    [[ -n "$chosen" ]] || return 0

    # Apply: repoint current.jpg at the chosen file.
    ln -sfr "$theme_dir/$chosen" "$WALLPAPER_DIR/current.jpg" 2>/dev/null || true

    # Best-effort live preview — only when a graphical session is present
    # (same WAYLAND_DISPLAY/DBUS_SESSION_BUS_ADDRESS guard shape as
    # reload.sh's headless guard) and awww is on PATH. The headless
    # container gate must never hang here.
    if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && command -v awww >/dev/null 2>&1; then
        awww img "$theme_dir/$chosen" \
            --transition-type center \
            --transition-duration 1 \
            --transition-fps 165 2>/dev/null || true
    fi

    # Write-back: atomic temp-file + mv idiom (matches commit.sh's
    # current-theme write) — cosmetic, must never fail theme-apply.
    mkdir -p "$LAST_WALLPAPER_DIR" 2>/dev/null || true
    printf '%s\n' "$chosen" > "$last_used_file.tmp" 2>/dev/null \
        && mv "$last_used_file.tmp" "$last_used_file" 2>/dev/null || true

    return 0
}
