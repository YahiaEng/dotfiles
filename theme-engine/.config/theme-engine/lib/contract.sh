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

# contract_presence_only_files
# Emits the ordered list of theme-invariant font render targets that get a
# presence-only check (existence, not color-contract parity) — these are
# fragments (kitty-font.conf, waybar-font.css) with no color-declaration
# content, so they are deliberately excluded from the `files` array that
# theme-parity's name-set/semantic-value parity consumes (WR-07/06-10).
contract_presence_only_files() {
    jq -r '(.presence_only_files // [])[]' "$CONTRACT_JSON"
}

# contract_state_metadata_files
# Emits the ordered list of state-dir metadata files (current-theme, mode)
# that get a bare existence check, not format-dispatched parity.
contract_state_metadata_files() {
    jq -r '(.state_metadata_files // [])[]' "$CONTRACT_JSON"
}

# contract_engine_owned_files
# Emits the ordered list of engine-owned root-level state paths (D-29) —
# files/directories written by something OTHER than a matugen render pass
# (motion-switch, wallpaper.sh, icon/font pickers, theme-parity's own log
# dir, ...) that must survive commit.sh's rsync --delete. Single source for
# BOTH commit.sh's --exclude flags and theme-doctor's state-manifest gate:
# reading the same array means the two consumers cannot drift (the bug
# class commit.sh's own comment block documents eight times over).
contract_engine_owned_files() {
    jq -r '(.engine_owned_files // [])[]' "$CONTRACT_JSON"
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
        ini-kv)
            # THM-01/D-08: settings.ini key=value lines, skipping [section]
            # headers, blank lines, and comment lines — mirrors the
            # structure/error-handling of the kitty-kv branch above.
            grep -oP '^[A-Za-z0-9_-]+(?==)' "$path" 2>/dev/null | sort -u
            ;;
        env-kv)
            # THM-04/D-15: fzf-colors.conf NAME="VALUE" assignment lines —
            # skip blanks/comments, extract the bare NAME token before '='.
            grep -oP '^[A-Za-z0-9_]+(?==)' "$path" 2>/dev/null | sort -u
            ;;
        css-vars)
            # TOKEN-03/12-RESEARCH Pitfall 3: gtk-css's @define-color regex
            # never matches this file's `--name: value;` custom-property
            # syntax (zero matches -> theme-parity's empty-reference-set
            # guard would FAIL on the very first target) — a purpose-built
            # extractor for CSS custom properties, not the colour-oriented
            # sibling.
            grep -oP '^\s*--\K[A-Za-z0-9_-]+(?=:)' "$path" 2>/dev/null | sort -u
            ;;
        hypr-motion)
            # 12-RESEARCH Pitfall 3: hypr-vars's `^$name = value` regex
            # never matches a `bezier = name, ...` curve line — this format
            # is the UNION of every declared bezier curve name AND every
            # top-level $name variable (WR-05: $motion_enabled is a real
            # declared identifier here; omitting it would let it silently
            # vanish from both name and value extraction).
            { grep -oP '^\s*bezier = \K[A-Za-z0-9_-]+(?=,)' "$path" 2>/dev/null
              grep -oP '^\$\K[A-Za-z_][A-Za-z0-9_]*(?= =)' "$path" 2>/dev/null
            } | sort -u
            ;;
        scss-vars)
            # Same shape as the ags.scss AGS-applet target (Phase 10):
            # `$name: value;` SCSS variable declarations — distinct from
            # hypr-vars's `$name = value` (colon+semicolon, not `= `).
            # 13-02: WR-05-class fix — ags.scss (this format's only prior
            # consumer) exclusively uses underscored names, so the char
            # class never needed a hyphen until _motion.scss's
            # $motion-duration-<token>-shaped names hit it and vanished
            # from extraction entirely (a false-pass generator, same bug
            # class as WR-05's hypr-vars digit fix below). SCSS identifiers
            # allow hyphens natively; widening the class is a no-op for
            # every existing underscore-only consumer.
            grep -oP '^\$\K[A-Za-z_][A-Za-z0-9_-]*(?=:)' "$path" 2>/dev/null | sort -u
            ;;
        lua-table)
            # Phase 13.1/D-02/D-05: hyprland-tokens.lua is a `return {...}`
            # Lua table, not JSON/TOML — parse it in its OWN language
            # runtime (same "load-native-format-then-walk-keys" shape as
            # the toml branch immediately below, just in Lua instead of
            # Python) and emit the sorted set of EVERY key name found in
            # ANY table anywhere in the tree (matches the json branch's
            # `.. | objects | keys[]` "flatten, don't qualify by parent"
            # behaviour — a name-set comparison only needs the set to
            # match, not a path). A dofile() failure (missing file,
            # syntax error) exits 1 so callers see a real extraction
            # failure, never a silent empty pass.
            lua - "$path" <<'LUAEOF' 2>/dev/null
