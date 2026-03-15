#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║          VSCODIUM THEME APPLIER                       ║
# ║  Merges theme colorTheme + colorCustomizations        ║
# ║  into VSCodium's settings.json via jq                 ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

THEME_NAME="${1:-catppuccin}"
SETTINGS="$HOME/.config/VSCodium/User/settings.json"
THEMES_DIR="$HOME/.config/themes/vscodium"
MATUGEN_CACHE="$HOME/.cache/matugen-vscodium.json"

# Ensure settings.json exists
mkdir -p "$(dirname "$SETTINGS")"
[[ ! -f "$SETTINGS" ]] && echo '{}' > "$SETTINGS"

if [[ "$THEME_NAME" == "materialyou" ]]; then
    # Material You: matugen already generated the JSON with theme + colorCustomizations
    if [[ -f "$MATUGEN_CACHE" ]]; then
        THEME_DATA="$MATUGEN_CACHE"
    else
        exit 0
    fi
else
    # Static theme: use the per-theme JSON
    THEME_DATA="$THEMES_DIR/${THEME_NAME}.json"
    if [[ ! -f "$THEME_DATA" ]]; then
        echo "Theme file not found: $THEME_DATA"
        exit 1
    fi
fi

# Merge theme data into settings.json
# This preserves all user settings and only overwrites colorTheme + colorCustomizations
jq -s '.[0] * .[1]' "$SETTINGS" "$THEME_DATA" > "${SETTINGS}.tmp" \
    && mv "${SETTINGS}.tmp" "$SETTINGS"
