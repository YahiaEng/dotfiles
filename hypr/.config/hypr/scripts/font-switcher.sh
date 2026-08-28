#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║   NERD FONT SWITCHER — machine-facing backend, no interactive UI  ║
# ║                                                                    ║
# ║  D-03 (quick task 260828-ah9): the fzf-in-floating-kitty picker    ║
# ║  and its live rendered specimen are RETIRED. The live-per-family   ║
# ║  specimen was the only thing this script offered that the QML     ║
# ║  surfaces (the Atelier's Fonts tab, the launcher's `font` route)   ║
# ║  could not — so the QML now owns the interactive half, and this    ║
# ║  script keeps exactly the tail every one of those surfaces calls:  ║
# ║                                                                    ║
# ║    --list         installed nerd-font family names                ║
# ║    --set <name>   persist + re-apply (state write, VSCodium        ║
# ║                   settings merge, theme-apply re-run, notify)      ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# UTIL-05/D-18/D-19: font choice is a theme-orthogonal state axis (same
# discipline as icon-theme-picker.sh/D-19's icon-theme axis) — this script
# WRITES the font-choice state file and re-runs theme-apply so lib/font.sh
# (kitty-font.conf) and generate.sh's gtk-font-name read own the actual
# render, never a bare one-off write to any surface.

set -euo pipefail

FONT_STATE="$HOME/.local/state/theme/font-choice"
CURRENT_THEME_FILE="$HOME/.local/state/theme/current-theme"
VSCODIUM_SETTINGS="$HOME/.config/VSCodium/User/settings.json"

# ── The whole surface this script offers now (quick-260821-6z1 Task 10,
#    R-6; interactive half retired in quick task 260828-ah9, D-03) —
#    `--list`/`--set <name>`. `--list` runs the same real
#    `fc-list : family` enumeration this script has always used (never a
#    hardcoded list). `_persist_and_apply()` is the one tail every QML
#    surface's apply call runs through (state write, VSCodium settings
#    merge, theme-apply re-run, notify) — one copy, every caller. ─────
_list_fonts() {
    # `|| true` on the whole pipeline (icon-theme-picker.sh bug class,
    # quick-260821-6z1 fix wave finding 1): a `grep` mid-pipeline that
    # matches nothing exits non-zero, and under this script's own
    # `set -euo pipefail` that would abort the whole script here — an
    # empty match set is a normal "no nerd fonts found" outcome, not an
    # error, so it must not kill the caller.
    fc-list : family 2>/dev/null | cut -d',' -f1 | grep -i 'nerd' \
        | grep -vx 'Symbols Nerd Font' | sort -u || true
}

_persist_and_apply() {
    local selected="$1"

    mkdir -p "$(dirname "$FONT_STATE")"
    printf '%s\n' "$selected" > "$FONT_STATE.tmp" && mv "$FONT_STATE.tmp" "$FONT_STATE"

    if command -v jq >/dev/null 2>&1; then
        mkdir -p "$(dirname "$VSCODIUM_SETTINGS")"
        [[ -f "$VSCODIUM_SETTINGS" ]] || echo '{}' > "$VSCODIUM_SETTINGS"

        local fragment_file
        fragment_file=$(mktemp /tmp/font-vscodium-fragment-XXXXXX.json)
        jq -n --arg editor "'${selected}', 'Fira Code', monospace" \
              --arg term "'${selected}'" \
              '{ "editor.fontFamily": $editor, "terminal.integrated.fontFamily": $term }' \
            > "$fragment_file"

        jq -s '.[0] * .[1]' "$VSCODIUM_SETTINGS" "$fragment_file" > "${VSCODIUM_SETTINGS}.tmp" 2>/dev/null \
            && mv "${VSCODIUM_SETTINGS}.tmp" "$VSCODIUM_SETTINGS" \
            || rm -f "${VSCODIUM_SETTINGS}.tmp"
        rm -f "$fragment_file"
    fi

    local active_preset
    active_preset=$(cat "$CURRENT_THEME_FILE" 2>/dev/null || echo "")
    if [[ -n "$active_preset" ]]; then
        ~/.config/theme-engine/theme-apply "$active_preset"
    else
        echo "font-switcher: no active theme recorded yet — font-choice saved, will apply on the next theme-apply run" >&2
    fi

    notify-send -a "Font Switcher" "Font Changed" \
        "Applied $selected — restart apps to see the full effect" \
        -i preferences-desktop-font -t 2500 2>/dev/null || true
}

case "${1:-}" in
    --list)
        _list_fonts
        exit 0
        ;;
    --set)
        NAME="${2:-}"
        [[ -n "$NAME" ]] || { echo "font-switcher.sh --set: name required" >&2; exit 1; }
        VALID=0
        while IFS= read -r _n; do
            [[ "$_n" == "$NAME" ]] && { VALID=1; break; }
        done < <(_list_fonts)
        [[ "$VALID" -eq 1 ]] \
            || { echo "font-switcher.sh --set: '$NAME' did not resolve to an enumerated nerd font" >&2; exit 1; }
        _persist_and_apply "$NAME"
        exit 0
        ;;
esac