local path = arg[1]
local ok, data = pcall(dofile, path)
if not ok or type(data) ~= "table" then os.exit(1) end
local names = {}
local function walk(node)
    if type(node) ~= "table" then return end
    for k, v in pairs(node) do
        names[tostring(k)] = true
        walk(v)
    end
end
walk(data)
local sorted = {}
for k in pairs(names) do sorted[#sorted + 1] = k end
table.sort(sorted)
for _, k in ipairs(sorted) do print(k) end
LUAEOF
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
        gtk-css-motion)
            # 13-02/D-35: a sass-compiled GTK3 stylesheet that bakes in
            # motion but only ever @import's colour (D-03) — never a
            # @define-color declaration (the `gtk-css` extractor's whole
            # premise) and never a literal hex/rgba value (the
            # `css-literal` extractor's whole premise). Both were tried
            # against the real compiled sheet and both returned a genuinely
            # empty/failed extraction (proven, not assumed — see
            # 13-02-SUMMARY.md), which is exactly the vacuous-comparison
            # case theme-parity's empty-reference-set guard exists to
            # refuse. This format's actual declared content IS the set of
            # cubic-bezier(...) motion values baked into
            # transition:/animation: declarations, plus the colour
            # @import line — the two things D-35 needs this contract entry
            # to prove non-vacuously: the sheet is non-empty/non-truncated,
            # and it still imports colour live. Same selector-tracking
            # shape as css-literal's structural stand-in directly above,
            # filtered to declarations that actually carry a
            # cubic-bezier(...), plus one synthetic "@import" name when
            # the colour import line is present.
            #
            # 13-05 Rule-1 fix (found by the real checker, not assumed):
            # `grep -q ... && echo` as the LAST command in this compound
            # group made the whole extractor's exit status depend on
            # whether an @import line happened to exist — a file with
            # motion but no colour @import (waybar-modules.css, an
            # included partial by design, never a standalone sheet) made
            # `grep -q` fail with no match, and `&&` short-circuited
            # without ever reaching `echo`, so THAT failing exit status
            # became the function's own return value even though the awk
            # pass above had already emitted real, non-empty names on
            # stdout. theme-parity's Layer 2 captures this function's
            # exit status (by design, to catch a genuinely broken
            # extractor) and treated the false failure as "name
            # extraction did not succeed". An `if` with no `else` always
            # exits 0 regardless of whether its condition matched —
            # exactly the fix, verified against the real file before and
            # after.
            {
                awk '
                    /\{/ {
                        sel = $0
                        gsub(/[[:space:]]*\{.*/, "", sel)
                        gsub(/^[[:space:]]+|[[:space:]]+$/, "", sel)
                        next
                    }
                    /cubic-bezier\(/ && sel != "" {
                        prop = $0
                        gsub(/:.*/, "", prop)
                        gsub(/^[[:space:]]+|[[:space:]]+$/, "", prop)
                        if (prop != "") print sel " " prop
                    }
                    /\}/ { sel = "" }
                ' "$path" 2>/dev/null | sort -u
                if grep -qE '^\s*@import\s+url\(' "$path" 2>/dev/null; then
                    echo "@import"
                fi
                true
            }
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
        ini-kv)
            # THM-01/D-08: key<TAB>value pairs, same skip rules as the name
            # extractor above (section headers/blanks/comments never match).
            sed -nE 's/^([A-Za-z0-9_-]+)=(.*)$/\1\t\2/p' "$path" 2>/dev/null
            ;;
        env-kv)
            # THM-04/D-15: NAME<TAB>value pairs, surrounding double quotes
            # stripped from the value (fzf-colors.conf's -1 literal for
            # FZF_COLOR_BG is a non-color token and does not match the
            # color regex in theme-parity's Layer 3 — it passes untouched).
            sed -nE 's/^([A-Za-z0-9_]+)="?([^"]*)"?$/\1\t\2/p' "$path" 2>/dev/null
            ;;
        css-vars)
            sed -nE 's/^\s*--([A-Za-z0-9_-]+):\s*(.*);\s*$/\1\t\2/p' "$path" 2>/dev/null
            ;;
        hypr-motion)
            { sed -nE 's/^\s*bezier = ([A-Za-z0-9_-]+), (.*)$/\1\t\2/p' "$path"
              sed -nE 's/^\$([A-Za-z_][A-Za-z0-9_]*) = (.*)$/\1\t\2/p' "$path"
            } 2>/dev/null
            ;;
        scss-vars)
            # 13-02: same hyphen-widening fix as the name extractor above —
            # kept in lockstep so name/value extraction can never disagree
            # about which variables exist (WR-05's stated failure mode).
            sed -nE 's/^\$([A-Za-z_][A-Za-z0-9_-]*):[[:space:]]*(.*);.*$/\1\t\2/p' "$path" 2>/dev/null
            ;;
        lua-table)
            # Phase 13.1/D-02/D-05: kept in lockstep with the name
            # extractor above — same dofile()-then-walk shape, this time
            # path-joined (matching the json branch's `paths(scalars) |
            # join(".")` convention, e.g. "colors.primary",
            # "motion.curves.standard.type") and emitting ONLY string-typed
            # leaf values (numeric motion durations/curve points are
            # intentionally excluded, same as json's `select(.value | type
            # == "string")` — this is why contract.json's exempt_keys for
            # this entry is "colors.image", the dotted form this extractor
            # actually emits, not the bare "image" the hypr-vars format
            # would have used).
            lua - "$path" <<'LUAEOF' 2>/dev/null
