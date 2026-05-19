#!/bin/bash
# Lock and log files are per-user so multi-user/switch-user works correctly.
(
  flock 200

  pkill -u "$UID" -x polybar

  while pgrep -u "$UID" -x polybar > /dev/null; do sleep 0.5; done

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
