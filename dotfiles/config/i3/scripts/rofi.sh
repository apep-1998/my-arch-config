#!/bin/bash

i3-msg -t send_tick "FORCE_US_LAYOUT_START"

rofi -show combi -combi-modi 'window,drun' -columns 1 -modi 'combi,run'

i3-msg -t send_tick "FORCE_US_LAYOUT_END"
