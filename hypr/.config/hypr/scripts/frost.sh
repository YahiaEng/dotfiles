#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════╗
# ║                  FROST OWNER (layer-rule re-applier)      ║
# ║  Owns the frosted-glass backdrop on the quickshell layer  ║
# ║  surfaces: the blur layer rules declared in               ║
# ║  config/windowrules.lua, plus a user on/off preference.   ║
# ║                                                           ║
# ║  MEASURED 2026-08-25 on Hyprland 0.56.2, correcting an     ║
# ║  older belief this script was first written on:            ║
# ║    * `hyprctl reload` does NOT drop layer rules. Verified  ║
# ║      by screenshot: a blurred dashboard stayed blurred     ║
# ║      across a plain reload. windowrules.lua's ⚠ block      ║
# ║      (~line 454) says EDITS do not take effect on reload,  ║
# ║      which is a narrower claim than "rules are dropped" —  ║
# ║      do not read it as the latter.                         ║
# ║    * Because reload re-executes the config, it re-asserts  ║
# ║      blur = true and would silently override a user who    ║
# ║      has turned frost OFF. Re-asserting the preference is  ║
# ║      the real reason lib/reload.sh calls `apply` — not     ║
# ║      repairing a drop.                                     ║
# ║    * `apply` DOES recover a surface stuck unblurred:       ║
# ║      verified by forcing blur=false on the open dashboard  ║
# ║      (text behind it became sharp) and then running it     ║
# ║      (text became blurred again).                          ║
# ║                                                           ║
# ║  SINGLE SOURCE OF TRUTH: the rules are NOT duplicated      ║
# ║  here. They are read back out of windowrules.lua in FILE   ║
# ║  ORDER and re-evaluated verbatim, because order is         ║
# ║  load-bearing — a per-surface rule must land AFTER the     ║
# ║  `^quickshell-.*` family rule it refines, or the family    ║
# ║  value wins and the surface reads as raw transparency.     ║
# ╚══════════════════════════════════════════════════════════╝
#
# Usage:
#   frost.sh apply     re-apply every layer rule, honouring the stored
#                      preference (this is what reload.sh calls)
#   frost.sh on        turn frost on  and apply
#   frost.sh off       turn frost off and apply
#   frost.sh toggle    flip and apply
#   frost.sh --get     print "on" or "off"
#   frost.sh --list    print the two values, for a non-interactive picker
#
# NOTE: deliberately no `set -e`. A single rejected eval must never abort
# the remaining rules and leave the session half-frosted — each one is
# applied best-effort and counted, and the summary reports failures.
set -uo pipefail

STATE_DIR="$HOME/.local/state/hypr"
FROST_STATE="$STATE_DIR/frost"
RULES_FILE="$HOME/.config/hypr/config/windowrules.lua"

# ── preference ────────────────────────────────────────────────
frost_get() {
    local v=""
    [[ -r "$FROST_STATE" ]] && v="$(tr -d '[:space:]' < "$FROST_STATE" 2>/dev/null)"
    case "$v" in
        on|off) printf '%s\n' "$v" ;;
        # Default ON: frost is what the shipped windowrules.lua declares, so
        # a machine with no state file must look like the config says.
        *)      printf 'on\n' ;;
    esac
}

frost_set() {
    mkdir -p "$STATE_DIR" 2>/dev/null || true
    printf '%s\n' "$1" > "$FROST_STATE"
}

# ── the rules, read back from the config that declares them ───
# Every `hl.layer_rule({ ... })` one-liner, in file order. Comment lines are
# excluded by requiring the call at the start of the line — windowrules.lua
# discusses these rules in prose extensively, and a grep that matched its own
# commentary would re-apply garbage.
frost_rules() {
    [[ -r "$RULES_FILE" ]] || return 1
    grep -E '^hl\.layer_rule\(\{.*\}\)$' "$RULES_FILE"
}

# Namespaces the config asks to blur — derived from the same lines, so a
# namespace added to windowrules.lua is picked up here with no second edit.
frost_blur_namespaces() {
    frost_rules \
        | grep -F 'blur = true' \
        | sed -nE 's/.*namespace = "([^"]+)".*/\1/p'
}

frost_apply() {
    local want; want="$(frost_get)"
    local rules applied=0 failed=0

    rules="$(frost_rules)" || {
        echo "frost.sh: cannot read $RULES_FILE — no rules applied" >&2
        return 1
    }
    if [[ -z "$rules" ]]; then
        echo "frost.sh: no hl.layer_rule lines found in $RULES_FILE — refusing to continue" >&2
        return 1
    fi

    # 1. Replay every declared rule, in file order. This restores the
    #    animation and ignore_alpha rules too, not just blur — `hyprctl
    #    reload` drops all of them alike, so re-applying only the blur ones
    #    would leave the drawers with their slide/fade entrances missing.
    while IFS= read -r rule; do
        [[ -n "$rule" ]] || continue
        if hyprctl eval "$rule" >/dev/null 2>&1; then
            applied=$((applied + 1))
        else
            failed=$((failed + 1))
            echo "frost.sh: eval rejected: $rule" >&2
        fi
    done <<< "$rules"

    # 2. If frost is OFF, switch blur back off for exactly the namespaces
    #    step 1 just turned it on for. Done as a second pass rather than by
    #    filtering step 1 so that ignore_alpha and the entrance animations
    #    stay intact — turning frost off must change the BLUR only, never
    #    how a drawer enters.
    if [[ "$want" == "off" ]]; then
        local ns
        while IFS= read -r ns; do
            [[ -n "$ns" ]] || continue
            hyprctl eval "hl.layer_rule({ match = { namespace = \"$ns\" }, blur = false })" \
                >/dev/null 2>&1 || true
        done <<< "$(frost_blur_namespaces)"
    fi

    echo "frost.sh: frost=$want, ${applied} layer rule(s) re-applied, ${failed} rejected"
    [[ "$failed" -eq 0 ]]
}

case "${1-}" in
    apply)      frost_apply ;;
    on)         frost_set on;  frost_apply ;;
    off)        frost_set off; frost_apply ;;
    toggle)     if [[ "$(frost_get)" == "on" ]]; then frost_set off; else frost_set on; fi
                frost_apply ;;
    --get|get)  frost_get ;;
    --list)     printf 'on\noff\n' ;;
    *)
        echo "Usage: frost.sh <apply|on|off|toggle|--get|--list>" >&2
        exit 1
        ;;
esac
