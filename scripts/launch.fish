#!/usr/bin/fish

if test -z "$argv[1]"
    echo "Please provide an argument"
    exit 1
end

set arg $argv[1]

# defaults
set terminal alacritty
set editor $EDITOR
set files $FILEMANAGER


function isRunning
    set appName $argv[1]
    if pgrep -x $appName >/dev/null
        return 0
    else
        return 1
    end
end

# Hyprland Only
function getWorkspaceId
    set appName $argv[1]
    set client (hyprctl clients -j | jq ".[] | select(.initialClass == \"$appName\") | .workspace.id")
    if test -n "$client"
        echo $client
    else
        echo 9 # Return 9 to indicate that the application is not running in any workspace
    end
end

function run_electron
    if test $XDG_SESSION_TYPE = wayland
        $argv[1] --ozone-platform=wayland --enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer
    else
        $argv[1]
    end
end

switch $arg
    # Hyprland Only
    case browser
        if isRunning firefox
            hyprctl dispatch workspace (getWorkspaceId "firefox")
        else
            firefox
        end

    case vivaldi
        if pgrep vivaldi >/dev/null
            set vivladiClient (hyprctl clients -j | jq ".[] | select(.initialClass == \"vivaldi-stable\") | .workspace.id")
            if test -n "$vivladiClient"
                hyprctl dispatch workspace $vivladiClient
            end
        else
            vivaldi
        end


    case code
        /usr/bin/code \
            --password-store="gnome" --ozone-platform=wayland

    case rofi
        rofi -show drun

    case dmenu
        bemenu-run


    case launcher
        ags -t applauncher

    case terminal
        alacritty
    case terminal2
        wezterm

    case tmux
        if tmux has
            alacritty -T tmux -e tmux a &
        else
            tmux new -d -s Default
            alacritty -T tmux -e tmux a &
        end

    case nvim
        $terminal --hold -e nvim &
    case neovide
        neovide

    case lunarvim
        $terminal --hold -e lvim &
    case lunarvide
        neovide --neovim-bin ~/.local/bin/lvim

    case filesgui
        $files

    case filestui
        $terminal -e ranger &

    case clipboard
        cliphist list | rofi -dmenu | cliphist decode | wl-copy

    case spotify
        run_electron spotify

    case spt
        spotifyd
        $terminal -e spt &
        $terminal -e cava &

    case passwords
        run_electron bitwarden-desktop &

    case http
        run_electron insomnia &

    case insomnia
        run_electron insomnia &

    case hypr_launch
        hyprctl keyword general:col.active_border "rgba(bada55ff) rgba(1a1b26ff)"
    case hypr_reset
        switch $theme
            case tokyonight
                ags -r "(await import('file://$HOME/.config/ags/js/settings/theme.js')).setTheme('Tokyo')"
            case rosepine
                ags -r "(await import('file://$HOME/.config/ags/js/settings/theme.js')).setTheme('RosePine')"
            case nero
                ags -r "(await import('file://$HOME/.config/ags/js/settings/theme.js')).setTheme('nero')"
            case idx
                ags -r "(await import('file://$HOME/.config/ags/js/settings/theme.js')).setTheme('idx')"
        end
    case hypr_windowmode
        hyprctl keyword general:col.active_border "rgba(FA7A55ff) rgba(00000000) rgba(FA7A55ff) rgba(00000000)"
end
