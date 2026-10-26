#!/bin/sh
# Light/dark theme for tmux and the apps in its panes (Neovim, Claude Code).
#   theme.sh light|dark   the terminal reported its theme (client-*-theme hooks)
#   theme.sh cycle        status bar toggle: auto -> light -> dark -> auto
#   theme.sh              re-apply (config reload)
#
# @theme_mode is auto|light|dark (unset = auto); @theme_terminal is the theme the
# terminal last reported. auto keeps the terminal's own colours, so it suits kitty,
# which follows the desktop. light/dark paint the panes instead (window-style plus
# the elementary palette in pane-colours), for terminals that don't report a theme,
# like Termius. Pane colours are per window, not per client, so a forced theme shows
# in every attached client.
#
# tmux 3.6 derives each pane's theme from its background, so painting it is enough
# for apps that subscribe to theme reports (Claude Code) and for background queries
# (Neovim at startup). Running Neovims ignore the reports: nvim_background.sh.

mode=$(tmux show -gqv @theme_mode)
terminal=$(tmux show -gqv @theme_terminal)
case $1 in
    light|dark)
        terminal=$1
        tmux set -g @theme_terminal "$terminal" ;;
    cycle)
        case $mode in light) mode=dark ;; dark) mode=auto ;; *) mode=light ;; esac
        tmux set -g @theme_mode "$mode" ;;
esac

case $mode in
    light|dark) theme=$mode ;;
    *) mode=auto; theme=${terminal:-dark} ;;
esac

# Palettes of kitty/elementary-*.conf: foreground, background, then colors 0-15.
dark="#a5a5a5 #2E2E2E #073642 #dc322f #859900 #b58900 #268bd2 #d33682 #2aa198 #eee8d5
      #5e5c64 #dc322f #586e75 #657b83 #839496 #6c71c4 #93a1a1 #fdf6e3"
light="#073642 #FDF6E3 #073642 #dc322f #859900 #b58900 #268bd2 #d33682 #2aa198 #eee8d5
       #93a1a1 #dc322f #586e75 #657b83 #839496 #6c71c4 #93a1a1 #fdf6e3"

{
    if [ "$mode" = auto ]; then
        echo "set -gw window-style default"
        echo "set -gwu pane-colours"
    else
        [ "$theme" = light ] && set -- $light || set -- $dark
        echo "set -gw window-style 'fg=$1,bg=$2'"
        shift 2
        i=0
        for colour; do
            echo "set -gw pane-colours[$i] '$colour'"
            i=$((i + 1))
        done
    fi

    if [ "$theme" = light ]; then
        echo "set -g status-style 'fg=#073642,bg=#eee8d5'"
        echo "set -g @tab_fg '#073642'"
        echo "set -g @tab_bg '#ddd6c1'"
        echo "set -g @tab_zoom_fg '#cb4b16'"
    else
        echo "set -g status-style 'fg=white,bg=colour235'"
        echo "set -g @tab_fg colour250"
        echo "set -g @tab_bg colour237"
        echo "set -g @tab_zoom_fg colour215"
    fi

    case $mode in light) icon="☀" ;; dark) icon="☾" ;; *) icon="◐" ;; esac
    echo "set -g @theme_icon '$icon'"
    # The theme in effect, for tools started in panes (bin/delta-themed)
    echo "set -g @theme $theme"
} | tmux source-file -

"$(dirname "$0")/nvim_background.sh" "$theme"
