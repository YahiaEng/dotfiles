#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              GAMING MODE TOGGLE (D-26/27/28)          ║
# ║  Runtime-only, reversible. NEVER writes a Hyprland     ║
# ║  config file — every compositor change goes through    ║
# ║  `hyprctl eval` (13.1-10 retarget; the Lua config       ║
# ║  manager rejects `hyprctl keyword` as a silent no-op —  ║
# ║  see WINDOWS.md #12 / deferred-items.md #1). The         ║
# ║  theme-engine OWNS the on-disk config files; a toggle    ║
# ║  that rewrote them would desync the pipeline (this is    ║
# ║  the single hardest constraint in this script — see      ║
# ║  07-07-PLAN.md D-26).                                    ║
# ╚══════════════════════════════════════════════════════╝
#
# 17-03 correction (Task 2, D-28 flagged-assumption resolution): this file
# is NOT silently dead as 17-CONTEXT.md's deferred section speculated —
# lines below already use `hyprctl eval` with `hl.config({...})`, migrated
# and live-verified by 13.1-10. Only THIS header comment still claimed the
# pre-migration form; corrected here so a fourth reader does not repeat
# the same stale-comment-driven "possibly silently dead" conclusion.
#
# State file: ~/.cache/gaming-mode ("on"/"off"), stow-seeded to "off" and
# unconditionally reset to "off" on every session start (D-28,
# autostart.conf) — a stale ON state means the screen never locks.
#
# FINDING (documented, not a bug; re-stated 13.1-09 against the merged Lua
# token file, same substance as before the migration): D-26's OFF-path
# instruction is to read the pre-toggle decoration/animation values back
# from the theme engine's rendered state before falling back to `hyprctl
# reload`. The rendered state this script now reads,
# `~/.local/state/theme/hyprland-tokens.lua`, contains ONLY a `colors`
# table (the Material You palette) and a `motion` table (curve/speed
# tokens) — rounding/blur/animations-enabled/shadow-enabled are static
# values in the repo-owned hypr/.config/hypr/hyprland.lua and
# config/animations.lua, which theme-apply never touches, exactly as
# before this migration. The read-back below is therefore still expected
# to find nothing on THIS repo's layout (no `decoration:*`/`animations:*`
# key exists anywhere in the merged token table), and always falls
# through to `hyprctl reload` — which is exactly the plan's own
# designated fallback and is provably correct here, since `hyprctl
# reload` re-sources the exact same static config every time (the values
# never vary by theme).

set -euo pipefail

STATE_FILE="$HOME/.cache/gaming-mode"
THEME_TOKENS_LUA="$HOME/.local/state/theme/hyprland-tokens.lua"
CONTRACT_LIB="$HOME/.config/theme-engine/lib/contract.sh"
# shellcheck source=/dev/null
[[ -r "$CONTRACT_LIB" ]] && source "$CONTRACT_LIB"

# ── Re-pointed waybar-visibility call (D-03 / P7 D-26). ─────────────────
# This IS the re-point Phase 7 left this thin one-liner for -- waybar
# visibility is now owned exclusively by waybar-visibility.sh (the D-03
# owner). This script must never signal waybar directly again (no raw
# pkill -SIGUSR1/-SIGUSR2 waybar anywhere below). It declares an intent
# ("gaming wants it hidden/shown"); the owner computes the resulting
# state against the other actors (idle, fullscreen, keybind).
_gaming_waybar_toggle() {
    local state="$1" # hide|show
    ~/.config/hypr/scripts/waybar-visibility.sh gaming "$state" 2>/dev/null || true
}

# ── D-28: identical shape for the live-wallpaper owner. Declares an
# intent ("gaming wants it hidden/shown"); wallpaper-visibility.sh (the
# D-14 owner) computes the resulting state against the other actors
# (idle, motion). This script must never start/stop mpvpaper directly.
_gaming_wallpaper_toggle() {
    local state="$1" # hide|show
    ~/.config/hypr/scripts/wallpaper-visibility.sh gaming "$state" 2>/dev/null || true
}

# theme_engine-style atomic state write (commit.sh's temp-file + mv idiom)
# — the menu entry reads this file while this script writes it, so a torn
# read is a real possibility.
_write_state() {
    local value="$1"
    printf '%s\n' "$value" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
}

_read_state() {
    cat "$STATE_FILE" 2>/dev/null || echo "off"
}

