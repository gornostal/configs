#!/usr/bin/env bash
# Pick a pane from another tmux session via fzf and join it to the current window.
# Bound to: Prefix j

set -euo pipefail

current_session=$(tmux display-message -p '#S')

selection=$(tmux list-panes -a -F '#{session_name}	#{pane_id}	#{session_name}:#{window_index}.#{pane_index}  #{b:pane_current_path}  [#{pane_current_command}]' \
  | awk -F'\t' -v cur="$current_session" '$1 != cur { print $2 "\t" $3 }')

if [ -z "$selection" ]; then
  tmux display-message "No panes in other sessions"
  exit 0
fi

picked=$(printf '%s\n' "$selection" \
  | fzf --tmux --with-nth=2.. --delimiter='\t' --prompt="pane: " \
  | awk -F'\t' '{print $1}')

[ -z "$picked" ] && exit 0

tmux join-pane -s "$picked"
