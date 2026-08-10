#!/usr/bin/env bash
# theme-engine/lib/wallpaper.sh — static-preset wallpaper auto-set (D-11/D-12)
#
# Only called for static presets, after theme_engine_commit succeeds and
# before theme_engine_reload — so a themed desktop lands with a matching
# wallpaper in one action (CONTEXT "Omarchy-style one-action coherence").
# Material You keeps the existing wallpaper-drives-palette direction (D-11):
# this function is a no-op for both materialyou and materialyou-light.
#
# Every step here is best-effort (`|| true`) — auto-set is cosmetic and must
# never fail theme-apply's exit code (Shared Patterns: best-effort, never-
# block error handling).

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
LAST_WALLPAPER_DIR="$HOME/.local/state/theme/last-wallpaper"
# D-07: engine-owned frame directory (registered in contract.json below) —
# the still frames extracted from live/ wallpapers, D-06/D-08's source of
# truth for current.jpg whenever the recorded choice is live.
FRAME_DIR="$HOME/.local/state/theme/wallpaper-frames"
# D-09: fixed seek-offset default, Claude's discretion per CONTEXT.md.
# Typical wallpaper loops open on a fade-in; the frame-0 fallback in
# theme_engine_wallpaper_extract_frame already covers clips shorter than
# this offset.
FRAME_OFFSET_DEFAULT=3

# theme_engine_wallpaper_is_live_ref <value>
# The shape half of the D-12/T-05-07 widening (Security Domain V5). Returns
# 0 for EXACTLY one form: `live/` followed by one path component that
# contains no `/` and is neither `.` nor `..`. Returns nonzero for
# everything else, including `live/a/b`, `live/`, `live`, `/etc/passwd`,
# `../clip.mp4` and the empty string. Pure string test — no filesystem
# access; the existence half (`-f`) stays paired at every call site, the
# same way the pre-existing bare-filename branch pairs its own shape test
# with `-f "$theme_dir/$recorded"`.
#
# This is a WIDENING of T-05-07's existing rejection of any `/`-bearing
# recorded value — it must never be relaxed into a prefix test (e.g.
# `[[ "$value" == live/* ]]`), which would admit traversal shapes like
# `live/../../../../etc/passwd`. theme-doctor (Task 3) reuses this exact
# function rather than re-implementing the regex, so the engine and the
# doctor can never drift on what counts as a live ref.
theme_engine_wallpaper_is_live_ref() {
    local value="$1"
    [[ "$value" =~ ^live/([^/]+)$ ]] || return 1
    local component="${BASH_REMATCH[1]}"
    [[ "$component" != "." && "$component" != ".." ]]
}

# theme_engine_wallpaper_frame_path <theme> <recorded>
# Prints $FRAME_DIR/<theme>/<component>.png, where <component> is
# <recorded> with the leading `live/` stripped. `.png` is APPENDED, never
# substituted for the source extension, so `clip.mp4` and `clip.gif` in the
# same folder cannot collide onto one frame path. Per-source frame paths
# are also what makes D-08's absent-or-zero-byte check correct when the
# *selection* changes: a different source is a different path, so a fresh
# selection is naturally absent and re-extracts with no extra logic.
theme_engine_wallpaper_frame_path() {
    local theme="$1" recorded="$2"
    local component="${recorded#live/}"
    printf '%s\n' "$FRAME_DIR/$theme/$component.png"
}

