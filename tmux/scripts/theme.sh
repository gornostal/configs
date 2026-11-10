#!/bin/sh
# Light/dark theme for tmux and the apps in its panes (Neovim, Claude Code), per session.
#   theme.sh light|dark          the terminal reported its theme (client-*-theme hooks)
#   theme.sh cycle SESSION       status bar toggle: auto -> light -> dark -> auto
#   theme.sh window SESSION WIN  WIN was linked into SESSION (window-linked hook)
#   theme.sh session SESSION     SESSION was created (session-created hook)
#   theme.sh                     re-apply everything (config reload)
#
# Each session is auto|light|dark: session option @theme_mode, unset = auto. auto keeps
# the terminal's own colours, so it suits kitty, which follows the desktop; the global
# options hold this auto theme, following @theme_terminal, the theme the terminal last
# reported. light/dark paint the panes instead (window-style plus the elementary palette
# in pane-colours), for terminals that don't report a theme, like Termius: the session
# overrides the global options with its own, and so do its windows, as pane colours are
# window options. Back to auto, the overrides are unset.
#
# Grouped sessions (new -t) share their windows, so the mode is per group: any member's
# @theme_mode is the group's, and new members and newly linked windows get it from the
# hooks. For the same reason a forced theme shows in every client attached to the group.
#
# tmux 3.6 derives each pane's theme from its background, so painting it is enough
# for apps that subscribe to theme reports (Claude Code) and for background queries
# (Neovim at startup). Running Neovims ignore the reports: nvim_background.sh.

dir=$(dirname "$0")

# Palettes of kitty/elementary-*.conf: foreground, background, then colors 0-15.
dark="#a5a5a5 #2E2E2E #073642 #dc322f #859900 #b58900 #268bd2 #d33682 #2aa198 #eee8d5
      #5e5c64 #dc322f #586e75 #657b83 #839496 #6c71c4 #93a1a1 #fdf6e3"
light="#073642 #FDF6E3 #073642 #dc322f #859900 #b58900 #268bd2 #d33682 #2aa198 #eee8d5
       #93a1a1 #dc322f #586e75 #657b83 #839496 #6c71c4 #93a1a1 #fdf6e3"

# Options a forced session overrides, besides @theme_mode
session_vars="status-style @tab_fg @tab_bg @tab_zoom_fg @tab_claude_fg @fzf_colors @theme @theme_icon"

# A session's group, or the session itself when it has none
group='#{?session_grouped,#{session_group},#{session_id}}'

# group_sessions SESSION: every session in SESSION's group
group_sessions() {
    tmux list-sessions -F "$group	#{session_id}" |
        awk -F'\t' -v g="$(tmux display -p -t "$1" "$group")" '$1 == g { print $2 }'
}

# group_mode SESSION: light|dark if any session in SESSION's group forces it
group_mode() {
    tmux list-sessions -F "$group	#{@theme_mode}" |
        awk -F'\t' -v g="$(tmux display -p -t "$1" "$group")" '$1 == g && $2 { print $2; exit }'
}

# The functions below print tmux commands, for tmux source-file. SCOPE is -g or
# -t 'ID' (quoted: session ids start with $, which tmux would expand).

# theme_opts SCOPE THEME: status bar colours and other per-theme values
theme_opts() {
    if [ "$2" = light ]; then
        echo "set $1 status-style 'fg=#073642,bg=#eee8d5'"
        echo "set $1 @tab_fg '#073642'"
        echo "set $1 @tab_bg '#ddd6c1'"
        echo "set $1 @tab_zoom_fg '#cb4b16'"
        echo "set $1 @tab_claude_fg '#c15f3c'"
        # fzf's light scheme draws matches in a dull teal, hard to see on cream
        echo "set $1 @fzf_colors 'light,hl:#cb4b16:bold,hl+:#cb4b16:bold,fg+:#073642,bg+:#eee8d5,gutter:-1,pointer:#d33682'"
    else
        echo "set $1 status-style 'fg=white,bg=colour235'"
        echo "set $1 @tab_fg colour250"
        echo "set $1 @tab_bg colour237"
        echo "set $1 @tab_zoom_fg colour215"
        echo "set $1 @tab_claude_fg '#d97757'"
        echo "set $1 @fzf_colors dark"
    fi
    # The theme in effect, for tools started in panes (bin/delta-themed)
    echo "set $1 @theme $2"
}

# apply_session SESSION MODE
apply_session() {
    case $2 in
        light|dark)
            theme_opts "-t '$1'" "$2"
            [ "$2" = light ] && icon="☀" || icon="☾"
            echo "set -t '$1' @theme_icon '$icon'"
            echo "set -t '$1' @theme_mode $2" ;;
        *)
            for opt in $session_vars @theme_mode; do
                echo "set -u -t '$1' $opt"
            done ;;
    esac
}

# apply_window WINDOW MODE
apply_window() {
    case $2 in
        light|dark)
            [ "$2" = light ] && set -- "$1" $light || set -- "$1" $dark
            echo "set -w -t '$1' window-style 'fg=$2,bg=$3'"
            win=$1
            shift 3
            i=0
            for colour; do
                echo "set -w -t '$win' pane-colours[$i] '$colour'"
                i=$((i + 1))
            done ;;
        *)
            echo "set -wu -t '$1' window-style"
            echo "set -wu -t '$1' pane-colours" ;;
    esac
}

# apply_group SESSION MODE: SESSION's whole group and its windows
apply_group() {
    for s in $(group_sessions "$1"); do
        apply_session "$s" "$2"
    done
    for w in $(tmux list-windows -t "$1" -F '#{window_id}'); do
        apply_window "$w" "$2"
    done
}

# The global options: auto, the theme the terminal reported
apply_global() {
    theme=$(tmux show -gqv @theme_terminal)
    theme_opts -g "${theme:-dark}"
    echo "set -g @theme_icon '◐'"
    echo "set -gw window-style default"
    echo "set -gwu pane-colours"
}

case $1 in
    light|dark)
        tmux set -g @theme_terminal "$1"
        apply_global | tmux source-file - ;;
    cycle)
        case $(group_mode "$2") in light) mode=dark ;; dark) mode=auto ;; *) mode=light ;; esac
        apply_group "$2" "$mode" | tmux source-file - ;;
    # A new window or group member only takes on the group's theme; Neovims are left
    # alone, as one only moves between themes by moving a window between groups.
    window)
        apply_window "$3" "$(group_mode "$2")" | tmux source-file -
        exit ;;
    session)
        apply_session "$2" "$(group_mode "$2")" | tmux source-file -
        exit ;;
    *)
        # The mode is per session, never global (a global one would apply to all)
        tmux set -gu @theme_mode
        {
            apply_global
            tmux list-sessions -F "$group	#{session_id}" | awk -F'\t' '!seen[$1]++ { print $2 }' |
                while read -r s; do
                    apply_group "$s" "$(group_mode "$s")"
                done
        } | tmux source-file - ;;
esac

"$dir/nvim_background.sh"
