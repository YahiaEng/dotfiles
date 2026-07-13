#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          CHEAT-SHEET PARSER (D-29/D-30/D-31)          ║
# ║  Shared, display-only keybinds.conf parser. Sourced   ║
# ║  by BOTH cheat-sheet surfaces (cheat-sheet.sh's walker ║
# ║  list and cheat-sheet-view-all.sh's kitty table) so    ║
# ║  they read one implementation and can never disagree   ║
# ║  (D-29). Parses live, on every call — nothing is       ║
# ║  cached anywhere (D-31).                                ║
# ║                                                        ║
# ║  SECURITY (V5/ASVS L1, RESEARCH.md Security Domain):   ║
# ║  every parsed field is treated as inert display text.  ║
# ║  This file never dynamically executes parsed content   ║
# ║  as code, never re-interprets keybinds.conf as a shell  ║
# ║  script, and never runs command substitution on parsed  ║
# ║  text — only `printf '%s'`, quoted. $mainMod is         ║
# ║  resolved by STRING SUBSTITUTION against the value read ║
# ║  from the file's own `$mainMod = ...` line, never by    ║
# ║  re-interpreting the file as shell.                     ║
# ║                                                        ║
# ║  This file is a LIBRARY: sourcing it only defines the   ║
# ║  functions below — no output, no side effects, no shell ║
# ║  option changes (a library must never mutate its        ║
# ║  caller's `set` state). Callers invoke                  ║
# ║  cheat_sheet_parse_binds and read its stdout.            ║
# ╚══════════════════════════════════════════════════════╝

CHEAT_SHEET_DEFAULT_CONF="$HOME/.config/hypr/config/keybinds.conf"

# _cheat_sheet_trim <string>
# Trims leading/trailing whitespace via pure parameter expansion — no
# subprocess, no command substitution, no external tool.
_cheat_sheet_trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# _cheat_sheet_mod_name <raw-mod-token>
# Maps a raw Hyprland modifier token to its human display form.
_cheat_sheet_mod_name() {
    case "$1" in
        SUPER) printf 'Super' ;;
        SHIFT) printf 'Shift' ;;
        CTRL | CONTROL) printf 'Ctrl' ;;
        ALT) printf 'Alt' ;;
        CAPS) printf 'Caps' ;;
        MOD2) printf 'Mod2' ;;
        MOD3) printf 'Mod3' ;;
        MOD5) printf 'Mod5' ;;
        *) printf '%s' "$1" ;;
    esac
}

# _cheat_sheet_key_name <raw-key-field>
# Renders a key field in human form (never the raw config token verbatim
# for the cases this repo actually declares):
#   - code:N physical keycodes -> a known friendly name (107 == PrtSc, per
#     keybinds.conf's own Print-key-family comment), falling back to a
#     generic "KeyN" label for any undocumented future keycode.
#   - SUPER_L / SUPER_R (the tap-only release-bind's physical key symbol,
#     D-02) -> "(tap)", since the leading modifier already renders "Super"
#     and repeating it verbatim ("Super+SUPER_L") would be redundant noise.
#   - all-uppercase multi-character tokens (e.g. SPACE) -> title-cased
#     (Space) for readability.
#   - everything else (single letters, digits, already-natural-case tokens
#     like Escape/left/XF86AudioNext/mouse:272) -> passed through as-is.
_cheat_sheet_key_name() {
    local k="$1"
    if [[ "$k" =~ ^code:([0-9]+)$ ]]; then
        case "${BASH_REMATCH[1]}" in
            107) printf 'PrtSc' ;;
            *) printf 'Key%s' "${BASH_REMATCH[1]}" ;;
        esac
        return
    fi
    if [[ "$k" == "SUPER_L" || "$k" == "SUPER_R" ]]; then
        printf '(tap)'
        return
    fi
    if [[ "$k" =~ ^[A-Z]{2,}$ ]]; then
        local lower="${k,,}"
        printf '%s' "${lower^}"
        return
    fi
    printf '%s' "$k"
}

