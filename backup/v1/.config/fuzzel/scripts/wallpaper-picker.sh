#!/bin/bash

# wallpaper directories
DIR=$HOME/Pictures/wallpapers
PICS=($(ls ${DIR}))
RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}
# fuzzel config
WIDTH=30
fuzzel_command="fuzzel --dmenu --prompt='󰸉 >' --width=$WIDTH"
# Transition config (see 'swww img --help' for more settings)
FPS=60
TYPE="simple"
DURATION=3
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

if [[ $(pidof swaybg) ]]; then
  pkill swaybg
fi

menu(){
printf "1. cityscape\n" 
printf "2. cityscape2\n" 
printf "3. colorful-snow\n" 
printf "4. Hong-Kong\n" 
printf "5. Into-the-night\n"
printf "6. lain\n"
printf "7. lonely-night\n"
printf "8. neon\n"
printf "9. old\n"
printf "10. random"
}

swww query || swww-daemon

main() {
choice=$(menu | ${fuzzel_command} | cut -d. -f1)
case $choice in
1)
    swww img ${DIR}/cityscape.jpg $SWWW_PARAMS
    return
    ;;
2)
    swww img ${DIR}/cityscape2.jpg $SWWW_PARAMS
    return
    ;;
3)
    swww img ${DIR}/colorful-snow.jpg $SWWW_PARAMS
    return
    ;;
4)
    swww img ${DIR}/hong-kong.jpg $SWWW_PARAMS
    return
    ;;
5)
    swww img ${DIR}/into-the-night.jpg $SWWW_PARAMS
    return
    ;;
6)
    swww img ${DIR}/lain.jpg $SWWW_PARAMS
    return
    ;;
7)
    swww img ${DIR}/lonely-night.jpg $SWWW_PARAMS
    return
    ;;
8)
    swww img ${DIR}/neon.jpg $SWWW_PARAMS
    return
    ;;
9)
    swww img ${DIR}/old.png $SWWW_PARAMS
    return
    ;;
10)
    swww img ${DIR}/${RANDOMPICS} $SWWW_PARAMS
    return
    ;;
esac
}

killall -f || main