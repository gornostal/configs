#!/usr/bin/env bash
# Fuzzy insert path into the current tmux pane.
# Usage: fuzzy_insert_path.sh <pane_id> [cd]
#
# Step 1 — pick a dir from history (Enter = insert dir, Tab = also pick a file)
# Step 2 — if Tab was pressed, fuzzy-pick a file under the selected dir
#
# With a second arg "cd" (used by the new-window binding), Enter runs
# `cd <dir>` in the pane instead of just typing the path. Tab still inserts.
#
# Picks are remembered per query: choose a dir after typing "conf" and the next
# time "conf" is typed the cursor jumps to that dir instead of the best match.
# Exact query only; pick another dir for the same query to overwrite it.

# query<TAB>dir, one line per query
memory=~/.local/share/fish/dir_picks

# Queries are stored with whitespace trimmed and collapsed, as fzf ignores it:
# "conf " and "conf" must find the same pick
normalize() { awk '{ $1 = $1; print }' <<< "$1"; }

# fzf result-event hook (see --bind below): print pos(N) of the dir remembered
# for $FZF_QUERY. N comes from re-running the same match in --filter mode,
# which ranks the list the way the interactive fzf just did.
if [ "$1" = "--remembered-pos" ]; then
  Q=$(normalize "$FZF_QUERY")
  [ -n "$Q" ] && [ -f "$memory" ] || exit 0
  dir=$(Q=$Q awk -F'\t' '$1 == ENVIRON["Q"] { print $2; exit }' "$memory")
  [ -n "$dir" ] || exit 0
  n=$(fzf --filter "$FZF_QUERY" < "$2" | grep -nxFm1 -- "$dir" | cut -d: -f1)
  [ -n "$n" ] && echo "pos($n)"
  exit 0
fi

# fzf --tmux defaults to a 50%-wide popup; on narrow clients (phone over SSH) use full width
popup=--tmux
[ "$(tmux display -p '#{client_width}')" -lt 100 ] && popup=--tmux=center,100%,50%
# fzf can't detect a light background; colours for the tmux theme (theme.sh)
colors=--color=$(tmux show -gqv @fzf_colors)

# The list goes to a file so the --remembered-pos hook can rank it too
list=$(mktemp)
trap 'rm -f "$list"' EXIT
sort -u ~/.local/share/fish/dir_history \
  | while IFS= read -r d; do
      expanded="${d/#\~/$HOME}"
      [ -d "$expanded" ] && echo "$d"
    done > "$list"

self=$(realpath "${BASH_SOURCE[0]}")
result=$(fzf "$popup" "$colors" --expect=tab --print-query --prompt="dir: " \
  --bind "result:transform:'$self' --remembered-pos '$list'" < "$list")

query=$(normalize "$(sed -n 1p <<< "$result")")
key=$(sed -n 2p <<< "$result")
dir=$(sed -n 3p <<< "$result")

[ -z "$dir" ] && exit 0

if [ -n "$query" ]; then
  { [ -f "$memory" ] && Q=$query awk -F'\t' '$1 != ENVIRON["Q"]' "$memory"
    printf '%s\t%s\n' "$query" "$dir"
  } > "$memory.tmp" && mv "$memory.tmp" "$memory"
fi

if [ "$key" = "tab" ]; then
  expanded_dir="${dir/#\~/$HOME}"
  if command -v fd > /dev/null 2>&1; then
    list_files() { fd --type f --hidden --follow . "$1" 2>/dev/null | sed "s|^$1/||"; }
  else
    list_files() { find "$1" -type f -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | sed "s|^$1/||"; }
  fi
  file=$(list_files "$expanded_dir" | fzf "$popup" "$colors" --prompt="file: ") || true
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
