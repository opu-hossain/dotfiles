#!/usr/bin/env bash
# Starts awww-daemon (if not already running) and sets the wallpaper.
# Note: awww is the renamed successor to swww (same author, different CLI
# prefix) — it is NOT a typo. Waits for the daemon's IPC socket instead of
# a fixed sleep, since a fixed sleep is either too short on a slow boot or
# wastes time otherwise.

WALLPAPER="$HOME/Pictures/Wallpapers/wgruv_1.jpg"

if ! pgrep -x awww-daemon >/dev/null; then
    awww-daemon &
fi

for _ in $(seq 1 25); do
    if awww query &>/dev/null; then
        awww img "$WALLPAPER" --transition-type simple
        exit 0
    fi
    sleep 0.2
done

echo "wallpaper.sh: awww-daemon never became ready" >&2
exit 1
