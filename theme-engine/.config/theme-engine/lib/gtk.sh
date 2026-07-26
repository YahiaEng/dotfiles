#!/usr/bin/env bash
# theme-engine/lib/gtk.sh — gsettings toggle + GTK theme env propagation
# (D-13/PIPE-05, THM-01 mode-aware)
#
# gtk.sh is the single mode-aware owner of GTK_THEME propagation (supersedes
# the uwsm/env single-source design — D-07 requires this value to flip with
# mode, and CONTEXT integration notes forbid a second hardcode site; the one
# remaining site is the mode branch below). Mode is read from the committed
# state-dir marker (written by generate.sh during render, before commit —
# atomic render-then-commit invariant), never recomputed here.

# theme_engine_gtk_reload
theme_engine_gtk_reload() {
    # THM-01: read the committed mode marker, graceful degradation to
    # "dark" (the pre-existing behavior) on pre-migration state where the
    # marker doesn't exist yet.
    local mode
    mode="$(cat "$HOME/.local/state/theme/mode" 2>/dev/null || echo "dark")"

    local color_scheme="prefer-dark"
    local gtk3_theme="adw-gtk3-dark"
    if [[ "$mode" == "light" ]]; then
        color_scheme="prefer-light"
        gtk3_theme="adw-gtk3"
    fi

    # Mode-correct dynamic GTK_THEME propagation — no inherited/stale value,
    # no second hardcode site (D-07).
    export GTK_THEME="$gtk3_theme"
    systemctl --user set-environment GTK_THEME="$gtk3_theme" 2>/dev/null || true
    dbus-update-activation-environment --systemd GTK_THEME 2>/dev/null || true

    # gsettings toggle — works when xdg-desktop-portal-gtk is running.
    gsettings set org.gnome.desktop.interface color-scheme "$color_scheme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null || true
    sleep 0.1
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk3_theme" 2>/dev/null || true

    # ── D-06/D-08/D-20: motion-scale's system-wide reduced-motion signal ──
    # TOKEN-05 says "across every surface" — without this line, the axis
    # would only affect the handful of surfaces this repo authors itself,
    # which is a false accessibility claim rather than a partial
    # implementation. org.gnome.desktop.interface enable-animations is read
    # LIVE (no restart) through the portal by every third-party GTK3/GTK4
    # and libadwaita application, exactly the surfaces this repo's own
    # motion tokens cannot reach. theme_engine_read_motion_scale is already
    # in scope here: theme-apply sources lib/generate.sh (which sources
    # lib/motion.sh) before lib/gtk.sh, so the function exists in this
    # process by the time theme_engine_gtk_reload runs. The mapping is
    # total over the closed four-preset set — "off" is the only preset
    # that disables at the toolkit level (D-08); every other preset
    # (including "reduced", which SCALES durations rather than removing
    # them) leaves animations enabled, so no default branch can silently
    # leave this key stale. This is the block's only writer for this key —
    # no other line in the pipeline touches enable-animations.
    local motion_scale enable_animations
    motion_scale="$(theme_engine_read_motion_scale 2>/dev/null || echo normal)"
    enable_animations="true"
    [[ "$motion_scale" == "off" ]] && enable_animations="false"
    gsettings set org.gnome.desktop.interface enable-animations "$enable_animations" 2>/dev/null || true

    # ── GTK4/libadwaita accent color (THEME-03/D-17, dark-only ceiling) ──
    # GTK4/libadwaita apps read color-scheme + accent-color live from
    # org.gnome.desktop.interface via the portal (GNOME47+ accent key,
    # confirmed present on this libadwaita 1.9.2). This is a best-effort
    # single-swatch approximation of the full Material You palette — the
    # fuller palette path is the named-color gtk-4.0/gtk.css @import
    # (wired in Plan 01-02). Full GTK4/libadwaita palette theming beyond
    # dark + one accent swatch is structurally unsupported upstream; this
    # is the realistic ceiling, not a gap (THEME-03).
    theme_engine_gtk4_accent

    # ── Icon-theme axis (UTIL-04/D-16/D-17/D-19) ───────────────────────
    # Theme-orthogonal — applies whatever the icon-theme state file holds
    # (generate.sh already rendered it into settings.ini for GTK3's
    # restart-based reload above/below; this call is the GTK4 live-gsettings
    # path plus the Papirus/Tela/Colloid folder-accent tracking).
    theme_engine_apply_icon_theme

    # GTK3 apps cannot hot-reload CSS — restart the background Thunar
    # daemon so the CSS baseline is fresh for the next window (D-15).
    #
    # Empirically corrected this plan: Thunar is a D-Bus single-instance
    # app on this system — there is only ever ONE thunar process, whether
    # it was started as `--daemon` or as a plain window. `thunar --quit`
    # tears down that WHOLE process, closing any open window along with
    # it (verified live: opening a window against a running `--daemon`
    # process reuses the same PID, and `--quit` closed the window too —
    # see SUMMARY). There is no separate "daemon-only" PID to target once
    # a window is attached, so the only way to honor the "never kill a
    # visible window" invariant is to skip the restart while a window is
    # open, deferring the fresh-CSS restart until Thunar returns to its
    # windowless resting state.
    if pgrep -x thunar >/dev/null 2>&1; then
        local thunar_has_window=0
        if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
            if hyprctl clients -j 2>/dev/null \
                | jq -e '[.[] | select(.class | ascii_downcase == "thunar")] | length > 0' \
                >/dev/null 2>&1; then
                thunar_has_window=1
            fi
        fi

        if [[ "$thunar_has_window" == "1" ]]; then
            # Deviation, fix(01-03) round 2: the notify-and-skip branch
            # used to leave the daemon stale INDEFINITELY — nothing ever
            # re-fired the restart once the window closed, so Thunar kept
            # serving the CSS baseline from whatever theme was active when
            # the window was first opened, no matter how many switches
            # happened afterward. Fixed by spawning ONE detached watcher
            # that polls until no Thunar window remains, then performs the
            # same bounded quit/relaunch as the immediate path below.
            notify-send -a "Thunar" "Notice" "New theme applied. Thunar will refresh automatically once all windows are closed." -t 3000 2>/dev/null || true

            local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
            local lock_dir="$runtime_dir/theme-engine-thunar-watcher.lock"

            # Self-heal a stale lock (e.g. left behind by a killed/crashed
            # prior watcher) before attempting to acquire it, so a single
            # bad run can't permanently block future deferred restarts.
            if [[ -d "$lock_dir" ]]; then
                local existing_pid=""
                [[ -f "$lock_dir/pid" ]] && existing_pid=$(cat "$lock_dir/pid" 2>/dev/null)
                if [[ -z "$existing_pid" ]] || ! kill -0 "$existing_pid" 2>/dev/null; then
                    rm -rf "$lock_dir" 2>/dev/null || true
                fi
            fi

            # `mkdir` is atomic, so this doubles as a dedupe lock: if a
            # watcher from an EARLIER switch is still polling, do not
            # stack a second one. The single existing watcher already
            # covers this newer switch too — it re-reads Thunar's window
            # state and, when it finally restarts the daemon, always picks
            # up whatever CSS is CURRENT in ~/.local/state/theme/ at that
            # moment (after commit.sh's atomic move), never a stale
            # snapshot from when it was first spawned. No cancel/replace
            # logic is needed for correctness — only for not wasting a
            # redundant background process.
            if mkdir "$lock_dir" 2>/dev/null; then
                export -f theme_engine_thunar_deferred_watcher 2>/dev/null || true
                setsid bash -c "theme_engine_thunar_deferred_watcher '$lock_dir'" >/dev/null 2>&1 </dev/null &
                disown
            fi
        else
            # Bounded poll instead of a fixed sleep for the exit wait
            # (Don't-Hand-Roll table); falls through to a forced kill
            # after the cap (T-03-01) rather than hang the switch on a
            # daemon that never exits.
            thunar --quit 2>/dev/null || true

            local waited=0
            while pgrep -x thunar >/dev/null 2>&1 && (( waited < 20 )); do
                sleep 0.1
                waited=$(( waited + 1 ))
            done
            if pgrep -x thunar >/dev/null 2>&1; then
                killall -q -9 thunar 2>/dev/null || true
            fi

            # Fully detach so a long-running daemon never holds a
            # caller's pipe/fd open (same rationale as the walker
            # relaunch in reload.sh).
            setsid uwsm app -- thunar --daemon >/dev/null 2>&1 </dev/null &
            disown
        fi
    fi
}