# theme_engine_wallpaper_frame_offset <theme> <recorded>
# D-09's per-video seek-offset override reader. Reads the first line of the
# sidecar at the frame path with `.png` replaced by `.offset` — the
# operator-editable override surface, which survives commit.sh's
# `rsync --delete` because `wallpaper-frames` is engine-owned (D-07).
# Accepts the value ONLY when it is digits with an optional dot and up to
# three further digits, and is numerically no greater than 86400; prints
# the accepted value, otherwise prints $FRAME_OFFSET_DEFAULT. This
# validation is not cosmetic — the value becomes an `-ss` argument to
# ffmpeg (T-17-07): the ffmpeg call is always a bash array expanded
# "${cmd[@]}", never a shell string, so an accepted value can only ever
# reach ffmpeg as one argv element regardless of its content, but a
# malformed value (injection attempt, negative, scientific notation, an
# out-of-range magnitude) must still never reach that argv position.
theme_engine_wallpaper_frame_offset() {
    local theme="$1" recorded="$2"
    local frame_path offset_path value
    frame_path="$(theme_engine_wallpaper_frame_path "$theme" "$recorded")"
    offset_path="${frame_path%.png}.offset"
    value=$(head -n1 "$offset_path" 2>/dev/null || true)

    if [[ "$value" =~ ^[0-9]+(\.[0-9]{1,3})?$ ]] && awk -v v="$value" 'BEGIN { exit !(v <= 86400) }'; then
        printf '%s\n' "$value"
        return 0
    fi

    printf '%s\n' "$FRAME_OFFSET_DEFAULT"
}

# theme_engine_wallpaper_extract_frame <source> <dest> <offset>
# The ffmpeg wrapper implementing D-08/D-09/D-10, with both RESEARCH-
# reproduced silent-failure traps closed by construction:
#
# TRAP 1 (RESEARCH Pitfall 1): placing `-ss` BEFORE `-i` yields ZERO output
# for animated WebP (ffmpeg 9.0's webp_anim demuxer reports `Duration: N/A`
# — fast input-seeking has nothing to target) while still working for mp4
# and gif. One command shape, no per-format branch: the offset flag sits
# AFTER the input flag below, and this ordering is load-bearing, not
# stylistic.
#
# TRAP 2 (RESEARCH Pitfall 2): ffmpeg exits 0 with NO output file on an
# out-of-range seek. The success signal after each attempt is
# `[[ -s "$dest" ]]` and NOTHING ELSE — the exit status of the ffmpeg
# invocation itself is never consulted.
#
# Attempt 2 is D-09's frame-0 fallback: the same array without the offset
# flag/value, run only when attempt 1 left no non-empty destination.
# D-10 requires PNG at source resolution — no video-filter flag, no
# output-size flag, no resizing of any kind, ever. Every invocation is a
# bash array expanded "${cmd[@]}" — never a single string, never shell
# evaluation.
theme_engine_wallpaper_extract_frame() {
    local source="$1" dest="$2" offset="$3"
    mkdir -p "$(dirname -- "$dest")" 2>/dev/null || true

    local -a cmd=(ffmpeg -y -i "$source" -ss "$offset" -frames:v 1 -update 1 "$dest")
    "${cmd[@]}" &>/dev/null || true
    if [[ -s "$dest" ]]; then
        return 0
    fi

    local -a cmd_fallback=(ffmpeg -y -i "$source" -frames:v 1 -update 1 "$dest")
    "${cmd_fallback[@]}" &>/dev/null || true
    [[ -s "$dest" ]]
}

