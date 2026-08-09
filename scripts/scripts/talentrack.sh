#!/bin/bash

workdir="$HOME/wsl/pfe/talentrack"

launch_in_scratchpad() {
	hyprctl dispatch exec [workspace special silent] "$1" &
}

cd "$workdir/vue-app" || exit
code . &
launch_in_scratchpad "alacritty --hold --working-directory $workdir/vue-app -e npm run dev"

cd "$workdir/worker" || exit
code . &
launch_in_scratchpad "alacritty --hold --working-directory $workdir/worker -e npm run dev"
 notify-send "Talentrack started" "Happy coding!"