# theme_engine_thunar_deferred_watcher — deviation, fix(01-03) round 2.
# Runs fully detached (setsid, own bash -c invocation via `export -f` so
# it survives theme-apply's own process exiting). Polls Thunar's window
# state every 5s until no window remains, then performs the identical
# bounded quit/relaunch as the immediate restart path above, so the
# daemon never stays stale past the point the user closes their last
# Thunar window. Bounded to ~60 minutes total (T-03-01) so a window left
# open indefinitely cannot leave a watcher process running forever — the
# daemon simply stays on the old palette until the NEXT theme switch
# re-arms a fresh watcher, same graceful-degradation shape as the rest of
# this engine's bounded polls.
#
# Accepted race (documented, not fixed): if a NEW Thunar window opens in
# the instant between this watcher's "no window" check and the
# `thunar --quit` call below, that window is closed along with the
# daemon — the same inherent limitation noted in theme_engine_gtk_reload
# above (Thunar has no separate daemon-only PID to target once a window
# is attached). Narrow window, accepted for a personal single-user
# desktop; not worth a second, more invasive detection layer.
theme_engine_thunar_deferred_watcher() {
    local lock_dir="$1"
    echo $$ > "$lock_dir/pid" 2>/dev/null || true

    local max_polls=720
    local n=0
    while (( n < max_polls )); do
        if ! pgrep -x thunar >/dev/null 2>&1; then
            # Thunar exited entirely on its own (e.g. user quit it) —
            # nothing left to restart; the next `thunar --daemon` launch
            # (ours or a future window) picks up fresh CSS naturally.
            break
        fi

        local still_open=0
        if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
            if hyprctl clients -j 2>/dev/null \
                | jq -e '[.[] | select(.class | ascii_downcase == "thunar")] | length > 0' \
                >/dev/null 2>&1; then
                still_open=1
            fi
        fi

        if [[ "$still_open" == "0" ]]; then
            thunar --quit 2>/dev/null || true

            local waited=0
            while pgrep -x thunar >/dev/null 2>&1 && (( waited < 20 )); do
                sleep 0.1
                waited=$(( waited + 1 ))
            done
            if pgrep -x thunar >/dev/null 2>&1; then
                killall -q -9 thunar 2>/dev/null || true
            fi

            setsid uwsm app -- thunar --daemon >/dev/null 2>&1 </dev/null &
            disown
            break
        fi

        sleep 5
        n=$(( n + 1 ))
    done

    rm -rf "$lock_dir" 2>/dev/null || true
}

