#!/bin/bash
# Run ~/.screenlayout/default.sh if it exists (created by arandr).
# Fall back to activating whatever display is connected.

if [ -f "$HOME/.screenlayout/default.sh" ]; then
    bash "$HOME/.screenlayout/default.sh"
else
    xrandr --auto
fi
