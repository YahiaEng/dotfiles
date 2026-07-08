#!/usr/bin/env bash
# theme-engine/lib/contract.sh — canonical output-contract manifest reader +
# per-format extraction/normalization helpers (D-30/PIPE-04)
#
# contract.json is the single source of truth for "what files does one
# theme render produce, in what format, with what per-file exemptions" —
# sourced by both theme-doctor (state-dir file-list check) and theme-parity
# (structure/name-set/semantic-value parity checks) so the two tools can
# never drift on the file list (D-30). Source-only function library, no
# execution guard — follows the lib/gtk.sh / lib/reload.sh shape (one
# function per concern).

# Resolve contract.json relative to THIS file's own directory, not the
# caller's CWD or $0, so sourcing works identically from theme-doctor,
# theme-parity, or any future consumer regardless of invocation directory.
CONTRACT_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
CONTRACT_JSON="$CONTRACT_LIB_DIR/../contract.json"

# contract_files
# Emits the ordered list of contract filenames (the 10 matugen-rendered
# state-dir files), one per line.
contract_files() {
    jq -r '.files[].name' "$CONTRACT_JSON"
}

# contract_format <name>
# Emits the format tag for a contract file (gtk-css | hypr-vars | kitty-kv |
# toml | json | css-literal).
contract_format() {
    local name="$1"
    jq -r --arg n "$name" '.files[] | select(.name == $n) | .format' "$CONTRACT_JSON"
}

# contract_exempt_keys <name>
# Emits the exempted key names for a contract file, one per line (nothing
# if none declared).
contract_exempt_keys() {
    local name="$1"
    jq -r --arg n "$name" '.files[] | select(.name == $n) | (.exempt_keys // [])[]' "$CONTRACT_JSON"
}

# contract_extract_names <name> <rendered_path>
# Dispatches to the correct per-format extractor and emits the sorted set of
# key/variable names found in the rendered file at <rendered_path>. For the
# css-literal format (walker-style.css has no named variables) this instead
# emits the sorted set of "<selector> <property>" pairs as a structural
# stand-in (RESEARCH Open Question 1).
contract_extract_names() {
    local name="$1"
    local path="$2"
    local fmt
    fmt="$(contract_format "$name")"

    case "$fmt" in
        gtk-css)
            grep -oP '@define-color \K\S+' "$path" 2>/dev/null | sort -u
            ;;
        hypr-vars)
            # WR-05: allow digits after the first character ($color4,
            # $surface2) — a digit-bearing variable silently vanishing from
            # BOTH name and value extraction is a false-pass generator.
            grep -oP '^\$\K[A-Za-z_][A-Za-z0-9_]*(?= =)' "$path" 2>/dev/null | sort -u
            ;;
        kitty-kv)
            grep -oP '^[A-Za-z0-9_]+(?=\s)' "$path" 2>/dev/null | sort -u
            ;;
        toml)
            python3 - "$path" <<'PYEOF'
import tomllib, sys

with open(sys.argv[1], "rb") as f:
    data = tomllib.load(f)


def walk(node, keys):
    if isinstance(node, dict):
        for k, v in node.items():
            keys.add(k)
            walk(v, keys)
    elif isinstance(node, list):
        for item in node:
            walk(item, keys)


found = set()
walk(data, found)
print("\n".join(sorted(found)))
PYEOF
            ;;
        json)
            jq -r '.. | objects | keys[]' "$path" | sort -u
            ;;
        css-literal)
            # No named color variables in this file — extract the shape of
            # selector blocks + property names instead, so a broken/missing
            # rule is still caught as a structural divergence.
            awk '
                /\{/ {
                    sel = $0
                    gsub(/[[:space:]]*\{.*/, "", sel)
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", sel)
                    next
                }
                /:/ && sel != "" {
                    prop = $0
                    gsub(/:.*/, "", prop)
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", prop)
                    if (prop != "") print sel " " prop
                }
                /\}/ { sel = "" }
            ' "$path" 2>/dev/null | sort -u
            ;;
        *)
            # CR-01: an unknown/typo format tag must be loud — a silent
            # `return 1` with no output lets callers that swallow exit codes
            # false-pass on an empty extraction.
            echo "contract.sh: unknown format '$fmt' for '$name'" >&2
            return 1
            ;;
    esac
}

