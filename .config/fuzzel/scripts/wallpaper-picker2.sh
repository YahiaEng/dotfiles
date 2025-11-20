#!/bin/bash

# wallpaper directories
DIR=$HOME/Pictures/wallpapers
PICS=($(ls ${DIR} | grep -e ".jpg$" -e ".jpeg$" -e ".png$" -e ".gif$"))
RANDOM_PIC=${PICS[ $RANDOM % ${#PICS[@]} ]}
RANDOM_PIC_NAME="${#PICS[@]}. random"
# fuzzel config
WIDTH=30
fuzzel_command="fuzzel --dmenu --prompt="󰸉 >" --width=$WIDTH"
# Transition config (see 'swww img --help' for more settings)
FPS=60
TYPE="simple"
DURATION=3
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"


# check if swaybg is running
if [[ $(pidof swaybg) ]]; then
  pkill swaybg
fi

menu(){
    # Here we are looping in the PICS array that is composed of all images in the $DIR
    # folder 
    for i in ${!PICS[@]}; do
        # keeping the .gif to make sue you know it is animated
        if [[ -z $(echo ${PICS[$i]} | grep .gif$) ]]; then
            printf "$i. $(echo ${PICS[$i]} | cut -d. -f1)\n" # n°. <name_of_file_without_identifier>
        else
            printf "$i. ${PICS[$i]}\n"
        fi
    done

    printf "$RANDOM_PIC_NAME"
}

swww query || swww-daemon

main() {
    choice=$(menu | ${fuzzel_command})

    # no choice case
    if [[ -z $choice ]]; then return; fi

    # random choice case
    if [ "$choice" = "$RANDOM_PIC_NAME" ]; then
        swww img ${DIR}/${RANDOM_PIC} $SWWW_PARAMS
        return
    fi
    
    pic_index=$(echo $choice | cut -d. -f1)
    swww img ${DIR}/${PICS[$pic_index]} $SWWW_PARAMS
}

# Check if fuzzel is already running
if pidof fuzzel >/dev/null; then
    killall fuzzel
    exit 0
else
    main
fi

# Uncomment to launch something if a choice was made 
# if [[ -n "$choice" ]]; then
    # Restart Waybar
# fi