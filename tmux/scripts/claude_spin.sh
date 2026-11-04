#!/usr/bin/env bash
# Animate the Claude mark on tabs flagged by claude_status.py: cycles the global
# option @cc_spin through the frames below every 0.4s, and the tab formats in
# .tmux.conf draw it. status-interval can't go below 1s, hence a loop of its own.
#
#   claude_spin.sh <socket_path>   (started from .tmux.conf with run-shell -b)
#
# One loop per server: each start records its pid in @cc_spin_pid, and an older
# loop exits when it sees another pid there, so reloading the config picks up
# edits to this file. Exits with the server. Sets the option only while some
# window is busy, since every set-option redraws all clients.

socket=$1
[ -n "$socket" ] || { echo "usage: claude_spin.sh <tmux socket path>" >&2; exit 1; }
# run-shell would show any output in a pane, and report a non-zero exit status
# (hence the "exit 0"s: losing ownership or the server is the normal way out)
exec >/dev/null 2>&1

t() { tmux -S "$socket" "$@"; }

frames=(✳ ✢ ·)
i=0
t set -g @cc_spin_pid $$ || exit 0
while sleep 0.4; do
    # first line: owner pid; then a line per busy window, if any
    out=$(t show -gv @cc_spin_pid \; list-windows -a -f '#{@cc_busy}' -F x) || exit 0
    [ "${out%%$'\n'*}" = $$ ] || exit 0
    [[ $out == *$'\n'* ]] || continue
    i=$(( (i + 1) % ${#frames[@]} ))
    t set -g @cc_spin "${frames[i]}"
done
