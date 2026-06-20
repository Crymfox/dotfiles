#!/usr/bin/bash

case "$1" in
  terminal)
    kitty
    ;;
  terminal2)
    alacritty
    ;;
  browser)
    if pgrep -x zen-browser >/dev/null; then
      hyprctl dispatch workspace "$(hyprctl clients -j | jq '.[] | select(.initialClass == "zen-beta") | .workspace.id')"
    else
      zen-browser
    fi
    ;;
  filesgui)
    thunar
    ;;
  rofi)
    rofi -show drun
    ;;
  dmenu)
    bemenu-run
    ;;
  clipboard)
    cliphist list | rofi -dmenu | cliphist decode | wl-copy
    ;;
  *)
    echo "Usage: $0 {terminal|terminal2|browser|filesgui|rofi|dmenu|clipboard}"
    exit 1
    ;;
esac
