#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          CHEAT-SHEET PARSER (D-29/D-30/D-31)          ║
# ║  Shared, display-only keybinds.lua parser. Sourced     ║
# ║  by BOTH cheat-sheet surfaces (cheat-sheet.sh's walker  ║
# ║  list and cheat-sheet-view-all.sh's kitty table) so     ║
# ║  they read one implementation and can never disagree    ║
# ║  (D-29). Parses live, on every call — nothing is        ║
# ║  cached anywhere (D-31).                                ║
# ║                                                        ║
# ║  SECURITY (V5/ASVS L1, RESEARCH.md Security Domain):   ║
# ║  every parsed field is treated as inert display text.  ║
# ║  This file never dynamically executes parsed content   ║
# ║  as code, never re-interprets keybinds.lua as a Lua     ║
# ║  script (no `lua`/`dofile`), and never runs command     ║
# ║  substitution on parsed text — only `printf '%s'`,       ║
# ║  quoted. $mainMod is resolved by STRING SUBSTITUTION     ║
# ║  against the value read from the file's own `local       ║
# ║  mainMod = "..."` line, never by re-interpreting the      ║
# ║  file as Lua. The one-off python3 invocation below does  ║
# ║  pure TEXT TOKENIZATION only (quote/bracket-depth         ║
# ║  scanning to find where a bind call's own trailing        ║
# ║  comment starts) — the same category of tool as the        ║
# ║  grep/sed already used elsewhere in this file, never       ║
# ║  Lua execution of the parsed content.                       ║
# ║                                                        ║
# ║  This file is a LIBRARY: sourcing it only defines the   ║
# ║  functions below — no output, no side effects, no shell ║
# ║  option changes (a library must never mutate its        ║
# ║  caller's `set` state). Callers invoke                  ║
# ║  cheat_sheet_parse_binds and read its stdout.            ║
# ╚══════════════════════════════════════════════════════╝
#
# Phase 13.1/13.1-09: retargeted from keybinds.conf (hyprlang) to
# keybinds.lua. No fallback to keybinds.conf when the Lua module is
# missing (T-13.1-27) — cheat_sheet_parse_binds simply returns nothing
# (via its existing `[[ -f "$conf" ]] || return 1` guard) exactly as it
# always has for a missing file.

CHEAT_SHEET_DEFAULT_CONF="$HOME/.config/hypr/config/keybinds.lua"

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
#     keybinds.lua's own Print-key-family comment), falling back to a
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
# Display-only cleanup of a "-- ── Section ──" banner. keybinds.lua's banners
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
# keybinds.lua itself is never modified; this is presentation, not a rewrite.
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