# theme_engine_gtk4_accent — best-effort GTK4/libadwaita accent-color
# mapping (D-17). gsettings' accent-color key is a fixed enum (blue,
# teal, green, yellow, orange, red, pink, purple, slate) — not an
# arbitrary hex — so this maps the state dir's Material You accent hex
# to the nearest enum member by hue. Never blocks/fails theme_engine_gtk_reload
# on error (best-effort, dark-only ceiling per THEME-03).
theme_engine_gtk4_accent() {
    local colors_file="$HOME/.local/state/theme/gtk-4.0-colors.css"
    [[ -f "$colors_file" ]] || return 0
    command -v python3 >/dev/null 2>&1 || return 0

    local hex
    hex=$(grep -m1 '@define-color accent_color ' "$colors_file" 2>/dev/null | grep -oE '#[0-9a-fA-F]{6}')
    [[ -n "$hex" ]] || return 0

    local accent
    accent=$(python3 - "$hex" <<'PYEOF' 2>/dev/null
import colorsys, sys
hexv = sys.argv[1].lstrip('#')
r, g, b = (int(hexv[i:i+2], 16) / 255.0 for i in (0, 2, 4))
h, s, l = colorsys.rgb_to_hls(r, g, b)[0], colorsys.rgb_to_hls(r, g, b)[2], colorsys.rgb_to_hls(r, g, b)[1]
deg = h * 360
if s < 0.15:
    print("slate")
elif deg < 15 or deg >= 345:
    print("red")
elif deg < 45:
    print("orange")
elif deg < 70:
    print("yellow")
elif deg < 160:
    print("green")
elif deg < 195:
    print("teal")
elif deg < 255:
    print("blue")
elif deg < 290:
    print("purple")
else:
    print("pink")
PYEOF
)
    [[ -n "$accent" ]] || return 0
    gsettings set org.gnome.desktop.interface accent-color "$accent" 2>/dev/null || true
}

