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
# shared implementation, never a second extraction regex) and renders a
# "reference card": one rounded panel per keybinds.conf "# ── Section ──"
# banner, masonry-packed into as many columns as the window can fit.
# Live-parsed on every open (D-31).
#
# THEMING: every colour below is an ANSI palette index (0-15), NOT a literal
# hex. kitty resolves those against its own matugen-rendered palette
# (~/.local/state/theme/kitty.conf), so this surface re-themes on every theme
# switch for free — no new matugen template, no new contract.json entry, no
# parity-gate surface. This is the whole reason the table lives inside kitty.
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

    (( ${#chords[@]} == 0 )) && { printf 'No keybinds found.\n'; return 1; }

    # ── Group rows under their section, preserving first-seen order ──
    local -a order=()
    local -A rows_of=()
    local i s
    for i in "${!sections[@]}"; do
        s="${sections[$i]}"
        [[ -z "${rows_of[$s]+set}" ]] && { order+=("$s"); rows_of["$s"]=""; }
        rows_of["$s"]+="${chords[$i]}"$'\t'"${descs[$i]}"$'\n'
    done

    # ── Panel geometry, driven by the widest real content ──
    local cw=0 dw=0
    for i in "${!chords[@]}"; do
        (( ${#chords[$i]} > cw )) && cw=${#chords[$i]}
        (( ${#descs[$i]} > dw )) && dw=${#descs[$i]}
    done
    for s in "${order[@]}"; do
        (( ${#s} > cw + dw + 2 )) && dw=$(( ${#s} - cw - 2 ))
    done
    local inner=$(( 2 + cw + 2 + dw + 2 ))   # padding, chord, gap, desc, padding
    local pw=$(( inner + 2 ))                # + the two border glyphs

    # ── Fit as many panel columns as the ACTUAL window allows ──
    local termw=${COLUMNS:-0}
    (( termw == 0 )) && termw=$(tput cols 2>/dev/null || echo 120)
    local gutter=2
    local ncols=$(( (termw + gutter) / (pw + gutter) ))
    (( ncols < 1 )) && ncols=1
    (( ncols > 4 )) && ncols=4

    local BOR=$'\033[2m'          # dim  — frame, recedes
    local TIT=$'\033[1;38;5;4m'   # bold accent — section name
    local CHD=$'\033[38;5;3m'     # accent — the chord (what you scan for)
    local DSC=$'\033[38;5;7m'     # muted — the description
    local RST=$'\033[0m'

    local rule=""
    printf -v rule '%*s' "$inner" ''
    rule="${rule// /─}"

    # ── Build each section panel as an array of fixed-visible-width lines ──
    # Every line is EXACTLY $pw visible columns wide, so panels can simply be
    # concatenated side by side without any escape-code-aware width maths.
    local -a panel_blob=() panel_h=()
    local body c d pad
    for s in "${order[@]}"; do
        body="${BOR}╭${rule}╮${RST}"$'\n'
        printf -v pad '%-*s' "$(( inner - 2 ))" "$s"
        body+="${BOR}│${RST}  ${TIT}${pad}${RST}${BOR}│${RST}"$'\n'
        body+="${BOR}├${rule}┤${RST}"$'\n'
        local n=0
        while IFS=$'\t' read -r c d; do
            [[ -z "$c" ]] && continue
            printf -v c '%-*s' "$cw" "$c"
            printf -v d '%-*s' "$dw" "$d"
            body+="${BOR}│${RST}  ${CHD}${c}${RST}  ${DSC}${d}${RST}  ${BOR}│${RST}"$'\n'
            n=$(( n + 1 ))
        done <<<"${rows_of[$s]}"
        body+="${BOR}╰${rule}╯${RST}"
        panel_blob+=("$body")
        panel_h+=( $(( n + 4 )) )
    done

    # ── Masonry: drop each panel into the currently shortest column ──
    local -a col_lines=() col_h=()
    for (( i = 0; i < ncols; i++ )); do col_lines[i]=""; col_h[i]=0; done
    local p target
    for p in "${!panel_blob[@]}"; do
        target=0
        for (( i = 1; i < ncols; i++ )); do
            (( col_h[i] < col_h[target] )) && target=$i
        done
        [[ -n "${col_lines[target]}" ]] && { col_lines[target]+=$'\n'; col_h[target]=$(( col_h[target] + 1 )); }
        col_lines[target]+="${panel_blob[$p]}"$'\n'
        col_h[target]=$(( col_h[target] + panel_h[p] ))
    done

    # ── Header ──
    local theme="unknown"
    [[ -r "$HOME/.local/state/theme/current-theme" ]] && theme=$(<"$HOME/.local/state/theme/current-theme")
    theme="${theme//[$'\n\r']/}"
    printf '\n  \033[1mKEYBINDS\033[0m  %s%s · %s binds%s\n\n' "$DSC" "$theme" "${#chords[@]}" "$RST"

    # ── Emit the columns side by side ──
    # Split each column into its lines ONCE, into a (col,row) grid — not once
    # per output row, which would re-split every column on every line.
    local -A grid=()
    local -a split=()
    local maxh=0 r
    for (( i = 0; i < ncols; i++ )); do
        mapfile -t split <<<"${col_lines[$i]}"
        for (( r = 0; r < ${#split[@]}; r++ )); do
            grid["$i,$r"]="${split[$r]}"
        done
        (( ${#split[@]} > maxh )) && maxh=${#split[@]}
    done

    local out blank
    printf -v blank '%*s' "$pw" ''
    for (( r = 0; r < maxh; r++ )); do
        out="  "
        for (( i = 0; i < ncols; i++ )); do
            if [[ -n "${grid[$i,$r]:-}" ]]; then
                out+="${grid[$i,$r]}"
            else
                out+="$blank"
            fi
            (( i < ncols - 1 )) && out+="  "
        done
        # trailing filler on the last column is pure whitespace — trim it
        printf '%s\n' "${out%"${out##*[![:space:]]}"}"
    done

    printf '\n  %sPress any key to close…%s' "$DSC" "$RST"
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
    -o font_size=10 \
    -- "$SCRIPT_REAL" --render
