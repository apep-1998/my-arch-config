#!/bin/bash
# Lock and log files are per-user so multi-user/switch-user works correctly.
(
  flock 200

  pkill -u "$UID" -x polybar

  while pgrep -u "$UID" -x polybar > /dev/null; do sleep 0.5; done

  # Laptop-only modules: pick the first battery, AC adapter, and backlight if
  # they exist. LAPTOP_MODULES is expanded inside modules-right in config.ini
  # so the modules disappear on machines without these devices (e.g. the PC).
  BATTERY=""; ADAPTER=""; BACKLIGHT_CARD=""; LAPTOP_MODULES=""
  for b in /sys/class/power_supply/BAT*;  do [ -e "$b" ] && BATTERY=$(basename "$b") && break; done
  for a in /sys/class/power_supply/A[CDP]*; do [ -e "$a" ] && ADAPTER=$(basename "$a") && break; done
  for c in /sys/class/backlight/*;        do [ -e "$c" ] && BACKLIGHT_CARD=$(basename "$c") && break; done
  [ -n "$BATTERY" ] && [ -n "$BACKLIGHT_CARD" ] && LAPTOP_MODULES="backlight battery"
  export BATTERY ADAPTER BACKLIGHT_CARD LAPTOP_MODULES

  outputs=$(xrandr --query | grep " connected" | cut -d" " -f1)
  tray_output=$(echo "$outputs" | head -1)

  for m in $outputs; do
    [[ $m == "HDMI1" || $m == "DisplayPort-0" ]] && tray_output=$m
  done

  for m in $outputs; do
    export MONITOR=$m
    export TRAY_POSITION=none
    [[ $m == "$tray_output" ]] && TRAY_POSITION=right

    polybar --reload main </dev/null >"/var/tmp/polybar-$UID-$m.log" 2>&1 200>&- &
    disown
  done
) 200>"/var/tmp/polybar-launch-$UID.lock"
# https://github.com/polybar/polybar/issues/763