# _cheat_sheet_clean_section <raw-banner-text>
# Display-only cleanup of a "# ── Section ──" banner. keybinds.conf's banners
# double as developer annotations and carry planning metadata that has no
# business on a user-facing cheat-sheet ("Escape hatch (D-03)", "Utilities
# (D-32 — freed X/Z family, MENU-07 cheat-sheet source)").
#
# A trailing parenthetical is dropped ONLY when it looks like planning noise:
# it contains a decision/requirement ID (D-03, MENU-07) or is a multi-clause
# note (contains a comma). A short descriptive parenthetical is KEPT, because
# it is information the reader actually wants — "Special workspace
# (scratchpad)" must not become "Special workspace".
#
# keybinds.conf itself is never modified; this is presentation, not a rewrite.
_cheat_sheet_clean_section() {
    local s="$1"
    if [[ "$s" =~ ^(.*[^[:space:]])[[:space:]]*\((.*)\)[[:space:]]*$ ]]; then
        local head="${BASH_REMATCH[1]}" inner="${BASH_REMATCH[2]}"
        if [[ "$inner" =~ [A-Z]+-[0-9]+ || "$inner" == *,* ]]; then
            printf '%s' "$head"
            return
        fi
    fi
    printf '%s' "$s"
}

# cheat_sheet_parse_binds [path-to-keybinds.conf]
# Parses the given (or default) keybinds.conf LIVE on every call — no
# caching anywhere (D-31). Emits one line per declared bind*/= line: three
# tab-separated fields, SECTION<TAB>CHORD<TAB>DESCRIPTION, via `printf '%s'`
# only. Every field is handled as inert display text end-to-end: read via
# `while IFS= read -r line` (no word-splitting surprises), matched via
# bash's own `[[ =~ ]]` regex engine (pattern match only, never code
# execution of the matched text), and emitted via `printf`. A bind with no
# trailing `# description` renders the UI-SPEC's defensive fallback
# "(no description)" — never blank, never a crash.
cheat_sheet_parse_binds() {
    local conf="${1:-$CHEAT_SHEET_DEFAULT_CONF}"
    [[ -f "$conf" ]] || return 1

    # $mainMod resolved by reading the file's own declaration line and
    # doing plain string substitution below — never by re-interpreting the
    # file as shell (keybinds.conf is Hyprland's own config DSL, not a
    # shell script; treating it as one to "resolve the variables" is
    # exactly the wrong turn this parser must never take). Same discipline
    # keybind-doctor already uses for the identical resolution problem.
    local mainmod_value
    # shellcheck disable=SC2016 # intentional: literal $ in the grep -P pattern, not shell expansion
    mainmod_value=$(grep -oP '^\s*\$mainMod\s*=\s*\K.*' "$conf" 2>/dev/null | head -1 | tr -d '[:space:]')
    mainmod_value="${mainmod_value:-SUPER}"

    local section="" line
    while IFS= read -r line; do
        # Section banners ("# ── Section ──") become the group header every
        # subsequent bind falls under, until the next banner (D-29's table
        # grouping mirrors these verbatim rather than a hand-rolled list).
        if [[ "$line" =~ ^#[[:space:]]*── ]]; then
            local candidate
            candidate=$(printf '%s' "$line" | sed -E 's/^#[[:space:]]*//; s/─+[[:space:]]*$//; s/^─+[[:space:]]*//')
            candidate=$(_cheat_sheet_trim "$candidate")
            candidate=$(_cheat_sheet_clean_section "$candidate")
            [[ -n "$candidate" ]] && section="$candidate"
            continue
        fi

        if [[ "$line" =~ ^[[:space:]]*(bind[a-z]*)[[:space:]]*=[[:space:]]*([^,]*),[[:space:]]*([^,]*), ]]; then
            local modsfield="${BASH_REMATCH[2]}"
            local keyfield="${BASH_REMATCH[3]}"
            modsfield=$(_cheat_sheet_trim "$modsfield")
            keyfield=$(_cheat_sheet_trim "$keyfield")

            local desc=""
            if [[ "$line" == *'#'* ]]; then
                desc="${line#*#}"
                desc=$(_cheat_sheet_trim "$desc")
            fi
            [[ -z "$desc" ]] && desc="(no description)"
            # A record delimiter can never legitimately appear in
            # user-authored comment text here, but strip it defensively so
            # a stray tab could never desync the 3-field record downstream.
            desc="${desc//$'\t'/ }"

            modsfield="${modsfield//\$mainMod/$mainmod_value}"
            local mods_str="" tok mod_name
            for tok in $modsfield; do
                [[ -z "$tok" ]] && continue
                mod_name=$(_cheat_sheet_mod_name "$tok")
                if [[ -z "$mods_str" ]]; then
                    mods_str="$mod_name"
                else
                    mods_str="${mods_str}+${mod_name}"
                fi
            done

            local key_name chord
            key_name=$(_cheat_sheet_key_name "$keyfield")
            if [[ -n "$mods_str" ]]; then
                chord="${mods_str}+${key_name}"
            else
                chord="$key_name"
            fi

            printf '%s\t%s\t%s\n' "$section" "$chord" "$desc"
        fi
    done <"$conf"
}
