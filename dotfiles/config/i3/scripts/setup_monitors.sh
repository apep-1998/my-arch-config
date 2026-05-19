#!/bin/bash
# Per-host monitor layout. Edit the case block for each machine.
# Called once at i3 startup.

case "$(hostname)" in
    jarvis)
        xrandr \
            --output DisplayPort-0 --mode 2560x1440 --pos 0x0    --primary \
            --output DisplayPort-1 --mode 2560x1440 --pos 2560x0 --right-of DisplayPort-0
        ;;
    *)
        # Laptop / fallback: try internal panel, leave externals to auto.
        xrandr --output eDP-1 --auto --primary 2>/dev/null || true
        ;;
esac