local path = arg[1]
local ok, data = pcall(dofile, path)
if not ok or type(data) ~= "table" then os.exit(1) end
local function walk(node, prefix)
    if type(node) == "table" then
        for k, v in pairs(node) do
            local np = (prefix == "") and tostring(k) or (prefix .. "." .. tostring(k))
            walk(v, np)
        end
    elseif type(node) == "string" then
        print(prefix .. "\t" .. node)
    end
end
walk(data, "")
LUAEOF
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
        gtk-css-motion)
            # 13-02/D-35: kept in lockstep with the name extractor above —
            # same selector-tracking shape, same cubic-bezier(...) filter,
            # value is the declaration's own value span (e.g.
            # "all 200ms cubic-bezier(0.2, 0, 0, 1)"), plus the colour
            # @import's URL string as the "@import" key's value so a
            # template-leftover or malformed path is caught the same way
            # any other declared value is (WR-01's global {{ scan already
            # covers leftovers independently of format; this is the
            # per-key well-formedness pass theme-parity's Layer 3 runs).
            {
                awk '
                    /\{/ {
                        sel = $0
                        gsub(/[[:space:]]*\{.*/, "", sel)
                        gsub(/^[[:space:]]+|[[:space:]]+$/, "", sel)
                        next
                    }
                    /cubic-bezier\(/ && sel != "" {
                        prop = $0
                        gsub(/:.*/, "", prop)
                        gsub(/^[[:space:]]+|[[:space:]]+$/, "", prop)
                        val = $0
                        sub(/^[^:]*:[[:space:]]*/, "", val)
                        gsub(/;[[:space:]]*$/, "", val)
                        if (prop != "") print sel " " prop "\t" val
                    }
                    /\}/ { sel = "" }
                ' "$path" 2>/dev/null
                sed -nE 's/^\s*@import\s+url\(([^)]*)\)\s*;?\s*$/@import\t\1/p' "$path" 2>/dev/null
            }
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