# _restore_keyword <hyprctl-path> — best-effort read-back from the theme
# engine's rendered state (D-26: never hardcode restore literals). Prints
# the value if found, prints nothing otherwise (caller falls back to a
# full `hyprctl reload`, see FINDING above).
#
# 13.1-09: reads the merged Lua token table (hyprland-tokens.lua) through
# lib/contract.sh's `lua-table` value extractor (contract_extract_values,
# 13.1-05) rather than hand-rolling a second reader for this format —
# T-13.1-28: keeping one implementation of "how to read this format"
# instead of three (contract.sh, theme-doctor, theme-parity already share
# it; this file joining them means no fourth, divergent parser). The
# extractor emits dot-joined key paths ("colors.primary",
# "motion.speed.standard", ...) — this file's own $key argument is a
# colon-joined key path in the pre-13.1 `hyprctl keyword` shape
# ("decoration:blur:enabled"), which never matches any key in the
# colors/motion namespace (see FINDING
# above) — same "always empty, always falls through" outcome as before
# this retarget, now via the shared extractor instead of a hyprlang-
# specific grep.
_restore_keyword() {
    local key="$1"

    declare -F contract_extract_values >/dev/null 2>&1 || return 0
    [[ -f "$THEME_TOKENS_LUA" ]] || return 0

    local k v
    while IFS=$'\t' read -r k v; do
        if [[ "$k" == "$key" ]]; then
            printf '%s' "$v"
            return 0
        fi
    done < <(contract_extract_values "hyprland-tokens.lua" "$THEME_TOKENS_LUA" 2>/dev/null)
    return 0
}

gaming_mode_on() {
    # ── Runtime-only eye-candy disable (D-26) — every call is best-effort
    #    per the house `2>/dev/null || true` idiom (theme-engine/lib/gtk.sh).
    #
    # 13.1-10 (WINDOWS.md row 12 / deferred-items.md item 1): `hyprctl
    # keyword` is a silent no-op under the Lua config manager on this
    # installed Hyprland (prints "keyword can't work with non-legacy
    # parsers. Use eval." and still exits 0, so the `|| true` guard never
    # even fires). Retargeted to `hyprctl eval` with the `hl.config({...})`
    # expression the compositor's own error message names — proven live
    # against this exact session: each of the four calls below was run,
    # confirmed via `hyprctl -j getoption` to actually flip the reported
    # value, then reverted, before this fix was committed.
    hyprctl eval 'hl.config({ decoration = { blur = { enabled = false } } })' 2>/dev/null || true
    hyprctl eval 'hl.config({ animations = { enabled = false } })' 2>/dev/null || true
    hyprctl eval 'hl.config({ decoration = { shadow = { enabled = false } } })' 2>/dev/null || true
    hyprctl eval 'hl.config({ decoration = { rounding = 0 } })' 2>/dev/null || true

    # ── Idle/lock inhibit: pause hypridle rather than acquire a systemd
    #    inhibitor lock that could outlive this shell. SIGSTOP/SIGCONT is
    #    cleanly reversible and self-heals on session restart (a fresh
    #    session's exec-once spawns a brand-new hypridle process, D-28).
    pkill -STOP -x hypridle 2>/dev/null || true

    # ── Hide waybar: declare the gaming intent to the visibility owner.
    _gaming_waybar_toggle hide

    # ── Stop the live wallpaper: declare the gaming intent to ITS
    #    visibility owner (D-28). Mirrors the waybar call above exactly.
    _gaming_wallpaper_toggle hide

    _write_state "on"

    notify-send -a "Gaming Mode" "Gaming Mode: ON" "Eye-candy disabled, idle-lock inhibited" -i input-gaming -t 2500 2>/dev/null || true
}

