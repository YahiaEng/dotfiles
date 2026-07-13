#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        AI DASHBOARD — LOCAL MODELS (MENU-03, D-22)    ║
# ║  Shared by ai-dashboard.toml's "Local models" entry    ║
# ║  and ai-workspace.sh, so the ollama/aichat/no-model    ║
# ║  checks and the aichat config seed live in ONE place.  ║
# ╚══════════════════════════════════════════════════════╝
#
# D-22: local models stop at ollama + a TUI client (aichat, official repo).
# D-23: install.sh never auto-pulls a model. If ollama has none installed,
# surface the UI-SPEC's locked informational copy instead of dropping the
# user into an unusable TUI.
#
# NOTE (unverified against the installed binary — ollama/aichat are NOT
# installed on this dev machine as of 2026-07-13, confirmed via `which`;
# 07-03 wired install.sh but did not install onto this box): the `ollama
# list` output-parsing below and aichat's `clients:`/`api_base` config
# schema follow ollama's and aichat's documented CLI/config conventions but
# could not be live-verified here (the project's own "verify against the
# installed binary" standard, unmet for this one item — flagged explicitly
# rather than asserted as fact). The human checkpoint's optional step 5
# (`ollama pull llama3.2` then re-pick Local models) is the live check.
set -euo pipefail

notify_info() {
    notify-send -a "Local Models" "$1" "$2" -i dialog-information -t 4000 2>/dev/null || true
}

if ! command -v ollama >/dev/null 2>&1; then
    notify_info "Ollama Not Installed" "Install it first (declared in install.sh, D-33): pacman -S ollama"
    exit 0
fi

if ! command -v aichat >/dev/null 2>&1; then
    notify_info "aichat Not Installed" "Install it first (declared in install.sh, D-33): pacman -S aichat"
    exit 0
fi

# D-23: never pull a model automatically. Missing daemon and missing model
# both surface the same informational copy — either way the TUI cannot
# usefully answer, and "ollama pull <model>" is the correct next step for
# both (pulling also starts the daemon on first use).
MODEL_ROWS=""
if OLLAMA_LIST=$(ollama list 2>/dev/null); then
    MODEL_ROWS=$(printf '%s\n' "$OLLAMA_LIST" | awk 'NR>1 && NF')
fi
if [[ -z "$MODEL_ROWS" ]]; then
    notify_info "No Model Installed" "Run: ollama pull <model>"
    exit 0
fi

# D-22: aichat reaches ollama via its OpenAI-compatible endpoint. Seeded
# once, idempotently — created only if absent, never overwritten (a user's
# own aichat config, e.g. for other providers, must survive re-picks).
#
# The schema below is live-verified against aichat 0.30.0 + ollama 0.31.2
# (07-07 closeout). Two things that are NOT obvious and were originally
# wrong here, both proven by running the binary rather than reading docs:
#
#   1. `model:` must be a fully-qualified `<client>:<model>` reference. The
#      bare client name (`model: ollama`) makes aichat exit with
#      "Error: Unknown chat model 'ollama'" — i.e. the menu entry would open
#      a kitty window with a dead TUI, the exact D-22/D-23 failure mode.
#   2. An `openai-compatible` client does NOT auto-discover models from the
#      endpoint — the `models:` list must be declared explicitly, or aichat
#      resolves no model at all.
#
# The ollama tag is STRIPPED (`llama3.2:latest` -> `llama3.2`): aichat splits
# its `<client>:<model>` reference on the colon and cannot parse a model name
# that itself contains one — `model: ollama:llama3.2:latest` drops aichat into
# its interactive first-run wizard and hangs forever (verified both quoted and
# unquoted). Consequence: a model pulled under an explicit non-default tag
# (e.g. `qwen2.5:7b`) is not addressable through this seed. That is a known,
# accepted limitation — edit config.yaml by hand; this script never overwrites
# an existing one.
FIRST_MODEL=$(printf '%s\n' "$MODEL_ROWS" | awk 'NR==1 {print $1}' | cut -d: -f1)

AICHAT_CONFIG_DIR="$HOME/.config/aichat"
AICHAT_CONFIG="$AICHAT_CONFIG_DIR/config.yaml"
if [[ ! -f "$AICHAT_CONFIG" ]]; then
    mkdir -p "$AICHAT_CONFIG_DIR"
    cat > "$AICHAT_CONFIG" <<EOF
# Seeded by ai-local-models.sh (D-22, plan 07-06) — points aichat at
# ollama's local OpenAI-compatible endpoint. Edit freely; this file is only
# ever created if it does not already exist, never overwritten.
model: ollama:$FIRST_MODEL
clients:
  - type: openai-compatible
    name: ollama
    api_base: http://localhost:11434/v1
    models:
      - name: $FIRST_MODEL
EOF
fi

exec uwsm app -- kitty --class "ai-local-models" --title "Local Models" -- aichat
