#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        AI WORKSPACE — idempotent launcher (D-24)      ║
# ║  Switches to the reserved `name:ai` workspace,         ║
# ║  launching only what isn't already running there.      ║
# ╚══════════════════════════════════════════════════════╝
#
# Auto-launched subset (Claude's discretion): Claude Code (kitty CLI agent)
# and Local models (kitty aichat client). The four Zen AI web-app windows
# are deliberately NOT auto-launched by this entry — opening four browser
# windows on every pick would be heavy and is not what "switch to my AI
# workspace" implies. Picking Claude/ChatGPT/Gemini/Perplexity from the
# dashboard directly (ai-webapp-launch.sh) already lands those on this same
# `name:ai` workspace on their own.
#
# IDEMPOTENCY (D-24's literal requirement — picking this twice must yield
# ONE set of windows, not two): query hyprctl clients BEFORE launching
# anything. Only launch what's missing from the `name:ai` workspace. If the
# query itself fails (no hyprctl/jq), fail CLOSED — switch workspace and
# launch nothing, per the guarded hyprctl-plus-jq query idiom (query with
# `|| true` so a compositor-query failure launches nothing rather than
# risking a doubled window set) — an empty workspace is recoverable, a
# doubled one is not.
set -euo pipefail

CLAUDE_CODE_CLASS="ai-claude-code"
LOCAL_MODELS_CLASS="ai-local-models"

notify_fail() {
    notify-send -a "AI Workspace" "Launch Failed" "$1 did not start" -i dialog-error -t 4000 2>/dev/null || true
}

launch_claude_code() {
    uwsm app -- kitty --class "$CLAUDE_CODE_CLASS" --title "Claude Code" -- claude \
        || notify_fail "Claude Code"
}

launch_local_models() {
    ~/.config/hypr/scripts/ai-local-models.sh \
        || notify_fail "Local models"
}

if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    PRESENT=""
    PRESENT=$(hyprctl clients -j 2>/dev/null | \
        jq -r '[.[] | select(.workspace.name=="ai") | .class] | join(",")' 2>/dev/null) || true

    if [[ "$PRESENT" != *"$CLAUDE_CODE_CLASS"* ]]; then
        launch_claude_code
    fi
    if [[ "$PRESENT" != *"$LOCAL_MODELS_CLASS"* ]]; then
        launch_local_models
    fi
else
    : # Cannot determine compositor state — fail closed, launch nothing.
fi

# 13.1 Lua cutover: the legacy string form `hyprctl dispatch workspace
# name:ai` is textually wrapped into `return hl.dispatch(workspace name:ai)`
# and evaluated as Lua SOURCE, which is a parse error — this exec was
# silently dead (exit 7, and as the last command it also made the whole
# script exit non-zero). Lua's call sugar only permits f"str" / f{table},
# never `f name:ai`, so the payload cannot be rescued from the Lua side —
# the call site must be retargeted. Same fix pattern as 13.1-09's
# theme-engine/theme-stress-test. Verified live: switches to name:ai.
exec hyprctl dispatch 'hl.dsp.focus({workspace="name:ai"})'
