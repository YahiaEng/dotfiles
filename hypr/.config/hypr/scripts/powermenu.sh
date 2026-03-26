#!/usr/bin/env bash
# Power menu with walker

OPTIONS="🔒 Lock
🚪 Logout
🔄 Reboot
⏻  Shutdown
💤 Suspend"

SELECTED=$(echo "$OPTIONS" | walker --dmenu --placeholder "Power Menu")

[[ -z "$SELECTED" ]] && exit 0

case "$SELECTED" in
    *"Lock"*)     uwsm app -- hyprlock       ;;
    *"Logout"*)   uwsm stop                  ;;
    *"Reboot"*)   systemctl reboot           ;;
    *"Shutdown"*) systemctl poweroff         ;;
    *"Suspend"*)  systemctl suspend          ;;
esac
