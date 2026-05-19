#!/bin/bash

declare -r LAYOUT=$(setxkbmap -query | grep layout | cut -d' ' -f6| cut -d',' -f1)

if [[ LAYOUT != "us" ]]; then
    ~/.config/i3/scripts/change_keyboard_layout.sh us
fi

rofi -show combi -combi-modi 'window,drun' -columns 1 -modi 'combi,run'

if [[ LAYOUT != "us" ]]; then
    ~/.config/i3/scripts/change_keyboard_layout.sh "$LAYOUT"
fi