# _cheat_sheet_tokenize <path> <mainmod>
# One-shot text tokenizer (python3, pure string scanning — see this file's
# header comment for why this is not an execution boundary violation).
# Emits one line per relevant source line, ASCII-Unit-Separator (0x1f)
# delimited:
#   SECTION<0x1f><raw banner text, uncleaned>
#   BIND<0x1f><space-joined mod tokens><0x1f><key token><0x1f><description or empty>
# A `hl.bind(...)` line whose call this tokenizer cannot balance (unbalanced
# brackets, unrecognised key-expression shape) is silently skipped — this is
# a best-effort DISPLAY parser, not a regression gate (keybind-doctor is
# the tool that must fail loudly on a shape problem; this one degrades
# gracefully, exactly like the previous regex-based parser did for any line
# that didn't match its pattern).
_cheat_sheet_tokenize() {
    local path="$1" mainmod="$2"
    python3 - "$path" "$mainmod" <<'PYEOF'
import re
import sys

US = "\x1f"
path, mainmod = sys.argv[1], sys.argv[2]

try:
    with open(path, "r", encoding="utf-8") as fh:
        lines = fh.readlines()
except OSError:
    sys.exit(0)


def scan_call(text):
    assert text.startswith("hl.bind(")
    i = len("hl.bind(")
    depth = 1
    in_string = False
    arg_start = i
    args = []
    n = len(text)
    while i < n:
        c = text[i]
        if in_string:
            if c == "\\":
                i += 2
                continue
            if c == '"':
                in_string = False
            i += 1
            continue
        if c == '"':
            in_string = True
            i += 1
            continue
        if c in "({":
            depth += 1
            i += 1
            continue
        if c in ")}":
            depth -= 1
            if depth == 0:
                args.append(text[arg_start:i])
                return args, text[i + 1:]
            i += 1
            continue
        if c == "," and depth == 1:
            args.append(text[arg_start:i])
            arg_start = i + 1
            i += 1
            continue
        i += 1
    return None


SECTION_RE = re.compile(r'^--\s*──')

for raw in lines:
    lead = raw.rstrip("\n").strip()

    if SECTION_RE.match(lead):
        print(f"SECTION{US}{lead}")
        continue

    if not lead.startswith("hl.bind("):
        continue

    result = scan_call(lead)
    if result is None:
        continue
    args, trailer = result
    if len(args) not in (2, 3):
        continue

    key_arg = args[0].strip()

    m = re.match(r'^mainMod\s*\.\.\s*"((?:[^"\\]|\\.)*)"$', key_arg)
    if m:
        full_key = mainmod + m.group(1)
    else:
        m2 = re.match(r'^"((?:[^"\\]|\\.)*)"$', key_arg)
        if not m2:
            continue
        full_key = m2.group(1)

    tokens = full_key.split(" + ")
    key_token = tokens[-1]
    mod_tokens = tokens[:-1]

    trailer_stripped = trailer.strip()
    desc = ""
    if trailer_stripped.startswith("--"):
        desc = trailer_stripped[2:].strip()

    print(f"BIND{US}{' '.join(mod_tokens)}{US}{key_token}{US}{desc}")
PYEOF
}

# cheat_sheet_parse_binds [path-to-keybinds.lua]
# Parses the given (or default) keybinds.lua LIVE on every call — no
# caching anywhere (D-31). Emits one line per declared `hl.bind(...)` call:
# three tab-separated fields, SECTION<TAB>CHORD<TAB>DESCRIPTION, via
# `printf '%s'` only. Every field is handled as inert display text
# end-to-end. A bind with no trailing `-- description` renders the
# UI-SPEC's defensive fallback "(no description)" — never blank, never a
# crash.
cheat_sheet_parse_binds() {
    local conf="${1:-$CHEAT_SHEET_DEFAULT_CONF}"
    [[ -f "$conf" ]] || return 1

    # mainMod resolved by reading the file's own declaration line and
    # doing plain string substitution below — never by re-interpreting the
    # file as Lua (keybinds.lua is Hyprland's own config DSL executed by
    # the compositor's own embedded interpreter, not something this
    # display parser should ever evaluate). Same discipline keybind-doctor
    # already uses for the identical resolution problem.
    local mainmod_value
    # shellcheck disable=SC2016 # intentional: literal quote in the grep -P pattern, not shell expansion
    mainmod_value=$(grep -oP '^\s*local\s+mainMod\s*=\s*"\K[^"]+' "$conf" 2>/dev/null | head -1)
    mainmod_value="${mainmod_value:-SUPER}"

    local section="" us=$'\x1f'
    while IFS="$us" read -r rec_tag f1 f2 f3; do
        case "$rec_tag" in
            SECTION)
                local candidate
                candidate=$(printf '%s' "$f1" | sed -E 's/^--[[:space:]]*//; s/─+[[:space:]]*$//; s/^─+[[:space:]]*//')
                candidate=$(_cheat_sheet_trim "$candidate")
                candidate=$(_cheat_sheet_clean_section "$candidate")
                [[ -n "$candidate" ]] && section="$candidate"
                ;;
            BIND)
                local modsfield="$f1" keyfield="$f2" desc="$f3"
                [[ -z "$desc" ]] && desc="(no description)"
                # A record delimiter can never legitimately appear in
                # user-authored comment text here, but strip it
                # defensively so a stray tab could never desync the
                # 3-field record downstream.
                desc="${desc//$'\t'/ }"

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
                ;;
        esac
    done < <(_cheat_sheet_tokenize "$conf" "$mainmod_value")
}
