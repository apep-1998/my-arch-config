#!/bin/bash
# Screenshot helper. Captures screen to a file AND copies to clipboard.
#
# Usage: screenshot.sh [full|window|select]
#   full    full screen (default)
#   window  currently focused window
#   select  drag a region with the mouse
#
# Requires: maim, xclip, xdotool (only for window mode), libnotify (optional)

set -euo pipefail

MODE="${1:-full}"
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +%Y-%m-%d_%H-%M-%S)_${MODE}.png"

case "$MODE" in
    full)
        maim "$FILE"
        ;;
    window)
        maim -i "$(xdotool getactivewindow)" "$FILE"
        ;;
    select)
        maim -s "$FILE"
        ;;
    *)
        echo "Usage: $0 [full|window|select]" >&2
        exit 2
        ;;
esac

xclip -selection clipboard -t image/png -i "$FILE"

if command -v notify-send >/dev/null 2>&1; then
    notify-send -i "$FILE" "Screenshot saved" "$FILE"
fi
