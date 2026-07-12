#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              THEME SWITCHER (walker)                 ║
# ║   Thin caller: only picks a name, theme-apply does    ║
# ║   the rendering + reload (D-01/PIPE-01).               ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

PALETTES_DIR="$HOME/.config/theme-engine/palettes"

# Security Domain V5 (T-05-06) — the picker list is built from the ACTUAL
# palette filenames (never a hardcoded case ladder, RESEARCH Pitfall 2)
# plus the two Material You literals theme-apply also accepts. Display
# names are prettified (hyphen -> space, title case) purely for the UI;
# the selection always maps back to the exact basename/literal via a
# parallel index-matched array, never a reverse string transform — and
# theme-apply re-validates the final name against palettes/*.json
# regardless (defense in depth).
prettify() {
    local raw="$1"
    local spaced="${raw//-/ }"
    local out=""
    local word
    for word in $spaced; do
        out+="${word^} "
    done
    echo "${out% }"
}

NAMES=()
DISPLAYS=()
for f in "$PALETTES_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f" .json)"
    NAMES+=("$name")
    DISPLAYS+=("$(prettify "$name")")
done

NAMES+=("materialyou" "materialyou-light")
DISPLAYS+=("Material You (Dynamic)" "Material You Light (Dynamic)")

# WR-04: distinguish a hard walker failure (nonzero exit — walker not
# running/installed, dead elephant socket) from a genuine user cancel
# (empty selection). Failure notifies and exits 1; cancel keeps exit 0.
if ! SELECTED=$(printf '%s\n' "${DISPLAYS[@]}" | walker --dmenu --placeholder "Select Theme"); then
    notify-send -a "Theme Switcher" "Error" "walker dmenu failed" -i dialog-error 2>/dev/null || true
    exit 1
fi
[[ -z "$SELECTED" ]] && exit 0   # genuine user cancel

THEME=""
for i in "${!DISPLAYS[@]}"; do
    if [[ "${DISPLAYS[$i]}" == "$SELECTED" ]]; then
        THEME="${NAMES[$i]}"
        break
    fi
done

[[ -z "$THEME" ]] && exit 1

exec ~/.config/theme-engine/theme-apply "$THEME"
