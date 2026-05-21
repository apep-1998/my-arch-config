#!/bin/bash
SRC="$HOME/.config/i3/wallpapers/lock-screen.png"
CACHE_DIR="$HOME/.cache/i3lock"
mkdir -p "$CACHE_DIR"

# Geometry of every connected, enabled monitor as "WxH+X+Y" lines. The xrandr
# regex matches only real outputs (disconnected entries and listed modes have
# no +X+Y suffix).
mapfile -t monitors < <(xrandr --query | grep -oE ' [0-9]+x[0-9]+\+[0-9]+\+[0-9]+' | tr -d ' ')
if [ ${#monitors[@]} -eq 0 ]; then
  echo "lock.sh: no connected monitors found" >&2
  exit 1
fi

# Total virtual desktop size — the canvas i3lock paints onto.
RES=$(xdpyinfo | awk '/dimensions:/ {print $2; exit}')
TOTAL_W=${RES%x*}
TOTAL_H=${RES#*x}

# Cache key includes the full monitor layout so layout changes re-render.
CACHE_KEY=$(printf '%s\n' "${monitors[@]}" "$TOTAL_W" "$TOTAL_H" | md5sum | cut -d' ' -f1)
OUT="$CACHE_DIR/lock-$CACHE_KEY.png"

if [ ! -f "$OUT" ] || [ "$SRC" -nt "$OUT" ]; then
  # Build an ffmpeg filter graph that:
  #   - cover-fits SRC to each monitor's resolution (scale+crop)
  #   - overlays each result onto a virtual-desktop-sized black canvas at the
  #     monitor's (X, Y) position
  # So every monitor sees its own full copy of the image instead of one image
  # stretched across them all.
  inputs=()
  filter=""
  for i in "${!monitors[@]}"; do
    inputs+=("-i" "$SRC")
    wh=${monitors[$i]%%+*}
    w=${wh%x*}
    h=${wh#*x}
    filter+="[${i}:v]scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h}[m${i}];"
  done
  filter+="color=c=black:size=${TOTAL_W}x${TOTAL_H}[bg];"
  prev="bg"
  last=$((${#monitors[@]} - 1))
  for i in "${!monitors[@]}"; do
    rest=${monitors[$i]#*+}
    x=${rest%%+*}
    y=${rest#*+}
    if [ "$i" -eq "$last" ]; then
      filter+="[${prev}][m${i}]overlay=${x}:${y}[final]"
    else
      next="s${i}"
      filter+="[${prev}][m${i}]overlay=${x}:${y}[${next}];"
      prev="$next"
    fi
  done
  ffmpeg -y -loglevel error "${inputs[@]}" -filter_complex "$filter" -map "[final]" -frames:v 1 "$OUT"
fi

# Switch to English-only before locking so i3lock always accepts Latin input.
# us,ir keeps both layouts registered but the active group may still be Persian;
# setting only "us" removes that ambiguity entirely.
setxkbmap us

i3-msg -t send_tick "FORCE_US_LAYOUT_START"

i3lock -i "$OUT"

# Restore full layout (us + ir) after unlock so the normal toggle works again.
setxkbmap -layout us,ir -option grp:alt_shift_toggle
i3-msg -t send_tick "FORCE_US_LAYOUT_END"
