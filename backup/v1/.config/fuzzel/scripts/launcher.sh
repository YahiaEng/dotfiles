#!/usr/bin/env bash

CURRENT_THEME="cattpuccin"
MENUE_COMMAND="fuzzel --dmenu --prompt='󰸉 >' --width=30"
THEME_PICKER_SCRIPT=$HOME/.config/fuzzel/scripts/theme-picker.sh
KEYBIND_SCRIPT=""
WALLPAPER_PICKER_SCRIPT=$HOME/.config/fuzzel/scripts/wallpaper-picker2.sh

function menue_builder(){
    printf "Apps\n"
    printf "Keybinds\n"
    printf "Theme\n"
    printf "Wallpaper\n"
}

function main() {
    option=$(menu | ${MENUE_COMMAND})

    # no option
    if [[ -z $option ]]; then return; fi

    menue_index=$(echo $option | cut -d. -f1)

    case $option in
    1)
        fuzzel
        return
        ;;
    2)
        ${KEYBIND_SCRIPT}
        return
        ;;
    3)
        ${THEME_PICKER_SCRIPT}
        return
        ;;
    4)
        ${WALLPAPER_PICKER_SCRIPT}
        return
        ;;
    esac
}

# Check if fuzzel is already running
if pidof fuzzel >/dev/null; then
    killall fuzzel
    exit 0
else
    main
fi