# contract_extract_values <name> <rendered_path>
# Emits "key<TAB>value" pairs for every leaf key in the rendered file,
# dispatched by format. For css-literal (no key concept) emits sequential
# index<TAB>token pairs, one per color-looking token found in the file.
# Used by theme-parity's semantic-value parity layer.
contract_extract_values() {
    local name="$1"
    local path="$2"
    local fmt
    fmt="$(contract_format "$name")"

    case "$fmt" in
        gtk-css)
            sed -nE 's/@define-color[[:space:]]+([A-Za-z0-9_]+)[[:space:]]+(.*);.*/\1\t\2/p' "$path" 2>/dev/null
            ;;
        hypr-vars)
            # WR-05: keep in lockstep with the name extractor above —
            # digits allowed after the first character.
            sed -nE 's/^\$([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$/\1\t\2/p' "$path" 2>/dev/null
            ;;
        kitty-kv)
            awk '$1 !~ /^#/ && NF >= 2 { print $1"\t"$2 }' "$path" 2>/dev/null
            ;;
        toml)
            python3 - "$path" <<'PYEOF'
import tomllib, sys

with open(sys.argv[1], "rb") as f:
    data = tomllib.load(f)


def walk(node, prefix, out):
    if isinstance(node, dict):
        for k, v in node.items():
            walk(v, f"{prefix}.{k}" if prefix else k, out)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            walk(v, f"{prefix}[{i}]", out)
    elif isinstance(node, str):
        out.append((prefix, node))


results = []
walk(data, "", results)
for k, v in results:
    print(f"{k}\t{v}")
PYEOF
            ;;
        json)
            jq -r '[paths(scalars) as $p | {key: ($p | join(".")), value: getpath($p)}] | .[] | select(.value | type == "string") | "\(.key)\t\(.value)"' "$path"
            ;;
        css-literal)
            grep -oP '#[0-9a-fA-F]{6}|rgba\([^)]*\)' "$path" 2>/dev/null | awk '{print NR"\t"$0}'
            ;;
        *)
            # CR-01: an unknown/typo format tag must be loud — a silent
            # `return 1` with no output lets callers that swallow exit codes
            # false-pass on an empty extraction.
            echo "contract.sh: unknown format '$fmt' for '$name'" >&2
            return 1
            ;;
    esac
}

# contract_normalize_color <raw>
# Reduces a color value to a bare lowercase 6-hex-digit string regardless of
# source format (bare hex, #-prefixed hex, or Hyprland's no-comma
# rgba(RRGGBBAA) form). Returns 1 (emits nothing) if the value is not one of
# those recognized "sentinel candidate" forms — a comma rgba()/rgb() CSS
# value is NOT reduced here (see contract_wellformed_color for that case).
contract_normalize_color() {
    local raw="$1"
    raw="${raw,,}"
    raw="${raw#\#}"
    if [[ "$raw" =~ ^rgba\(([0-9a-f]{6})[0-9a-f]{2}\)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$raw" =~ ^([0-9a-f]{6})$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        return 1
    fi
}

# contract_wellformed_color <raw>
# True (exit 0) when the value is a valid color in ANY recognized format:
# bare/#-prefixed 6-hex, Hyprland's rgba(RRGGBBAA), OR a standard CSS
# rgba(r, g, b, a) / rgb(r, g, b) comma form (e.g. hardcoded GTK shadow
# constants). False for empty strings, literal `{{...}}` template
# leftovers, or any other malformed value.
contract_wellformed_color() {
    local raw="$1"
    if contract_normalize_color "$raw" >/dev/null 2>&1; then
        return 0
    fi
    local lc="${raw,,}"
    if [[ "$lc" =~ ^rgba?\([[:space:]]*[0-9]{1,3}[[:space:]]*,[[:space:]]*[0-9]{1,3}[[:space:]]*,[[:space:]]*[0-9]{1,3}[[:space:]]*(,[[:space:]]*[0-9.]+[[:space:]]*)?\)$ ]]; then
        return 0
    fi
    return 1
}
