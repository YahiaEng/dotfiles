#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║      CHEAT-SHEET — "View all" kitty table (D-29b)     ║
# ║  Launcher shim (icon-theme-switch.sh's exact shape)     ║
# ║  PLUS the table renderer, in one file: a bare           ║
# ║  invocation opens a floating kitty window that          ║
# ║  re-invokes this same script with --render, which        ║
# ║  prints the column-aligned, section-grouped table and    ║
# ║  waits for a keypress (a reference table, not a picker — ║
# ║  no fzf needed). Sources the SAME shared parser           ║
# ║  cheat-sheet.sh uses (D-29) — no second grep/awk copy.    ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

SCRIPT_REAL="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_REAL")"

# render_table
# The kitty-side half: sources cheat-sheet-parser.sh (D-29 — the single
# shared implementation, never a second extraction regex), prints a
# column-aligned table grouped by keybinds.conf's own "# ── Section ──"
# banners, then waits for a keypress. Live-parsed on every open (D-31).
render_table() {
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/cheat-sheet-parser.sh"

    local sections=() chords=() descs=()
    local section chord desc
    while IFS=$'\t' read -r section chord desc; do
        sections+=("$section")
        chords+=("$chord")
        descs+=("$desc")
    done < <(cheat_sheet_parse_binds)

    local chord_w=5   # min width = len("CHORD")
    local i
    for i in "${!chords[@]}"; do
        (( ${#chords[$i]} > chord_w )) && chord_w="${#chords[$i]}"
    done

    printf '\033[1m%-*s  %s\033[0m\n' "$chord_w" "CHORD" "DESCRIPTION"
    printf '%.0s─' $(seq 1 $((chord_w + 2 + 11)))
    printf '\n'

    local current_section=""
    for i in "${!chords[@]}"; do
        if [[ "${sections[$i]}" != "$current_section" ]]; then
            current_section="${sections[$i]}"
            printf '\n\033[1m%s\033[0m\n' "$current_section"
        fi
        printf '%-*s  %s\n' "$chord_w" "${chords[$i]}" "${descs[$i]}"
    done

    printf '\nPress any key to close...'
    read -rn1 -s -t 300 || true
    printf '\n'
}

if [[ "${1:-}" == "--render" ]]; then
    render_table
    exit 0
fi

exec uwsm app -- kitty \
    --class "cheat-sheet" \
    --title "Keybinds" \
    -o background_opacity=0.85 \
    -o font_size=11 \
    -- "$SCRIPT_REAL" --render
