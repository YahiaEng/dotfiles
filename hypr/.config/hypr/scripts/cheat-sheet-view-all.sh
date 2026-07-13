#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║      CHEAT-SHEET — "View all" kitty card (D-29b)      ║
# ║  Launcher shim (icon-theme-switch.sh's exact shape)     ║
# ║  PLUS the card renderer, in one file: a bare            ║
# ║  invocation opens a floating kitty window that          ║
# ║  re-invokes this same script with --render, which        ║
# ║  draws the reference card and waits for a keypress       ║
# ║  (a reference surface, not a picker — no fzf needed).    ║
# ║  Sources the SAME shared parser cheat-sheet.sh uses      ║
# ║  (D-29) — never a second grep/awk copy.                  ║
# ╚══════════════════════════════════════════════════════╝
#
# THEMING: every colour below is an ANSI palette index (0-15), NOT a literal
# hex. kitty resolves those against its own matugen-rendered palette
# (~/.local/state/theme/kitty.conf), so this surface re-themes on every theme
# switch for free — no new matugen template, no new contract.json entry, no
# new parity-gate surface. That is the whole reason the card lives in kitty.
#
# GLYPHS: every codepoint used below (key symbols, section icons, the banner's
# box-drawing) was verified against the INSTALLED font — FiraCode Nerd Font —
# for BOTH cmap presence AND hmtx advance width: all confirmed present and
# exactly 1.00 cells wide, so no glyph can shift a box border. This follows the
# project's standing rule (Phase 6): resolve glyphs from the installed font,
# never from an unverified cheat-sheet copy. U+229E (⊞) was the natural Super
# symbol and is NOT in this font — hence  (U+F17A). If the font ever changes,
# re-run that check before trusting this file's alignment.

set -euo pipefail

SCRIPT_REAL="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_REAL")"

# _cs_icon <section-name>
# A verified Nerd Font icon per section. Unknown/future sections fall back to a
# star rather than rendering an empty cell or a tofu box.
_cs_icon() {
    case "$1" in
        Core)                          printf '\uf489' ;;
        Launchers)                     printf '\uf135' ;;
        "Escape hatch")                printf '\uf0e7' ;;
        "Custom menus")                printf '\uf0c9' ;;
        Clipboard)                     printf '\uf0ea' ;;
        Screenshots)                   printf '\uf030' ;;
        Utilities)                     printf '\uf0ad' ;;
        "Notification center")         printf '\uf0f3' ;;
        "Lock screen")                 printf '\uf023' ;;
        "Move focus")                  printf '\uf002' ;;
        "Move windows")                printf '\uf0b2' ;;
        "Resize windows")              printf '\uf065' ;;
        "Switch workspaces")           printf '\uf009' ;;
        "Move to workspace")           printf '\uf108' ;;
        "Special workspace"*)          printf '\uf06e' ;;
        "Scroll through workspaces")   printf '\uf0ec' ;;
        "Mouse bindings")              printf '\uf245' ;;
        "Audio controls")              printf '\uf028' ;;
        Brightness)                    printf '\uf185' ;;
        "Media controls")              printf '\uf001' ;;
        *)                             printf '\uf005' ;;
    esac
}

# _cs_keycap <chord>
# Renders a chord ("Super+Shift+left") as reverse-video keycap chips, setting:
#   CAP_PLAIN — visible text, used ONLY for width/padding maths
#   CAP_COLOR — the same thing with escapes, used for output
# Keeping the two in lockstep is what keeps the box borders aligned: never
# measure a string that has ANSI escapes in it.
#
# The PARSER deliberately still emits plain text: the walker surface searches
# it, so "Super+Z" must stay typeable. This glyph translation is presentation
# and is local to the card — D-29's single-parser rule governs extraction, not
# rendering.
CAP_PLAIN=""
CAP_COLOR=""
_cs_keycap() {
    local chord="$1" tok g
    local -a toks=()
    IFS='+' read -ra toks <<<"$chord"
    CAP_PLAIN=""
    CAP_COLOR=""
    for tok in "${toks[@]}"; do
        case "$tok" in
            Super)  g=$'\uf17a' ;;
            Shift)  g='⇧' ;;
            Ctrl)   g='⌃' ;;
            Alt)    g='⌥' ;;
            Return) g='⏎' ;;
            Space)  g='␣' ;;
            Escape) g='⎋' ;;
            left)   g='←' ;;
            right)  g='→' ;;
            up)     g='↑' ;;
            down)   g='↓' ;;
            # XF86 keys are long and unreadable; name what the key DOES. This
            # also collapses the widest chord in the set
            # (XF86MonBrightnessDown, 21 cols), which buys a whole column.
            XF86AudioRaiseVolume)  g='Vol ↑' ;;
            XF86AudioLowerVolume)  g='Vol ↓' ;;
            XF86AudioMute)         g='Mute' ;;
            XF86AudioMicMute)      g='Mic' ;;
            XF86MonBrightnessUp)   g='Bright ↑' ;;
            XF86MonBrightnessDown) g='Bright ↓' ;;
            XF86AudioPlay | XF86AudioPause) g='Play' ;;
            XF86AudioNext)         g='Next' ;;
            XF86AudioPrev)         g='Prev' ;;
            mouse:272)             g='Mouse L' ;;
            mouse:273)             g='Mouse R' ;;
            mouse_down)            g='Wheel ↓' ;;
            mouse_up)              g='Wheel ↑' ;;
            "(tap)")               g='tap' ;;
            *)                     g="$tok" ;;
        esac
        # NO background fill. Reverse video (`\033[7m`) borrows the foreground
        # colour as a fill and so always renders a maximum-contrast block that
        # glares; a soft surface fill was still a visible slab. The quietest
        # form that stays legible is plain type: the key itself in BOLD ACCENT,
        # keys joined by a DIM "+". Colour still comes from palette indices
        # (slot 3), so this re-themes with kitty and hardcodes no hex.
        #
        # CAP_PLAIN mirrors CAP_COLOR character-for-character and is the ONLY
        # thing ever measured — the escapes in CAP_COLOR must never reach the
        # width maths or every box border shifts.
        if [[ -n "$CAP_PLAIN" ]]; then
            CAP_PLAIN+=' + '
            CAP_COLOR+=$'\033[2m'" + "$'\033[0m'
        fi
        CAP_PLAIN+="$g"
        CAP_COLOR+=$'\033[1;38;5;3m'"$g"$'\033[0m'
    done
}

