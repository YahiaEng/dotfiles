#!/bin/zsh

# This is an auto reload script for waybar

# kill waybar if it is already running
killall -9 waybar

# Relaunch waybar in the background
waybar &
