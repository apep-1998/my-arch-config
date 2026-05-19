#!/bin/bash


IMAGE=$HOME/.config/i3/wallpapers/lock-screen.png

i3-msg -t send_tick "FORCE_US_LAYOUT_START"

i3lock -i $HOME/.config/i3/wallpapers/lock-screen.png -t

i3-msg -t send_tick "FORCE_US_LAYOUT_END"
