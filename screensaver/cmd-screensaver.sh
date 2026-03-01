#!/bin/bash

screensaver_in_focus() {
  hyprctl activewindow -j | jq -e '.class == "org.orphan.screensaver"' >/dev/null 2>&1
}

exit_screensaver() {
  hyprctl keyword cursor:invisible false
  pkill -x tte 2>/dev/null
  pkill -f org.orphan.screensaver 2>/dev/null
  exit 0
}

trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT

printf '\033]11;rgb:00/00/00\007'  # Set background color to black

hyprctl keyword cursor:invisible true &>/dev/null

file=$(ls ~/.config/screensaver/ASCII | shuf -n 1)

while true; do
  tte -i ~/.config/screensaver/ASCII/$file \
    --frame-rate 120 --canvas-width 0 --canvas-height 0 --anchor-canvas c --anchor-text c\
    --no-eol --no-restore-cursor --random-effect &

  while pgrep -x tte >/dev/null; do
    if read -n 1 -t 3 || ! screensaver_in_focus; then
      exit_screensaver
    fi
  done
done