gaming_mode_off() {
    # ── Restore eye-candy: attempt a read-back from the theme engine's
    #    rendered state first (D-26); fall back to a full `hyprctl reload`
    #    (re-sources the compositor's whole on-disk config) for any value
    #    that isn't present there. On this repo's layout, none of these
    #    four keys are ever in the merged hyprland-tokens.lua table (see
    #    FINDING above), so this always exercises the reload fallback —
    #    which is the plan's own designed, guaranteed-correct path.
    # 13.1-10: the four `hyprctl keyword <key> "$v"` restore calls below are
    # retargeted to `hyprctl eval "hl.config({...})"`, same as the ON path.
    # NOTE on the getoption type-key divergence (COVERAGE.md, 13.1-03/13.1-05):
    # that divergence is specific to `hyprctl -j getoption`'s JSON field-name
    # ("int" vs "bool") and does NOT apply here — `$v` is never sourced from
    # `hyprctl getoption` anywhere in this script. It comes from
    # `_restore_keyword` reading `~/.local/state/theme/hyprland-tokens.lua`
    # through `contract_extract_values`'s lua-table extractor, which
    # `tostring()`s a Lua boolean leaf to the literal "true"/"false" (see
    # lib/contract.sh's lua-table value arm) — a value already shaped as a
    # valid Lua literal, safe to splice directly into `hl.config({... = $v})`.
    # Checked and confirmed not a live bug: per this file's own FINDING
    # comment above, none of these four keys exist in the merged token
    # table on this repo's layout, so `$v` is always empty and every one of
    # these four branches is still provably dead code — `need_reload` is
    # always 1 and the fallback below is what actually restores state.
    # Fixed anyway (Rule 1: broken syntax on an unreachable-but-real code
    # path is still a bug) so this stays correct if a future token ever
    # populates one of these keys.
    local need_reload=0
    local v

    v="$(_restore_keyword decoration:blur:enabled)"
    if [[ -n "$v" ]]; then
        hyprctl eval "hl.config({ decoration = { blur = { enabled = $v } } })" 2>/dev/null || true
    else
        need_reload=1
    fi

    v="$(_restore_keyword animations:enabled)"
    if [[ -n "$v" ]]; then
        hyprctl eval "hl.config({ animations = { enabled = $v } })" 2>/dev/null || true
    else
        need_reload=1
    fi

    v="$(_restore_keyword decoration:shadow:enabled)"
    if [[ -n "$v" ]]; then
        hyprctl eval "hl.config({ decoration = { shadow = { enabled = $v } } })" 2>/dev/null || true
    else
        need_reload=1
    fi

    v="$(_restore_keyword decoration:rounding)"
    if [[ -n "$v" ]]; then
        hyprctl eval "hl.config({ decoration = { rounding = $v } })" 2>/dev/null || true
    else
        need_reload=1
    fi

    if [[ "$need_reload" == "1" ]]; then
        hyprctl reload 2>/dev/null || true
    fi

    # ── Un-inhibit idle/lock.
    pkill -CONT -x hypridle 2>/dev/null || true

    # ── Un-hide waybar: declare the gaming intent cleared.
    _gaming_waybar_toggle show

    # ── Restore the live wallpaper: declare the gaming intent cleared on
    #    ITS visibility owner too (D-28). Mirrors the waybar call above.
    _gaming_wallpaper_toggle show

    # ── Stale-idle fix (D-05 SIGSTOP interaction). gaming_mode_on()
    #    freezes hypridle (pkill -STOP above), so an idle-hide/dim intent
    #    that was already in effect when gaming mode engaged can never be
    #    cleared by hypridle's own on-resume -- that process cannot run
    #    while stopped. During gaming this is harmless (the gaming=hide
    #    intent dominates under D-01's OR-union regardless), but declaring
    #    ONLY "gaming show" here would leave that stale idle=hide intent
    #    standing, and the bar would return dimmed instead of normal.
    #    Toggling gaming mode off IS user input -- by D-02's own rule any
    #    input clears idle-hide -- so this is gaming-mode correctly
    #    reporting that input occurred, not reaching into another actor's
    #    concern. Do NOT remove this second call as "redundant": without
    #    it, gaming-mode-OFF can return a dimmed bar.
    ~/.config/hypr/scripts/waybar-visibility.sh idle show 2>/dev/null || true

    # ── Same stale-idle fix, applied to the live wallpaper (D-28/17-03
    #    Task 2e). gaming_mode_on()'s pkill -STOP -x hypridle above can
    #    strand an idle=hide intent this owner declared before hypridle
    #    was frozen — hypridle's own on-resume can never run to clear it
    #    while stopped. Without this second call, turning gaming mode OFF
    #    returns a STOPPED wallpaper (17-01/17-02 already proved this
    #    exact shape for waybar; the wallpaper owner needs the identical
    #    second call or the fix is only half-applied).
    ~/.config/hypr/scripts/wallpaper-visibility.sh idle show 2>/dev/null || true

    _write_state "off"

    notify-send -a "Gaming Mode" "Gaming Mode: OFF" "Desktop restored to theme defaults" -i input-gaming -t 2500 2>/dev/null || true
}

main() {
    local arg="${1:-}"

    if [[ "$arg" == "status" ]]; then
        _read_state
        exit 0
    fi

    local current
    current="$(_read_state)"

    if [[ "$current" == "on" ]]; then
        gaming_mode_off
    else
        gaming_mode_on
    fi
}

main "$@"