# theme_engine_wallpaper_autoset <name>
theme_engine_wallpaper_autoset() {
    local name="$1"

    # D-11: dynamic mode keeps wallpaper -> palette direction; auto-set is
    # static-only. Never touch current.jpg for either Material You name.
    if [[ "$name" == "materialyou" || "$name" == "materialyou-light" ]]; then
        return 0
    fi

    local theme_dir="$WALLPAPER_DIR/$name"
    [[ -d "$theme_dir" ]] || return 0

    # Same extension filter + enumeration idiom as wallpaper-picker.sh
    # (maxdepth 1, filename-only, exclude current.jpg — Security Domain V5:
    # never trust raw interpolation, enumerate real files only).
    local images
    images=$(find "$theme_dir" -maxdepth 1 \
        -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) \
        ! -name "current.jpg" \
        -printf "%f\n" 2>/dev/null | sort)

    # D-03: separate, unfiltered live/ enumeration pass. Deliberately NEVER
    # merged into $images — the still pool must stay pure, since it is
    # D-13's fallback source and D-03 exists precisely to stop a stray
    # still inside live/ leaking into the image pool. No -iname filter here
    # (D-01 defines "live" by behaviour, not container; D-04 sends
    # everything under live/ to one backend).
    local live_entries
    live_entries=$(find "$theme_dir/live" -maxdepth 1 -type f -printf 'live/%f\n' 2>/dev/null | sort)

    # Empty/missing BOTH pools — keep the current wallpaper untouched (D-12
    # never-a-dead-end semantics on the apply side). This early return used
    # to fire on $images alone, which silently skipped a theme directory
    # containing only live wallpapers and did nothing at all on a switch to
    # it (D-03's live-only-theme fix).
    [[ -n "$images" || -n "$live_entries" ]] || return 0

    # Candidate selection: prefer the recorded last-used file for this
    # theme. T-05-07, widened per D-12: admit either the pre-existing bare
    # still-filename shape (unchanged) OR exactly one additional shape — a
    # single-component live/ ref, validated by
    # theme_engine_wallpaper_is_live_ref (Task 1's widened helper, never a
    # prefix test). The existence test (-f) stays mandatory on BOTH
    # branches — never interpolate untrusted state-file content into a
    # path without validation.
    local chosen="" dead_live_entry=0
    local last_used_file="$LAST_WALLPAPER_DIR/$name"
    if [[ -f "$last_used_file" ]]; then
        local recorded
        recorded=$(head -n1 "$last_used_file" 2>/dev/null || true)
        if [[ -n "$recorded" ]] && \
           { [[ "$recorded" != */* && -f "$theme_dir/$recorded" ]] || \
             { theme_engine_wallpaper_is_live_ref "$recorded" && [[ -f "$theme_dir/$recorded" ]]; }; }; then
            chosen="$recorded"
        elif [[ -n "$recorded" ]] && theme_engine_wallpaper_is_live_ref "$recorded"; then
            # D-13: shape is a valid live ref but the file is gone — clear
            # the dead entry (never mutates a still-shaped recorded value's
            # own pre-existing silent-ignore behaviour) and remember that
            # the live pool must NOT be used as this call's fallback below:
            # D-13 falls back to the theme's first STILL, never to another
            # live entry, when the recorded live pick has disappeared.
            rm -f "$last_used_file" 2>/dev/null || true
            dead_live_entry=1
        fi
    fi

    # Fall back to the first still by sorted name (D-11/D-13). Only when
    # there is truly no still AND this is not D-13's dead-live-entry path
    # does a live-only theme fall back to its first live entry (D-03's
    # live-only-theme fix) — D-13 itself never auto-selects a replacement
    # live wallpaper for one that was just deleted; with no still to fall
    # back to either, the caller falls through to the empty-chosen guard
    # below and the current wallpaper is left untouched (never-a-dead-end).
    if [[ -z "$chosen" ]]; then
        if [[ -n "$images" ]]; then
            chosen=$(head -n1 <<< "$images")
        elif [[ "$dead_live_entry" -eq 0 && -n "$live_entries" ]]; then
            chosen=$(head -n1 <<< "$live_entries")
        fi
    fi

    [[ -n "$chosen" ]] || return 0

    if theme_engine_wallpaper_is_live_ref "$chosen"; then
        # D-06/D-08: live choice — repoint current.jpg at the FRAME, never
        # the video — this is what makes the lock screen
        # (hyprlock.conf:50) show a real frame in EVERY mode. D-05 needs
        # no code here: a static preset renders its palette from
        # palettes/$name.json and never reads current.jpg, so the frame
        # reaches the lock screen everywhere while the palette stays
        # coupled to current.jpg only through generate.sh's Material You
        # branch.
        #
        # 17-03 hardening (found during the AMB-01 render gate's own
        # investigation, not the gate's root cause but a real gap this
        # function shared with no other frame consumer in this file):
        # re-extract ONLY when the frame is missing or empty — the SAME
        # cache-warm check theme_engine_wallpaper_frame_repair and the
        # picker's preview pane already use. autoset runs on EVERY
        # theme-apply (including a motion-scale/idle/gaming-triggered
        # re-render that changes nothing about the wallpaper choice
        # itself), so re-extracting unconditionally wasted a full ffmpeg
        # invocation on every one of those and left current.jpg dependent
        # on that invocation succeeding every single time rather than
        # only once.
        local frame offset
        frame="$(theme_engine_wallpaper_frame_path "$name" "$chosen")"
        if [[ ! -s "$frame" ]]; then
            offset="$(theme_engine_wallpaper_frame_offset "$name" "$chosen")"
            theme_engine_wallpaper_extract_frame "$theme_dir/$chosen" "$frame" "$offset" || true
        fi
        if [[ -s "$frame" ]]; then
            ln -sfr "$frame" "$WALLPAPER_DIR/current.jpg" 2>/dev/null || true
        fi
        # Extraction failed (or produced nothing): leave the existing
        # current.jpg pointer completely untouched — current.jpg is the
        # hyprlock background on every unlock, and a dangling pointer is a
        # lock screen with no background (T-17-09).

        # Best-effort live preview — same graphical-session guard as the
        # still branch below, headless container gate must never hang
        # here. awww owns the static-image path (D-04); it is handed the
        # extracted FRAME, never the source video, which awww cannot play.
        if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] \
            && command -v awww >/dev/null 2>&1 && [[ -s "$frame" ]]; then
            awww img "$frame" \
                --transition-type center \
                --transition-duration 1 \
                --transition-fps 165 2>/dev/null || true
        fi
    else
        # Apply: repoint current.jpg at the chosen still file (unchanged
        # pre-existing behaviour).
        ln -sfr "$theme_dir/$chosen" "$WALLPAPER_DIR/current.jpg" 2>/dev/null || true

        # Best-effort live preview — only when a graphical session is
        # present (same WAYLAND_DISPLAY/DBUS_SESSION_BUS_ADDRESS guard
        # shape as reload.sh's headless guard) and awww is on PATH. The
        # headless container gate must never hang here.
        if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && command -v awww >/dev/null 2>&1; then
            awww img "$theme_dir/$chosen" \
                --transition-type center \
                --transition-duration 1 \
                --transition-fps 165 2>/dev/null || true
        fi
    fi

    # Write-back: atomic temp-file + mv idiom (matches commit.sh's
    # current-theme write) — cosmetic, must never fail theme-apply.
    mkdir -p "$LAST_WALLPAPER_DIR" 2>/dev/null || true
    printf '%s\n' "$chosen" > "$last_used_file.tmp" 2>/dev/null \
        && mv "$last_used_file.tmp" "$last_used_file" 2>/dev/null || true

    return 0
}

# theme_engine_wallpaper_frame_repair <name>
# D-08's repair-on-missing guard — the hot-path cost is one cheap read plus
# one string test for the overwhelmingly common still-preset case. Called
# from theme-apply BEFORE theme_engine_generate (deliberate — see the call
# site comment in theme-apply naming generate.sh:54 as the reason): a wiped
# state directory must self-heal its frame and its current.jpg pointer
# before generate.sh resolves current.jpg as the Material You palette
# source, or a wipe would surface as a wrong palette and a dangling lock
# screen with no gate catching it.
#
# NEVER mutates last-wallpaper/<name> — clearing a dead entry stays
# theme_engine_wallpaper_autoset's job (D-13). This guard only ever
# (re)creates the frame and, on success, repoints current.jpg at it. Every
# step best-effort; returns 0 on every path, since theme-apply calls this
# under `set -euo pipefail`.
theme_engine_wallpaper_frame_repair() {
    local name="$1"
    local last_used_file="$LAST_WALLPAPER_DIR/$name"

    [[ -f "$last_used_file" ]] || return 0
    local recorded
    recorded=$(head -n1 "$last_used_file" 2>/dev/null || true)
    theme_engine_wallpaper_is_live_ref "$recorded" || return 0

    local theme_dir="$WALLPAPER_DIR/$name"
    [[ -f "$theme_dir/$recorded" ]] || return 0

    local frame
    frame="$(theme_engine_wallpaper_frame_path "$name" "$recorded")"
    [[ -s "$frame" ]] && return 0

    local offset
    offset="$(theme_engine_wallpaper_frame_offset "$name" "$recorded")"
    if theme_engine_wallpaper_extract_frame "$theme_dir/$recorded" "$frame" "$offset" && [[ -s "$frame" ]]; then
        # WR-01: only flip current.jpg's pointer here when $name is
        # ALREADY the active theme (a self-heal re-render of the theme
        # already in effect, e.g. a wiped wallpaper-frames directory) —
        # never for a switch TO $name, which has not committed yet.
        # Repointing unconditionally made "Desktop left unchanged" false
        # on a subsequent theme_engine_generate failure: current.jpg
        # would already point at the new theme's frame even though
        # theme-apply reported the switch failed. The frame itself is
        # still (re)extracted eagerly either way — self-heal of the file
        # on disk is unconditional — only the disk-visible current.jpg
        # symlink flip is scoped. A switch's own repoint happens later,
        # from theme_engine_wallpaper_autoset, and only after
        # theme_engine_generate has actually succeeded.
        local current_theme
        current_theme=$(cat "$HOME/.local/state/theme/current-theme" 2>/dev/null || true)
        if [[ "$name" == "$current_theme" ]]; then
            ln -sfr "$frame" "$WALLPAPER_DIR/current.jpg" 2>/dev/null || true
        fi
    fi

    return 0
}

# theme_engine_wallpaper_sync_owner <theme> [ref]
#
# D-21's SINGLE owner-declaration path. This is the ONLY function in the
# whole system that may invoke wallpaper-visibility.sh's `select`/`clear`
# verbs on behalf of a theme switch, a login, or a manual picker
# selection — login (theme-init.sh -> theme-apply), a theme switch
# (theme-apply) and a manual pick (wallpaper-picker.sh) all call THIS
# function and nothing else. Adding a second call site anywhere is
# EXACTLY what D-21 forbids: it re-opens the "login-only code path"
# failure class this decision exists to close. If this function's
# behaviour ever needs to change, it changes here once, for all three
# callers at once — never re-derive any part of it at a second site.
#
# Best-effort throughout (`|| true`, returns 0 on every path) — this
# whole concern is cosmetic to a theme-apply run under
# `set -euo pipefail` and must never change its exit code, exactly as
# every other step in this library already requires of itself.
theme_engine_wallpaper_sync_owner() {
    local name="$1" ref="${2-}"
    local have_ref=0
    [[ $# -ge 2 ]] && have_ref=1

    local owner="$HOME/.config/hypr/scripts/wallpaper-visibility.sh"
    # A headless container or a fresh machine before stow must never fail
    # here — return quietly rather than error.
    [[ -x "$owner" ]] || return 0

    # ── Reduced-motion intent FIRST, before any selection intent — a
    # selection made under reduced motion must never briefly start a
    # player and then immediately stop it. D-31 is a three-valued axis:
    # only the literal "off" suppresses; "reduced", "normal", "lively"
    # and a missing/unreadable file all show.
    local motion_scale
    motion_scale=$(cat "$HOME/.local/state/theme/motion-scale" 2>/dev/null || true)
    if [[ "$motion_scale" == "off" ]]; then
        "$owner" motion hide >/dev/null 2>&1 || true
    else
        "$owner" motion show >/dev/null 2>&1 || true
    fi

    # ── Selection: take ref from $2 when the caller supplied one
    # (including the empty string, meaning "a wallpaper outside this
    # theme, nothing to remember" — the picker's out-of-theme-pick case),
    # otherwise read the first line of the theme's own recorded choice.
    if [[ "$have_ref" -eq 0 ]]; then
        ref=$(head -n1 "$LAST_WALLPAPER_DIR/$name" 2>/dev/null || true)
    fi

    if [[ -n "$ref" ]] && theme_engine_wallpaper_is_live_ref "$ref" \
        && [[ -f "$WALLPAPER_DIR/$name/$ref" ]]; then
        "$owner" select "$WALLPAPER_DIR/$name/$ref" >/dev/null 2>&1 || true
    else
        "$owner" clear >/dev/null 2>&1 || true
    fi

    # ── Reassert — mirrors reload.sh's own post-signal
    # waybar-visibility.sh reassert call, so a theme switch can never
    # leave the owner's actuated state desynced from the newly selected
    # wallpaper.
    "$owner" reassert >/dev/null 2>&1 || true

    return 0
}
