#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║   ICON THEME PICKER — fzf + kitty graphics + gtk.sh   ║
# ║                                                        ║
# ║  D-20: fzf-in-floating-kitty with a rich icon-grid     ║
# ║  preview — the SAME pattern as wallpaper-picker.sh,    ║
# ║  not the walker dmenu picker pattern (Pitfall 6        ║
# ║  mandates a real state read/re-render, never a bare    ║
# ║  standalone settings write).                           ║
# ║                                                        ║
# ║  Left pane:  installed icon themes, fzf fuzzy search   ║
# ║              (Ctrl-A browses the repo/AUR catalogue    ║
# ║              of not-yet-installed themes, MAINT-03)    ║
# ║  Right pane: montage icon-grid preview (kitten icat)   ║
# ║                                                        ║
# ║  Enter    = confirm selection (writes state + re-       ║
# ║             applies), or install a catalogue pick      ║
# ║  Ctrl-A   = browse the installable repo/AUR catalogue  ║
# ║  Esc/q    = cancel, no changes made                     ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

# ── Signal-vs-EXIT-trap gap (Rule 1 fix, found during Task 3 checkpoint
# forensics) ──────────────────────────────────────────────────────────
# An EXIT-only trap (see below) alone does NOT reliably run when the
# floating kitty window is closed via Hyprland's real
# closewindow/killactive dispatch:
# bash only overrides a signal's default (terminate) disposition for a
# signal it has an explicit trap on — HUP/INT/TERM with no trap of their
# own are handled by the kernel's default action directly, bypassing
# bash's own EXIT-trap machinery entirely. Verified live: a real
# `hyprctl dispatch closewindow` on this script's own floating window
# left the mktemp'd ENUM_SCRIPT/PREVIEW_SCRIPT/CATALOG_SCRIPT/CACHE_DIR
# on disk every time without this; adding these explicit traps (which
# re-exit through the shell's own exit path so the EXIT trap below
# actually fires) cleaned up all four artifacts every time, confirmed
# against the real launcher and the real dispatcher, not a synthetic
# stand-in.
for _sig in HUP INT TERM; do
    trap "exit 1" "$_sig"
done

ICON_STATE="$HOME/.local/state/theme/icon-theme"
CURRENT_THEME_FILE="$HOME/.local/state/theme/current-theme"
ACTIVE_MARKER=" ●"
CATALOG_SEARCH_TERM="icon-theme"