# theme_engine_apply_icon_theme — best-effort icon-theme axis apply
# (UTIL-04, D-16/D-17). Reads the theme-orthogonal icon-theme state file
# (generate.sh already folded it into settings.ini for GTK3's restart-based
# reload; this is the live GTK4 gsettings path) and, for the two icon sets
# that support palette-tracked folder/variant accents, tracks the current
# palette's primary hue:
#   - Papirus (or Papirus-Dark/-Light): one theme name, folders recolored
#     in place via `papirus-folders -C <named-color> -t <variant>` (D-17).
#   - Tela/Colloid: N separately-baked full theme-name variants, no
#     folder-recolor tool — nearest-hue variant is a full icon-theme
#     name swap instead (Pitfall 3), scoped to whatever variants are
#     actually installed (never a hardcoded variant list).
# Adwaita/anything else: plain gsettings icon-theme write, no accent
# tracking. Never blocks/fails theme_engine_gtk_reload (same best-effort,
# return-0-on-any-error discipline as theme_engine_gtk4_accent above).
theme_engine_apply_icon_theme() {
    local icon_theme
    icon_theme="$(cat "$HOME/.local/state/theme/icon-theme" 2>/dev/null || echo Adwaita)"
    [[ -z "$icon_theme" || "$icon_theme" == "Adwaita" ]] && return 0

    local colors_file="$HOME/.local/state/theme/gtk-4.0-colors.css"
    local hex=""
    if [[ -f "$colors_file" ]]; then
        hex=$(grep -m1 '@define-color primary ' "$colors_file" 2>/dev/null | grep -oE '#[0-9a-fA-F]{6}')
    fi

    case "$icon_theme" in
        Papirus|Papirus-Dark|Papirus-Light)
            # Name itself never changes — folders are recolored in place.
            gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
            if [[ -n "$hex" ]] && command -v papirus-folders >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
                local color
                color="$(theme_engine_nearest_papirus_color "$hex")"
                [[ -n "$color" ]] && papirus-folders -C "$color" -t "$icon_theme" 2>/dev/null || true
            fi
            ;;
        Tela*|Colloid*)
            # Pitfall 3: no folder-recolor tool — nearest-hue variant is a
            # full theme-name swap among whatever "<base>-*" directories
            # are actually installed (real enumeration, never a hardcoded
            # variant list — Open Question 1). An exact hue match swaps the
            # name; anything else leaves the user's pick untouched, so this
            # stays in lockstep with the settings.ini value generate.sh
            # writes from the same state file.
            local base="${icon_theme%%-*}"
            local nearest="$icon_theme"
            if [[ -n "$hex" ]] && command -v python3 >/dev/null 2>&1; then
                local found
                found="$(theme_engine_nearest_icon_variant "$base" "$hex")"
                [[ -n "$found" ]] && nearest="$found"
            fi
            gsettings set org.gnome.desktop.interface icon-theme "$nearest" 2>/dev/null || true
            ;;
        *)
            gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
            ;;
    esac

    return 0
}

