#!/bin/bash
SRC="$HOME/.config/i3/wallpapers/lock-screen.png"
CACHE_DIR="$HOME/.cache/i3lock"
mkdir -p "$CACHE_DIR"

# Resize the source image to the current X display size (the bounding box of
# all connected monitors) using a "cover" fit — scale up to fill, then crop
# any overflow from the centre. Cache the result per-geometry so we only
# re-render when the screen layout or the source image changes.
RES=$(xdpyinfo | awk '/dimensions:/ {print $2; exit}')
OUT="$CACHE_DIR/lock-$RES.png"
if [ ! -f "$OUT" ] || [ "$SRC" -nt "$OUT" ]; then
  W=${RES%x*}
  H=${RES#*x}
  ffmpeg -y -loglevel error -i "$SRC" \
    -vf "scale=${W}:${H}:force_original_aspect_ratio=increase,crop=${W}:${H}" \
    "$OUT"
fi

# Switch to English-only before locking so i3lock always accepts Latin input.
# us,ir keeps both layouts registered but the active group may still be Persian;
# setting only "us" removes that ambiguity entirely.
setxkbmap us

i3-msg -t send_tick "FORCE_US_LAYOUT_START"

i3lock -i "$OUT" -t

# Restore full layout (us + ir) after unlock so the normal toggle works again.
setxkbmap -layout us,ir -option grp:alt_shift_toggle
i3-msg -t send_tick "FORCE_US_LAYOUT_END"
