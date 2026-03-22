#!/usr/bin/env bash
# Toggle wlogout — kill if running, launch if not

if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
else
    wlogout --protocol layer-shell -b 6 -T 400 -B 400 &
fi