# ── Non-interactive surface (quick-260821-6z1 Task 10, R-6) — `--list`/
#    `--set <name>`, handled BEFORE any interactive machinery (AUR helper
#    resolution, the enum script mktemp, fzf-colors). Covers ONLY the
#    already-INSTALLED theme set, via the SAME real directory scan the
#    interactive path's own ENUM_SCRIPT uses — never the AUR-catalog
#    install flow further down this file, which installs a package and
#    is out of scope for a settings-window dropdown (package installs
#    are never auto-driven from this surface). `_persist_and_apply()` is
#    the SAME "legacy installed-theme" tail the interactive path runs on
#    Enter for an already-installed selection (state write, theme-apply
#    re-run, notify) — one copy, both paths call it. ────────────────────
_list_installed_icon_themes() {
    local base dir name idx dirs_line
    declare -A seen
    for base in /usr/share/icons "$HOME/.local/share/icons"; do
        [[ -d "$base" ]] || continue
        for dir in "$base"/*/; do
            [[ -d "$dir" ]] || continue
            name=$(basename "$dir")
            [[ -n "${seen[$name]:-}" ]] && continue
            [[ "$name" == "hicolor" || "$name" == "default" ]] && continue
            idx="$dir/index.theme"
            [[ -f "$idx" ]] || continue
            dirs_line=$(grep -m1 '^Directories=' "$idx" 2>/dev/null || true)
            [[ -n "$dirs_line" ]] || continue
            seen[$name]=1
            printf '%s\n' "$name"
        done
    done | sort
}

_persist_and_apply() {
    local selected="$1"
    mkdir -p "$(dirname "$ICON_STATE")"
    printf '%s\n' "$selected" > "$ICON_STATE.tmp" && mv "$ICON_STATE.tmp" "$ICON_STATE"

    local active_preset
    active_preset=$(cat "$CURRENT_THEME_FILE" 2>/dev/null || echo "")
    if [[ -n "$active_preset" ]]; then
        ~/.config/theme-engine/theme-apply "$active_preset"
    else
        echo "icon-theme-picker: no active theme recorded yet — icon-theme state saved, will apply on the next run of the engine" >&2
    fi

    notify-send -a "Icon Theme" "Icon Theme Changed" \
        "Applied $selected" \
        -i preferences-desktop-icons -t 2000 2>/dev/null || true
}

case "${1:-}" in
    --list)
        _list_installed_icon_themes
        exit 0
        ;;
    --set)
        NAME="${2:-}"
        [[ -n "$NAME" ]] || { echo "icon-theme-picker.sh --set: name required" >&2; exit 1; }
        VALID=0
        while IFS= read -r _n; do
            [[ "$_n" == "$NAME" ]] && { VALID=1; break; }
        done < <(_list_installed_icon_themes)
        [[ "$VALID" -eq 1 ]] \
            || { echo "icon-theme-picker.sh --set: '$NAME' did not resolve to an installed icon theme" >&2; exit 1; }
        _persist_and_apply "$NAME"
        exit 0
        ;;
esac

# ── Pipeline-themed fzf colors (THM-04/D-15) ─────────
# Best-effort source of the engine-rendered fragment — the current
# catppuccin-mocha hex values survive only as ${VAR:-fallback} defaults
# below (fresh-install graceful degradation before the engine's first
# render).
# shellcheck source=/dev/null
source "$HOME/.local/state/theme/fzf-colors.conf" 2>/dev/null || true

ACTIVE_ICON=$(cat "$ICON_STATE" 2>/dev/null || echo "Adwaita")

# ── AUR helper resolution (D-27) ─────────────────────
# Same precedence install.sh:304-317 already uses (prefer paru, else yay);
# unlike install.sh's fresh-system bootstrap this picker never bootstraps
# one itself — if neither is present the catalogue simply shows repo
# results only, with a visible note (D-27/Package Legitimacy Audit).
AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
fi

# ── Enumeration script (Security Domain V5) ──────────
# Real installed icon themes only, via a directory scan for index.theme
# files carrying a non-empty Directories= key (excludes cursor themes
# like Bibata, which have no Directories= key, and the non-selectable
# hicolor/default fallback buckets) — never trust raw interpolation, same
# discipline as wallpaper-picker.sh's ENUM_SCRIPT/lib/wallpaper.sh.
# WR-04: initialize all four mktemp-artifact vars before the first
# mktemp, then install one EXIT trap covering all four — safe on any
# abort path (failing enumeration, a later mktemp failing, SIGTERM/SIGHUP
# from the floating kitty window closing), matching the sibling idiom
# color-picker.sh/gif-export.sh already use. Installing a second on-exit
# handler here would silently replace this one, so only one is ever set.
ENUM_SCRIPT=""
PREVIEW_SCRIPT=""
CACHE_DIR=""
CATALOG_SCRIPT=""
ENUM_SCRIPT=$(mktemp /tmp/icon-enum-XXXXXX.sh)
trap 'rm -f "$ENUM_SCRIPT" "$PREVIEW_SCRIPT" "$CATALOG_SCRIPT"; rm -rf "$CACHE_DIR"' EXIT
printf '#!/usr/bin/env bash\nACTIVE_MARKER=%q\n' "$ACTIVE_MARKER" > "$ENUM_SCRIPT"
cat >> "$ENUM_SCRIPT" << 'ENUM'
ACTIVE="$1"
declare -A seen
for base in /usr/share/icons "$HOME/.local/share/icons"; do
    [[ -d "$base" ]] || continue
    for dir in "$base"/*/; do
        [[ -d "$dir" ]] || continue
        name=$(basename "$dir")
        [[ -n "${seen[$name]:-}" ]] && continue
        [[ "$name" == "hicolor" || "$name" == "default" ]] && continue
        idx="$dir/index.theme"
        [[ -f "$idx" ]] || continue
        dirs_line=$(grep -m1 '^Directories=' "$idx" 2>/dev/null || true)
        [[ -n "$dirs_line" ]] || continue
        seen[$name]=1
        if [[ "$name" == "$ACTIVE" ]]; then
            printf '%s%s\n' "$name" "$ACTIVE_MARKER"
        else
            printf '%s\n' "$name"
        fi
    done
done | sort
ENUM
chmod +x "$ENUM_SCRIPT"

THEMES=$("$ENUM_SCRIPT" "$ACTIVE_ICON")
THEME_COUNT=$(printf '%s\n' "$THEMES" | grep -c . || true)

# ── Only-Adwaita note (MAINT-03) ──────────────────────
# The picker used to hard-exit here before the browsable catalogue
# existed — that would make Ctrl-A unreachable on exactly the machine
# state (a fresh install) where browsing/installing a new theme is most
# wanted. Note it and keep going instead of exiting (Rule 2: the early
# exit was blocking this plan's own core truth).
if [[ "$THEME_COUNT" -le 1 ]]; then
    echo "icon-theme-picker: only Adwaita installed locally — press Ctrl-A to browse installable themes from the repos/AUR" >&2
fi

# ── Catalogue enumeration script (D-26/D-27/D-28) ────
# A third mktemp'd script, sibling of ENUM_SCRIPT/PREVIEW_SCRIPT, covered
# by the same single EXIT trap above. Emits one line per browsable
# not-necessarily-installed package as <source>\t<pkgname>\t<description>,
# so the preview and install paths can branch on provenance without
# re-querying. Official-repo results need no extra vetting (Arch's own
# signed, mirrored packages); AUR results come only through the
# already-resolved helper, never a bespoke fetch path.
CATALOG_SCRIPT=$(mktemp /tmp/icon-catalog-XXXXXX.sh)
printf '#!/usr/bin/env bash\nACTIVE_MARKER=%q\nSEARCH_TERM=%q\n' "$ACTIVE_MARKER" "$CATALOG_SEARCH_TERM" > "$CATALOG_SCRIPT"
cat >> "$CATALOG_SCRIPT" << 'CATALOG'
# Shared parser: pacman -Ss and `<helper> -Ss -a` both emit
# "repo/pkgname version [markers]" header lines followed by a
# 4-space-indented description line — installed packages carry an
# "[installed]" (pacman) or "[Installed...]" (paru) marker.
parse_search_output() {
    local source="$1"
    local line pkgname="" installed=0 desc marker
    while IFS= read -r line; do
        if [[ "$line" =~ ^[^[:space:]]+/([^[:space:]]+)[[:space:]] ]]; then
            pkgname="${BASH_REMATCH[1]}"
            if [[ "$line" == *"[installed]"* || "$line" == *"[Installed"* ]]; then
                installed=1
            else
                installed=0
            fi
        elif [[ "$line" == "    "* ]]; then
            desc="${line#"    "}"
            marker=""
            [[ "$installed" -eq 1 ]] && marker="$ACTIVE_MARKER"
            printf '%s\t%s\t%s%s\n' "$source" "$pkgname" "$desc" "$marker"
        fi
    done
}

REPO_RESULTS=$(pacman -Ss "$SEARCH_TERM" 2>/dev/null | parse_search_output repo)

AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
fi

AUR_RESULTS=""
if [[ -n "$AUR_HELPER" ]]; then
    AUR_RESULTS=$(timeout 20 "$AUR_HELPER" -Ss -a "$SEARCH_TERM" 2>/dev/null | parse_search_output aur)
else
    echo "icon-theme-picker: no AUR helper (paru/yay) found — showing official-repo results only" >&2
fi

# Dedupe by package name (repo wins over AUR), then sort.
printf '%s\n%s\n' "$REPO_RESULTS" "$AUR_RESULTS" | awk -F'\t' '
    NF < 2 { next }
    { key = $2; if (!(key in seen) || ($1 == "repo" && src[key] != "repo")) { seen[key] = $0; src[key] = $1 } }
    END { for (k in seen) print seen[k] }
' | sort -t $'\t' -k2,2
CATALOG
chmod +x "$CATALOG_SCRIPT"

# ── Preview script (montage icon-grid + kitten icat) ──────────────────
# Renders a small grid of representative icons from the previewed theme
# via ImageMagick `montage` (available on this system: magick/convert/
# rsvg-convert), then displays it with the exact same fzf upstream
# kitten-icat idiom wallpaper-picker.sh uses (RESEARCH Pattern 4) — chafa
# --format=kitty / block-symbols are the same two-tier fallback.
#
# Handles THREE shapes of fzf line, branched on content:
#   - a plain installed-theme name (legacy, unchanged rendering path)
#   - a catalogue line already installed (source\tpkgname\tdesc + marker)
#     -> resolves pkgname to the directory it owns and renders that
#   - a catalogue line NOT installed, source=repo
#     -> fetches+extracts into $CACHE_DIR/pkg/ (never installs) and
#        renders the real icons (D-28)
#   - a catalogue line NOT installed, source=aur
#     -> no prebuilt package exists; renders package metadata text
PREVIEW_SCRIPT=$(mktemp /tmp/icon-preview-XXXXXX.sh)
CACHE_DIR=$(mktemp -d /tmp/icon-preview-cache-XXXXXX)
mkdir -p "$CACHE_DIR/pkg"
printf '#!/usr/bin/env bash\nCACHE_DIR=%q\nAUR_HELPER=%q\n' "$CACHE_DIR" "$AUR_HELPER" > "$PREVIEW_SCRIPT"
cat >> "$PREVIEW_SCRIPT" << 'PREVIEW'
RAW="$1"
MARKED=0
[[ "$RAW" == *" ●" ]] && MARKED=1
ENTRY="${RAW% ●}"

# ── Shared icon-finding helpers (Pitfall 6) ──────────
# freedesktop.org permits two directory-naming conventions and themes
# choose independently (verified this session against two real packages:
# Papirus uses SIZExSIZE/category/, elementary uses the inverted
# category/SIZE/). Try SIZExSIZE first, then the inverted form, then an
# unfiltered fallback — applied to every root this script ever searches.
find_icon_variant() {
    local root="$1" name="$2" f
    f=$(find "$root" -type f \( -iname "${name}.svg" -o -iname "${name}.png" \) -path '*/[0-9]*x[0-9]*/*' 2>/dev/null | head -1)
    if [[ -z "$f" ]]; then
        f=$(find "$root" -type f \( -iname "${name}.svg" -o -iname "${name}.png" \) -regextype posix-extended -iregex '.*/[0-9]+/[^/]+\.(svg|png)' 2>/dev/null | head -1)
    fi
    if [[ -z "$f" ]]; then
        f=$(find "$root" -type f \( -iname "${name}.svg" -o -iname "${name}.png" \) 2>/dev/null | head -1)
    fi
    [[ -n "$f" ]] && printf '%s\n' "$f"
}

find_icon_bulk() {
    local root="$1"
    local -a hits=()
    mapfile -t hits < <(find "$root" -type f \( -iname "*.svg" -o -iname "*.png" \) -path '*/[0-9]*x[0-9]*/apps/*' 2>/dev/null | sort | head -12)
    if [[ ${#hits[@]} -eq 0 ]]; then
        mapfile -t hits < <(find "$root" -type f \( -iname "*.svg" -o -iname "*.png" \) -regextype posix-extended -iregex '.*/apps/[0-9]+/[^/]+\.(svg|png)' 2>/dev/null | sort | head -12)
    fi
    if [[ ${#hits[@]} -eq 0 ]]; then
        mapfile -t hits < <(find "$root" -type f \( -iname "*.svg" -o -iname "*.png" \) 2>/dev/null | sort | head -12)
    fi
    [[ ${#hits[@]} -gt 0 ]] && printf '%s\n' "${hits[@]}"
}

render_montage_from_root() {
    # $1 = root dir to search, $2 = output PNG path
    local root="$1" out="$2"
    [[ -f "$out" ]] && return 0
    command -v montage &>/dev/null || return 1
    local -a NAMES=(folder user-home network-server drive-harddisk applications-system utilities-terminal text-x-generic image-x-generic audio-x-generic video-x-generic package-x-generic preferences-system)
    local -a ICONS=()
    local n f
    for n in "${NAMES[@]}"; do
        f=$(find_icon_variant "$root" "$n")
        [[ -n "$f" ]] && ICONS+=("$f")
    done
    if [[ ${#ICONS[@]} -lt 4 ]]; then
        mapfile -t ICONS < <(find_icon_bulk "$root")
    fi
    [[ ${#ICONS[@]} -eq 0 ]] && return 1
    montage "${ICONS[@]}" -tile 4x3 -geometry 48x48+4+4 -background none "$out" 2>/dev/null
}

render_grid_png() {
    # $1 = png path (may not exist — rendering degrades gracefully),
    # $2 = label line to print underneath
    local png="$1" label="$2"
    local COLS=${FZF_PREVIEW_COLUMNS:-40}
    local LINES=${FZF_PREVIEW_LINES:-20}
    local IMG_LINES=$((LINES - 2))
    [[ $IMG_LINES -lt 1 ]] && IMG_LINES=1
    if [[ -f "$png" ]]; then
        if [[ -n "${KITTY_WINDOW_ID:-}" ]] && command -v kitten &>/dev/null; then
            kitten icat --clear --transfer-mode=memory --unicode-placeholder \
                --stdin=no --place="${COLS}x${IMG_LINES}@0x0" "$png" 2>/dev/null \
                | sed '$d' | sed $'$s/$/\e[m/'
        elif command -v chafa &>/dev/null && chafa --help 2>/dev/null | grep -q 'kitty'; then
            chafa --format=kitty --size="${COLS}x${IMG_LINES}" \
                  --animate=off --center=on \
                  "$png" 2>/dev/null
        else
            chafa --size="${COLS}x${IMG_LINES}" \
                  --animate=off --center=on \
                  --color-space=din99d \
                  --symbols=block+border+space \
                  "$png" 2>/dev/null
        fi
    fi
    echo ""
    echo -e "$label"
}

resolve_installed_dir_for_pkg() {
    # Prints the first icon-theme directory name the installed package
    # owns, if any (Package -> theme-directory identity resolution,
    # <assumption_delta_decision>).
    pacman -Ql "$1" 2>/dev/null \
        | grep -oE 'usr/share/icons/[^/]+/index\.theme$' \
        | sed -E 's#usr/share/icons/([^/]+)/index\.theme#\1#' \
        | sort -u | head -1
}

if [[ "$ENTRY" == *$'\t'* ]]; then
    # ── Catalogue entry: source\tpkgname\tdescription ──
    IFS=$'\t' read -r SRC PKG DESC <<< "$ENTRY"
    ACTIVE_MARK=""
    [[ -f "$HOME/.local/state/theme/icon-theme" ]] && \
        [[ "$(cat "$HOME/.local/state/theme/icon-theme" 2>/dev/null)" == "$PKG" ]] && \
        ACTIVE_MARK="  │  ● active"
    LABEL=" \e[1m$PKG\e[0m  │  $SRC  │  $DESC${ACTIVE_MARK}"

    if [[ "$MARKED" -eq 1 ]]; then
        # Already installed — fall through to a real installed-theme
        # render, resolved via the package's own file list since a
        # package name is never the theme directory name.
        DIRNAME=$(resolve_installed_dir_for_pkg "$PKG")
        if [[ -n "$DIRNAME" ]]; then
            GRID_PNG="$CACHE_DIR/${DIRNAME}.png"
            render_montage_from_root "/usr/share/icons/$DIRNAME" "$GRID_PNG"
            render_grid_png "$GRID_PNG" "$LABEL  │  provides $DIRNAME"
        else
            echo ""
            echo -e "$LABEL"
            echo ""
            echo "  installed, but no recognisable icon-theme directory was found"
        fi
    elif [[ "$SRC" == "repo" ]]; then
        # Not installed, official repo — fetch and extract for preview
        # only (D-28). Never `pacman -U`, never the helper: extraction
        # only, so no install hook from this package ever runs for a
        # preview the user has not agreed to install (T-13-16).
        GRID_PNG="$CACHE_DIR/pkg-${PKG}.png"
        EXTRACT_DIR="$CACHE_DIR/pkg/${PKG}"
        ARCHIVE="$CACHE_DIR/pkg/${PKG}.pkg.tar.zst"
        if [[ ! -f "$GRID_PNG" ]]; then
            if [[ ! -d "$EXTRACT_DIR" ]]; then
                echo "  ⟳ fetching $PKG …"
                URL=$(pacman -Sp "$PKG" 2>/dev/null | tail -1)
                if [[ -z "$URL" ]]; then
                    echo "  ✗ could not resolve a download URL for $PKG"
                    exit 0
                fi
                if ! curl -fsSL --max-time 30 --max-filesize 209715200 -o "$ARCHIVE" "$URL" 2>/dev/null; then
                    echo "  ✗ fetch failed for $PKG — network unreachable or download error"
                    rm -f "$ARCHIVE"
                    exit 0
                fi
                mkdir -p "$EXTRACT_DIR"
                # T-13-17: restricted to the archive's usr/share/icons
                # paths, same-owner/same-permission restoration disabled,
                # absolute-path extraction (-P) never enabled.
                if ! bsdtar -x --no-same-owner --no-same-permissions -f "$ARCHIVE" -C "$EXTRACT_DIR" 'usr/share/icons/*' 2>/dev/null; then
                    echo "  ✗ extraction failed for $PKG"
                    rm -rf "$EXTRACT_DIR"
                    exit 0
                fi
            fi
            render_montage_from_root "$EXTRACT_DIR/usr/share/icons" "$GRID_PNG"
        fi
        render_grid_png "$GRID_PNG" "$LABEL"
    elif [[ "$SRC" == "aur" ]]; then
        # No prebuilt package exists to fetch — render package metadata
        # instead, with the explicit no-preview note (D-28).
        echo ""
        echo -e "$LABEL"
        echo ""
        echo "  AUR package — built from source, no fetchable preview"
        if [[ -n "$AUR_HELPER" ]]; then
            "$AUR_HELPER" -Si "$PKG" 2>/dev/null | grep -E '^(Repository|Name|Version|Description|URL|Maintainer)' || true
        fi
    else
        echo ""
        echo -e "$LABEL"
    fi
    exit 0
fi

# ── Legacy installed-theme preview (unchanged shape) ──
THEME_DIR=""
for base in /usr/share/icons "$HOME/.local/share/icons"; do
    if [[ -d "$base/$ENTRY" ]]; then
        THEME_DIR="$base/$ENTRY"
        break
    fi
done
[[ -z "$THEME_DIR" ]] && exit 0

GRID_PNG="$CACHE_DIR/${ENTRY}.png"
render_montage_from_root "$THEME_DIR" "$GRID_PNG"

ACTIVE_MARK=""
[[ -f "$HOME/.local/state/theme/icon-theme" ]] && \
    [[ "$(cat "$HOME/.local/state/theme/icon-theme" 2>/dev/null)" == "$ENTRY" ]] && \
    ACTIVE_MARK="  │  ● active"
render_grid_png "$GRID_PNG" " \e[1m$ENTRY\e[0m${ACTIVE_MARK}"
PREVIEW
chmod +x "$PREVIEW_SCRIPT"

# ── Run fzf ──────────────────────────────────────────
# Ctrl-A copies wallpaper-picker.sh's exact idiom in shape (D-26): one
# surface, same muscle memory, no new keybind, one-way (Esc still
# cancels; the installed list is always what the picker opens on).
STANDARD_HEADER=" 🎨 Icon Theme Picker  │  Ctrl-A browse installable  │  ↑↓ browse  │  Enter confirm  │  Esc cancel"
BROWSE_HEADER=" 🎨 Icon Theme Picker — browsing repo + AUR catalogue  │  ↑↓ browse  │  Enter install  │  Esc cancel"
HEADER="$STANDARD_HEADER"
CTRL_A_BIND=(--bind "ctrl-a:reload(\"$CATALOG_SCRIPT\")+change-header($BROWSE_HEADER)")

SELECTED=$(echo "$THEMES" | fzf \
    --preview "$PREVIEW_SCRIPT {}" \
    --preview-window "right,60%,border-left" \
    "${CTRL_A_BIND[@]}" \
    --header "$HEADER" \
    --header-first \
    --prompt "  " \
    --pointer "▶" \
    --marker "●" \
    --color="bg:${FZF_COLOR_BG:--1},bg+:${FZF_COLOR_BG_PLUS:-#313244},fg:${FZF_COLOR_FG:-#cdd6f4},fg+:${FZF_COLOR_FG_PLUS:-#cba6f7},hl:${FZF_COLOR_HL:-#f5c2e7},hl+:${FZF_COLOR_HL_PLUS:-#f5c2e7}" \
    --color="info:${FZF_COLOR_INFO:-#94e2d5},prompt:${FZF_COLOR_PROMPT:-#cba6f7},pointer:${FZF_COLOR_POINTER:-#f5c2e7},marker:${FZF_COLOR_MARKER:-#f5c2e7},spinner:${FZF_COLOR_SPINNER:-#94e2d5}" \
    --color="header:${FZF_COLOR_HEADER:-#a6adc8},border:${FZF_COLOR_BORDER:-#585b70},gutter:-1" \
    --border rounded \
    --margin 1,2 \
    --padding 1 \
    --no-scrollbar \
    --cycle \
    --reverse) || true

# ── Handle cancellation ───────────────────────────────
if [[ -z "$SELECTED" ]]; then
    exit 0
fi

# Strip the active-theme/installed marker suffix before any use (same
# discipline as wallpaper-picker.sh) — applies to both legacy plain
# names and tab-separated catalogue lines, since `%` strips a literal
# suffix regardless of what precedes it.
SELECTED="${SELECTED% ●}"

if [[ "$SELECTED" == *$'\t'* ]]; then
    # ══════════════════════════════════════════════════
    # Catalogue selection (D-26/D-27/D-28) — install path
    # ══════════════════════════════════════════════════
    IFS=$'\t' read -r SEL_SRC SEL_PKG SEL_DESC <<< "$SELECTED"

    # Defense in depth: package names use a fixed, safe charset — reject
    # anything else before any further processing.
    if [[ ! "$SEL_PKG" =~ ^[a-zA-Z0-9@._+-]+$ ]]; then
        echo "icon-theme-picker: malformed package name in selection" >&2
        exit 1
    fi

    # ── Validate against the real enumerated set (Security Domain V5 /
    # T-13-19) — defense in depth: the fzf return must resolve to a line
    # the catalogue script actually emitted, never free text, before any
    # package-manager invocation. The catalogue is re-derived the same
    # way Ctrl-A produced it (fzf's own internal reload() output is not
    # otherwise observable from this script) and iterated exactly like
    # the installed-list VALID loop above. ────────────────────────────
    CATALOG_NOW=$("$CATALOG_SCRIPT" 2>/dev/null || true)
    VALID=0
    while IFS= read -r entry; do
        entry="${entry% ●}"
        [[ "$entry" == "$SELECTED" ]] && { VALID=1; break; }
    done <<< "$CATALOG_NOW"

    if [[ "$VALID" -ne 1 ]]; then
        echo "icon-theme-picker: selected catalogue entry did not resolve to an enumerated entry: $SEL_PKG" >&2
        exit 1
    fi

    if [[ "$SEL_SRC" != "repo" && "$SEL_SRC" != "aur" ]]; then
        echo "icon-theme-picker: not a selectable catalogue entry" >&2
        exit 1
    fi

    ALREADY_INSTALLED=0
    pacman -Q "$SEL_PKG" &>/dev/null && ALREADY_INSTALLED=1

    if [[ "$ALREADY_INSTALLED" -eq 1 ]]; then
        RESOLVED_THEME=$(pacman -Ql "$SEL_PKG" 2>/dev/null \
            | grep -oE 'usr/share/icons/[^/]+/index\.theme$' \
            | sed -E 's#usr/share/icons/([^/]+)/index\.theme#\1#' \
            | sort -u | head -1 || true)
        if [[ -z "$RESOLVED_THEME" ]]; then
            echo "icon-theme-picker: $SEL_PKG is already installed but ships no recognisable icon-theme directory" >&2
            exit 1
        fi
    else
        # Confirm the package is real in the authoritative database
        # before ever building an install command — never a bespoke
        # legitimacy heuristic, the package manager's own exit code is
        # authoritative (Don't Hand-Roll / T-13-19).
        if [[ "$SEL_SRC" == "repo" ]]; then
            if ! pacman -Si "$SEL_PKG" &>/dev/null; then
                echo "icon-theme-picker: $SEL_PKG did not resolve to a real repo package" >&2
                exit 1
            fi
        else
            if [[ -z "$AUR_HELPER" ]]; then
                echo "icon-theme-picker: no AUR helper available to install $SEL_PKG" >&2
                exit 1
            fi
            if ! "$AUR_HELPER" -Si "$SEL_PKG" &>/dev/null; then
                echo "icon-theme-picker: $SEL_PKG did not resolve to a real AUR package" >&2
                exit 1
            fi
        fi

        # Snapshot before the install so the newly-appeared directory can
        # be diffed out afterward (package name != theme directory name,
        # <assumption_delta_decision>).
        BEFORE=$("$ENUM_SCRIPT" "$ACTIVE_ICON")

        echo ""
        echo "Installing $SEL_PKG — $SEL_DESC — from $SEL_SRC. Review the prompts below:"
        echo ""
        # T-13-15/D-27: prompts and build output stream normally in this
        # real floating terminal. Never an auto-confirm flag on either
        # path — a silent install of an arbitrary user-chosen build
        # recipe would be the actual security regression here.
        INSTALL_OK=1
        if [[ "$SEL_SRC" == "repo" ]]; then
            sudo pacman -S --needed "$SEL_PKG" || INSTALL_OK=0
        else
            "$AUR_HELPER" -S "$SEL_PKG" || INSTALL_OK=0
        fi

        if [[ "$INSTALL_OK" -ne 1 ]]; then
            echo "icon-theme-picker: install of $SEL_PKG failed or was cancelled — no changes made" >&2
            exit 1
        fi

        AFTER=$("$ENUM_SCRIPT" "$ACTIVE_ICON")
        NEW_DIRS=$(comm -13 \
            <(printf '%s\n' "$BEFORE" | sed 's/ ●$//' | sort -u) \
            <(printf '%s\n' "$AFTER" | sed 's/ ●$//' | sort -u))
        NEW_COUNT=$(printf '%s\n' "$NEW_DIRS" | grep -c . || true)

        if [[ "$NEW_COUNT" -eq 0 ]]; then
            echo "icon-theme-picker: $SEL_PKG installed but no new icon-theme directory was detected — leaving the current theme applied" >&2
            exit 0
        elif [[ "$NEW_COUNT" -eq 1 ]]; then
            RESOLVED_THEME="$NEW_DIRS"
        else
            # More than one directory appeared (e.g. light/dark variants)
            # — re-present just those, using the same preview pipeline,
            # rather than silently picking one.
            RESOLVED_THEME=$(printf '%s\n' "$NEW_DIRS" | fzf \
                --preview "$PREVIEW_SCRIPT {}" \
                --preview-window "right,60%,border-left" \
                --header " 🎨 $SEL_PKG shipped multiple icon themes — choose one  │  Enter confirm  │  Esc skip" \
                --header-first \
                --prompt "  " \
                --pointer "▶" \
                --border rounded \
                --margin 1,2 \
                --padding 1 \
                --no-scrollbar \
                --cycle \
                --reverse) || true
            if [[ -z "$RESOLVED_THEME" ]]; then
                echo "icon-theme-picker: $SEL_PKG installed but no theme directory was chosen — leaving the current theme applied" >&2
                exit 0
            fi
        fi
    fi

    SELECTED="$RESOLVED_THEME"
else
    # ── Legacy installed-theme selection — today's behaviour byte-for-
    # byte (Security Domain V5 / T-06-12): the fzf return must resolve to
    # one of the entries the enumeration script actually found, never
    # free text, before any gsettings/path use. ──────────────────────
    VALID=0
    while IFS= read -r entry; do
        entry="${entry% ●}"
        [[ "$entry" == "$SELECTED" ]] && { VALID=1; break; }
    done <<< "$THEMES"

    if [[ "$VALID" -ne 1 ]]; then
        echo "icon-theme-picker: selected entry did not resolve to an enumerated icon theme: $SELECTED" >&2
        exit 1
    fi
fi

# ── Persist as a theme-orthogonal state axis (Pitfall 6/D-19) — the SAME
# tail `--set` runs, factored into `_persist_and_apply()` above so there
# is only one copy (state write, engine re-run, notify; never a bare
# standalone settings write here).
_persist_and_apply "$SELECTED"
