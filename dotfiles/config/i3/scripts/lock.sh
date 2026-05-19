#!/bin/bash
IMAGE=$HOME/.config/i3/wallpapers/lock-screen.png

# Force English synchronously BEFORE i3lock starts — no race condition.
# If this were only a tick, the async Python handler might not run in time.
setxkbmap -layout us,ir

# Also notify the event manager so it can restore the correct layout on unlock.
i3-msg -t send_tick "FORCE_US_LAYOUT_START"

i3lock -i "$IMAGE" -t

# Restore the focused window's layout after unlock.
i3-msg -t send_tick "FORCE_US_LAYOUT_END"
