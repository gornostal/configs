#!/usr/bin/env bash
# Pick a pane from another tmux session via fzf and join it to the current window.
# Bound to: Prefix j

set -euo pipefail

current_session=$(tmux display-message -p '#S')

# Panes already reachable from this session. A window can be linked into several
# sessions, and grouped sessions (new-session -t) share all of their windows, so
# the same pane shows up in list-panes -a once per session it belongs to.
own_panes=$(tmux list-panes -s -t "$current_session" -F '#{pane_id}')

selection=$(tmux list-panes -a -F '#{pane_id}	#{session_name}:#{window_index}.#{pane_index}  #{b:pane_current_path}  [#{pane_current_command}]' \
  | awk -F'\t' -v own="$own_panes" '
      BEGIN { n = split(own, ids, "\n"); for (i = 1; i <= n; i++) mine[ids[i]] = 1 }
      !mine[$1] && !seen[$1]++')

if [ -z "$selection" ]; then
  tmux display-message "No panes in other sessions"
  exit 0
fi

picked=$(printf '%s\n' "$selection" \
  | fzf --tmux --with-nth=2.. --delimiter='\t' --prompt="pane: " \
  | awk -F'\t' '{print $1}')

[ -z "$picked" ] && exit 0

tmux join-pane -s "$picked"
