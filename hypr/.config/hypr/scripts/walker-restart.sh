#!/usr/bin/env bash
# Rebuild Walker style.css from colors + base, then restart service

# Concatenate colors into style.css (no @import — inline colors)
cat "$HOME/.config/walker/themes/rice/colors.css" \
    "$HOME/.config/walker/themes/rice/style-base.css" \
    > "$HOME/.config/walker/themes/rice/style.css" 2>/dev/null

# Restart Walker service
pkill walker 2>/dev/null
sleep 0.3
uwsm app -- walker --gapplication-service &
