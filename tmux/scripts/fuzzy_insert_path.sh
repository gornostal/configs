#!/usr/bin/env bash
# Fuzzy insert path into the current tmux pane.
# Usage: fuzzy_insert_path.sh <pane_id> [cd]
#
# Step 1 — pick a dir from history (Enter = insert dir, Tab = also pick a file)
# Step 2 — if Tab was pressed, fuzzy-pick a file under the selected dir
#
# With a second arg "cd" (used by the new-window binding), Enter runs
# `cd <dir>` in the pane instead of just typing the path. Tab still inserts.

# fzf --tmux defaults to a 50%-wide popup; on narrow clients (phone over SSH) use full width
popup=--tmux
[ "$(tmux display -p '#{client_width}')" -lt 100 ] && popup=--tmux=center,100%,50%

result=$(cat ~/.local/share/fish/dir_history \
  | sort -u \
  | while IFS= read -r d; do
      expanded="${d/#\~/$HOME}"
      [ -d "$expanded" ] && echo "$d"
    done \
  | fzf "$popup" --expect=tab --prompt="dir: ")

key=$(echo "$result" | head -1)
dir=$(echo "$result" | tail -1)

[ -z "$dir" ] && exit 0

if [ "$key" = "tab" ]; then
  expanded_dir="${dir/#\~/$HOME}"
  if command -v fd > /dev/null 2>&1; then
    list_files() { fd --type f --hidden --follow . "$1" 2>/dev/null | sed "s|^$1/||"; }
  else
    list_files() { find "$1" -type f -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | sed "s|^$1/||"; }
  fi
  file=$(list_files "$expanded_dir" | fzf "$popup" --prompt="file: ") || true
  if [ -n "$file" ]; then
    tmux send-keys -t "$1" "$dir/$file"
  else
    tmux send-keys -t "$1" "$dir"
  fi
elif [ "$2" = "cd" ]; then
  tmux send-keys -t "$1" "cd $dir" Enter
else
  tmux send-keys -t "$1" "$dir"
fi
