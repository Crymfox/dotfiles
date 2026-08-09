#!/bin/bash

notify_volume() {
    local vol=$(pamixer --get-volume)
    hyprctl notify -1 1000 "rgb(31748F)" "Volume: $vol%"
}

case "$1" in
    mute)
        pamixer -t
        if pamixer --get-mute | grep -q "true"; then
            hyprctl notify -1 1000 "rgb(31748F)" "Muted"
        else
            notify_volume
        fi
        ;;
    inc)
        pamixer -i 5
        notify_volume
        ;;
    dec)
        pamixer -d 5
        notify_volume
        ;;
esac
