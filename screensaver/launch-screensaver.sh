#!/bin/bash

# Exit early if we don't have the tte show
if ! command -v tte &>/dev/null; then
  exit 1
fi

# Exit early if screensave is already running
pgrep -f org.orphan.screensaver && exit 0

# Allow screensaver to be turned off but also force started
if [[ -f ~/.local/state/screensaver-off ]] && [[ $1 != "force" ]]; then
  exit 1
fi

focused=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')
terminal=Alacritty

for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
  hyprctl dispatch focusmonitor $m

  case $terminal in
  *Alacritty*)
    hyprctl dispatch exec -- \
      alacritty --class=org.orphan.screensaver \
      --config-file ~/.config/alacritty/screensaver.toml \
      -e ~/.config/screensaver/cmd-screensaver.sh
    ;;
  *ghostty*)
    hyprctl dispatch exec -- \
      ghostty --class=org.orphan.screensaver \
      --font-size=18 \
      -e ~/.config/screensaver/cmd-screensaver.sh
    ;;
  *kitty*)
    hyprctl dispatch exec -- \
      kitty --class=org.orphan.screensaver \
      --override font_size=18 \
      -e ~/.config/screensaver/cmd-screensaver.sh
    ;;
  *)
    notify-send "✋  Screensaver only runs in Alacritty, Ghostty, or Kitty"
    ;;
  esac
done

hyprctl dispatch focusmonitor $focused
