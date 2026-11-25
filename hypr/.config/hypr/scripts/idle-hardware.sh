#!/bin/sh
# Windows owns the physical display and sleep state in WSL.
if [ "$(systemd-detect-virt)" = wsl ]; then
    exit 0
fi

if [ "$1" = brightnessctl ]; then
    # External displays often expose no sysfs backlight. Let the rest of
    # the idle listener run and avoid targeting keyboard LEDs.
    for device in /sys/class/backlight/*; do
        if [ -e "$device" ]; then
            shift
            exec brightnessctl --class=backlight "$@"
        fi
    done
    exit 0
fi

exec "$@"
