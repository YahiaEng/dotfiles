#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        AI DASHBOARD WEB-APP LAUNCHER (MENU-03)        ║
# ║  Places a Zen AI web-app window on the reserved       ║
# ║  `name:ai` workspace — see windowrules.lua for why     ║
# ║  this is NOT a windowrule (D-21).                      ║
# ╚══════════════════════════════════════════════════════╝
#
# WHY A SCRIPT, NOT A WINDOWRULE (verified live, 2026-07-13 — see the "AI
# Dashboard web-app windows" comment block in
# hypr/.config/hypr/config/windowrules.lua for the full finding):
#   - Zen gives every window the identical class "zen" regardless of URL.
#   - MOZ_APP_REMOTINGNAME does not change that on this build (RESEARCH
#     Assumption A1, closed: no effect).
#   - A title-regex windowrule ALSO cannot place these windows: Hyprland's
#     one-shot `workspace` rule fires at map-time using the window's title
#     at that instant, which is always the generic "Zen Browser" — the
#     real page title arrives only after the page loads, by which point
#     the rule has already run (and does not re-run on later title
#     changes, unlike continuous properties such as opacity/float).
#   - What DOES work: Hyprland spawns a new window on whichever workspace
#     is currently active. So this script switches to `name:ai` FIRST,
#     then launches — no windowrule involved.
set -euo pipefail

URL="${1:?usage: ai-webapp-launch.sh <url>}"

# 13.1 Lua cutover: the legacy string form `hyprctl dispatch workspace
# name:ai` is now a Lua parse error and silently no-ops (see
# hypridle.conf's header note for the full mechanism). That broke the
# "switch to name:ai FIRST, then launch" ordering this whole script
# depends on — the Zen window was landing on whatever workspace happened
# to be active. Verified live: switches to name:ai.
hyprctl dispatch 'hl.dsp.focus({workspace="name:ai"})' >/dev/null 2>&1 || true
exec uwsm app -- zen-browser --new-window "$URL"
