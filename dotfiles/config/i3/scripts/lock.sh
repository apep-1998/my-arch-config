#!/bin/bash
IMAGE=$HOME/.config/i3/wallpapers/lock-screen.png

# Switch to English-only before locking so i3lock always accepts Latin input.
# us,ir keeps both layouts registered but the active group may still be Persian;
# setting only "us" removes that ambiguity entirely.
setxkbmap us

i3-msg -t send_tick "FORCE_US_LAYOUT_START"

i3lock -i "$IMAGE" -t

# Restore full layout (us + ir) after unlock so the normal toggle works again.
setxkbmap -layout us,ir -option grp:alt_shift_toggle
i3-msg -t send_tick "FORCE_US_LAYOUT_END"
