#!/usr/bin/env bash
# Fuzzy insert path into the current tmux pane.
# Usage: fuzzy_insert_path.sh <pane_id>
#
# Step 1 — pick a dir from history (Enter = insert dir, Tab = also pick a file)
# Step 2 — if Tab was pressed, fuzzy-pick a file under the selected dir

result=$(cat ~/.local/share/fish/dir_history \
  | sort -u \
  | while IFS= read -r d; do [ -d "$d" ] && echo "$d"; done \
  | fzf --tmux --expect=tab --prompt="dir: ")

key=$(echo "$result" | head -1)
dir=$(echo "$result" | tail -1)

[ -z "$dir" ] && exit 0

if [ "$key" = "tab" ]; then
  if command -v fd > /dev/null 2>&1; then
    list_files() { fd --type f --hidden --follow . "$1" 2>/dev/null | sed "s|^$1/||"; }
  else
    list_files() { find "$1" -type f -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | sed "s|^$1/||"; }
  fi
  file=$(list_files "$dir" | fzf --tmux --prompt="file: ") || true
  if [ -n "$file" ]; then
    tmux send-keys -t "$1" "$dir/$file"
  else
    tmux send-keys -t "$1" "$dir"
  fi
else
  tmux send-keys -t "$1" "$dir"
fi