# render_table — the reference card.
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
        _cs_keycap "${chords[$i]}"
        rows_of["$s"]+="${CAP_PLAIN}"$'\t'"${CAP_COLOR}"$'\t'"${descs[$i]}"$'\n'
    done

    # ── Panel geometry, driven by the widest REAL (plain) content ──
    local cw=0 dw=0 p_plain p_color p_desc
    for s in "${order[@]}"; do
        while IFS=$'\t' read -r p_plain p_color p_desc; do
            [[ -z "$p_plain" ]] && continue
            (( ${#p_plain} > cw )) && cw=${#p_plain}
            (( ${#p_desc} > dw )) && dw=${#p_desc}
        done <<<"${rows_of[$s]}"
        (( ${#s} + 2 > cw + dw + 2 )) && dw=$(( ${#s} - cw ))
    done
    local inner=$(( 2 + cw + 2 + dw + 2 ))
    local pw=$(( inner + 2 ))

    # ── Fit as many panel columns as the ACTUAL window allows ──
    local termw=${COLUMNS:-0}
    (( termw == 0 )) && termw=$(tput cols 2>/dev/null || echo 120)
    local gutter=2
    local ncols=$(( (termw + gutter) / (pw + gutter) ))
    (( ncols < 1 )) && ncols=1
    (( ncols > 4 )) && ncols=4

    local BOR=$'\033[2m'          # dim — the frame recedes
    local TIT=$'\033[1;38;5;4m'   # bold accent — section name / banner
    local ICO=$'\033[38;5;3m'     # accent — section icon
    local DSC=$'\033[38;5;7m'     # muted — descriptions
    local RST=$'\033[0m'

    local rule=""
    printf -v rule '%*s' "$inner" ''
    rule="${rule// /─}"

    # ── Build each panel as fixed-visible-width lines ──
    local -a panel_blob=() panel_h=()
    local body pad icon
    for s in "${order[@]}"; do
        icon=$(_cs_icon "$s")
        body="${BOR}╭${rule}╮${RST}"$'\n'
        # title content = space + icon + space + pad  ==  inner
        # so pad is inner-3, NOT inner-4 (an off-by-one here silently drags the
        # panel's right border one column left and ruins the whole grid)
        printf -v pad '%-*s' "$(( inner - 3 ))" "$s"
        body+="${BOR}│${RST} ${ICO}${icon}${RST} ${TIT}${pad}${RST}${BOR}│${RST}"$'\n'
        body+="${BOR}├${rule}┤${RST}"$'\n'
        local n=0
        while IFS=$'\t' read -r p_plain p_color p_desc; do
            [[ -z "$p_plain" ]] && continue
            # pad from the PLAIN width, emit the COLOURED text
            printf -v pad '%*s' "$(( cw - ${#p_plain} ))" ''
            printf -v p_desc '%-*s' "$dw" "$p_desc"
            body+="${BOR}│${RST}  ${p_color}${pad}  ${DSC}${p_desc}${RST}  ${BOR}│${RST}"$'\n'
            n=$(( n + 1 ))
        done <<<"${rows_of[$s]}"
        body+="${BOR}╰${rule}╯${RST}"
        panel_blob+=("$body")
        panel_h+=( $(( n + 4 )) )
    done

    # ── Masonry: each panel drops into the currently shortest column ──
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

    # ── Banner (ANSI-Shadow block letters; every glyph cmap-verified) ──
    local theme="unknown"
    [[ -r "$HOME/.local/state/theme/current-theme" ]] && theme=$(<"$HOME/.local/state/theme/current-theme")
    theme="${theme//[$'\n\r']/}"

    printf '\n'
    printf '%s  ██╗  ██╗███████╗██╗   ██╗██████╗ ██╗███╗   ██╗██████╗ ███████╗%s\n' "$TIT" "$RST"
    printf '%s  ██║ ██╔╝██╔════╝╚██╗ ██╔╝██╔══██╗██║████╗  ██║██╔══██╗██╔════╝%s\n' "$TIT" "$RST"
    printf '%s  █████╔╝ █████╗   ╚████╔╝ ██████╔╝██║██╔██╗ ██║██║  ██║███████╗%s\n' "$TIT" "$RST"
    printf '%s  ██╔═██╗ ██╔══╝    ╚██╔╝  ██╔══██╗██║██║╚██╗██║██║  ██║╚════██║%s\n' "$TIT" "$RST"
    printf '%s  ██║  ██╗███████╗   ██║   ██████╔╝██║██║ ╚████║██████╔╝███████║%s\n' "$TIT" "$RST"
    printf '%s  ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═════╝ ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝%s\n' "$TIT" "$RST"
    printf '\n  %s  %s  ·  %s binds  ·  %s sections%s\n\n' \
        "$DSC" "$theme" "${#chords[@]}" "${#order[@]}" "$RST"

    # ── Emit the columns side by side ──
    # Split each column into its lines ONCE into a (col,row) grid — not once per
    # output row, which would re-split every column on every line.
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
