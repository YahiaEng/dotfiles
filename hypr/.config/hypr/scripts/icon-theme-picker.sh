#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║   ICON THEME PICKER — machine-facing backend, no interactive UI   ║
# ║                                                                    ║
# ║  D-03 (quick task 260828-ah9): the fzf-in-floating-kitty picker    ║
# ║  and its montage icon-grid preview / repo+AUR catalogue browse     ║
# ║  are RETIRED. The montage grid and live specimen were the only     ║
# ║  thing this script offered that the QML surfaces (the Atelier's    ║
# ║  Icons tab, the launcher's `icon` route) could not — so the QML    ║
# ║  now owns the interactive half, and this script keeps exactly the  ║
# ║  tail every one of those surfaces calls:                           ║
# ║                                                                    ║
# ║    --list             installed icon-theme names                  ║
# ║    --set <name>       persist + re-apply (state write, theme-apply ║
# ║                       re-run, notify)                              ║
# ║    --preview <t> [sz] 12-probe montage rows for one theme, for the ║
# ║                       Atelier/launcher preview grids (Task 1, M1)  ║
# ║                                                                    ║
# ║  The catalogue browse+install this script used to do interactively ║
# ║  now lives in AppearanceBackend.qml's own catalogue functions      ║
# ║  (Task 3, D-04) — this script contributes no catalogue code of its ║
# ║  own any more.                                                     ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

ICON_STATE="$HOME/.local/state/theme/icon-theme"
CURRENT_THEME_FILE="$HOME/.local/state/theme/current-theme"

# ── The whole surface this script offers now (quick-260821-6z1 Task 10,
#    R-6; interactive half retired in quick task 260828-ah9, D-03) —
#    `--list`/`--set <name>`. Covers ONLY the already-INSTALLED theme
#    set, via a real directory scan (never a hardcoded list). Catalogue
#    browse+install (not-yet-installed repo/AUR packages) is QML's job
#    now — `AppearanceBackend.qml`'s own catalogue functions (Task 3) —
#    this script contributes no catalogue code any more.
#    `_persist_and_apply()` is the one tail every QML surface's apply
#    call runs through (state write, theme-apply re-run, notify) — one
#    copy, every caller. ──────────────────────────────────────────────
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

# ── Icon lookup, biased to a requested size (quick task 260828-ah9, Task 1)
#    ──────────────────────────────────────────────────────────────────────
# Same two freedesktop directory-naming conventions the retired interactive
# preview's `find_icon_variant` used (SIZExSIZE/category/ first, then the
# inverted category/SIZE/), but tried at the REQUESTED size first, before
# either convention's unfiltered any-size fallback — M1 exists precisely
# because a caller asking for 22px must not silently receive a 48px hit.
_find_icon_at_size() {
    # `-L`: a delta theme like Papirus-Dark only OWNS a handful of
    # categories at each size (measured: `actions` at every override
    # size, plus `devices`/`places` at 16px) and reaches everything else
    # — `apps`, `mimetypes`, every non-overridden size — through real
    # per-category SYMLINKS into its base theme's own directories
    # (verified: `22x22/apps -> ../../Papirus/22x22/apps`). Plain `find`
    # does not descend into a symlinked directory, so without `-L` this
    # would report Papirus-Dark as covering only 4 of the 12 probe names
    # — an instrument fault, not what a real icon-theme loader (or a
    # `ls -R` through the theme) actually sees.
    local root="$1" name="$2" size="$3" f
    f=$(find -L "$root" -type f \( -iname "${name}.svg" -o -iname "${name}.png" \) -path "*/${size}x${size}/*" 2>/dev/null | head -1)
    if [[ -z "$f" ]]; then
        f=$(find -L "$root" -type f \( -iname "${name}.svg" -o -iname "${name}.png" \) -regextype posix-extended -iregex ".*/${size}/[^/]+\.(svg|png)" 2>/dev/null | head -1)
    fi
    if [[ -z "$f" ]]; then
        f=$(find -L "$root" -type f \( -iname "${name}.svg" -o -iname "${name}.png" \) -path '*/[0-9]*x[0-9]*/*' 2>/dev/null | head -1)
    fi
    if [[ -z "$f" ]]; then
        f=$(find -L "$root" -type f \( -iname "${name}.svg" -o -iname "${name}.png" \) -regextype posix-extended -iregex '.*/[0-9]+/[^/]+\.(svg|png)' 2>/dev/null | head -1)
    fi
    if [[ -z "$f" ]]; then
        f=$(find -L "$root" -type f \( -iname "${name}.svg" -o -iname "${name}.png" \) 2>/dev/null | head -1)
    fi
    # Explicit `return 0`: under this script's own `set -e`, a bare
    # `_f=$(_find_icon_at_size ...)` assignment at the call site propagates
    # this function's own exit status (unlike a `local` assignment, which
    # masks it) — a probe that legitimately finds nothing must not abort
    # the whole `--preview` loop after just a few rows (M3: a miss is
    # printed as `-`, never treated as an error).
    [[ -n "$f" ]] && printf '%s\n' "$f"
    return 0
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
    --preview)
        # QML-facing: emits `<probeName>\t<absolutePath>` for each of the
        # 12 probe names below, or `<probeName>\t-` when nothing resolves
        # in any size under any name in the chain (M3 — coverage is
        # information to show, not hide). Default size 22 per M1.
        THEME="${2:-}"
        SIZE="${3:-22}"
        [[ -n "$THEME" ]] || { echo "icon-theme-picker.sh --preview: theme name required" >&2; exit 1; }
        THEME_DIR=""
        for base in /usr/share/icons "$HOME/.local/share/icons"; do
            if [[ -d "$base/$THEME" ]]; then
                THEME_DIR="$base/$THEME"
                break
            fi
        done
        [[ -n "$THEME_DIR" ]] \
            || { echo "icon-theme-picker.sh --preview: '$THEME' is not an installed icon theme" >&2; exit 1; }
        PROBE_NAMES=(folder user-home network-server drive-harddisk applications-system utilities-terminal text-x-generic image-x-generic audio-x-generic video-x-generic package-x-generic preferences-system)
        for _n in "${PROBE_NAMES[@]}"; do
            _f=$(_find_icon_at_size "$THEME_DIR" "$_n" "$SIZE")
            if [[ -n "$_f" ]]; then
                printf '%s\t%s\n' "$_n" "$_f"
            else
                printf '%s\t-\n' "$_n"
            fi
        done
        exit 0
        ;;
esac
