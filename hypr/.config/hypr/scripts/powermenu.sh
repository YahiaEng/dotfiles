#!/usr/bin/env bash
# Power menu with wofi

OPTIONS="🔒 Lock
🚪 Logout
🔄 Reboot
⏻  Shutdown
💤 Suspend"

SELECTED=$(echo "$OPTIONS" | wofi --dmenu \
    --prompt "Power Menu" \
    --width 300 \
    --height 260 \
    --cache-file /dev/null)

[[ -z "$SELECTED" ]] && exit 0

case "$SELECTED" in
    *"Lock"*)     uwsm app -- hyprlock       ;;
    *"Logout"*)   uwsm stop                  ;;
    *"Reboot"*)   systemctl reboot           ;;
    *"Shutdown"*) systemctl poweroff         ;;
    *"Suspend"*)  systemctl suspend          ;;
esac