# theme_engine_nearest_papirus_color <hex> — maps an arbitrary palette hex
# to the nearest member of papirus-folders' fixed named-color enum (D-17;
# RESEARCH.md Standard Stack, verified against
# github.com/PapirusDevelopmentTeam/papirus-folders). Same hue-bucket
# idiom as theme_engine_gtk4_accent above, swapped to the wider 23-name
# enum (excludes the cat-* Catppuccin extras — not needed here).
theme_engine_nearest_papirus_color() {
    local hex="$1"
    python3 - "$hex" <<'PYEOF' 2>/dev/null
import colorsys, sys
hexv = sys.argv[1].lstrip('#')
r, g, b = (int(hexv[i:i+2], 16) / 255.0 for i in (0, 2, 4))
h, l, s = colorsys.rgb_to_hls(r, g, b)
deg = h * 360
if s < 0.12:
    if l > 0.85:
        print("white")
    elif l < 0.15:
        print("black")
    else:
        print("grey")
elif deg < 10 or deg >= 350:
    print("red")
elif deg < 22:
    print("carmine-red")
elif deg < 34:
    print("deeporange")
elif deg < 44:
    print("orange")
elif deg < 52:
    print("bright-orange")
elif deg < 60:
    print("paleorange")
elif deg < 68:
    print("palebrown")
elif deg < 78:
    print("brown")
elif deg < 100:
    print("yellow")
elif deg < 130:
    print("oxidgreen")
elif deg < 155:
    print("green")
elif deg < 175:
    print("teal")
elif deg < 195:
    print("cyan")
elif deg < 215:
    print("breeze")
elif deg < 235:
    print("nordic")
elif deg < 250:
    print("blue")
elif deg < 265:
    print("indigo")
elif deg < 285:
    print("violet")
elif deg < 305:
    print("magenta")
else:
    print("pink")
PYEOF
}

# theme_engine_nearest_icon_variant <base> <hex> — Tela/Colloid nearest-
# fixed-variant lookup (Pitfall 3). Enumerates whatever "<base>-*"
# (and bare "<base>") index.theme directories are ACTUALLY installed
# under /usr/share/icons and ~/.local/share/icons (Security Domain V5 —
# real enumeration, never a hardcoded variant list — Open Question 1),
# computes the ideal hue-bucket color name via the same enum as
# theme_engine_nearest_papirus_color, then returns the installed variant
# whose color-suffix matches exactly.
#
# Emits NOTHING when there is no exact match. The papirus-folders enum this
# borrows (carmine-red, oxidgreen, breeze, nordic, …) does not share a
# vocabulary with Tela/Colloid's variant names (Tela-blue, Tela-nord, …), so
# a miss is the common case, not the edge case. Returning an arbitrary
# installed variant here would silently override the user's explicit pick on
# every theme switch — and desync gsettings from the settings.ini value
# generate.sh writes, leaving GTK3 (Thunar) and GTK4 on different icon
# themes. Empty output means "no substitution"; the caller keeps the pick.
theme_engine_nearest_icon_variant() {
    local base="$1"
    local hex="$2"

    local dir installed=()
    for dir in /usr/share/icons "$HOME/.local/share/icons"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r -d '' found; do
            installed+=("$(basename "$found")")
        done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d \
            \( -iname "${base}" -o -iname "${base}-*" \) \
            -exec test -e {}/index.theme \; -print0 2>/dev/null)
    done

    [[ ${#installed[@]} -gt 0 ]] || return 0

    # Deterministic order — find(1) returns directory order, which varies
    # across runs and machines.
    mapfile -t installed < <(printf '%s\n' "${installed[@]}" | sort -u)

    local ideal
    ideal="$(theme_engine_nearest_papirus_color "$hex")"

    local candidate
    for candidate in "${installed[@]}"; do
        [[ "$candidate" == "${base}-${ideal}" ]] && { printf '%s\n' "$candidate"; return 0; }
    done

    return 0
}
