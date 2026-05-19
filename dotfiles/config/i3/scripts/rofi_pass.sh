#!/bin/bash
sh -c 'eval `xdotool getactivewindow getwindowgeometry --shell`; xdotool mousemove $((X+WIDTH/2)) $((Y+HEIGHT/2))'

i3-msg -t send_tick "FORCE_US_LAYOUT_START"

rofi-pass

i3-msg -t send_tick "FORCE_US_LAYOUT_END"
