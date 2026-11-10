#!/bin/sh
# Set 'background' (dark|light) in every running Neovim to the theme of the tmux session
# it runs in (@theme, see theme.sh, which runs this). Neovim 0.11 reads the terminal's
# background once at startup and ignores live theme switches, so this tells it through
# each instance's default server socket. Changing it reloads the colorscheme, which
# picks its light or dark palette, so instances already right are left alone.
# A Neovim outside tmux gets the global (auto) theme.
global=$(tmux show -gqv @theme)
panes=$(tmux list-panes -a -F '#{pane_pid} #{@theme}')
for sock in "$XDG_RUNTIME_DIR"/nvim.*.0; do
    [ -S "$sock" ] || continue
    # Walk up from Neovim (its pid is in the socket name) to the pane's shell
    pid=${sock##*/nvim.}
    pid=${pid%.0}
    theme=
    while [ -z "$theme" ] && [ "${pid:-1}" -gt 1 ]; do
        theme=$(printf '%s\n' "$panes" | awk -v p="$pid" '$1 == p { print $2; exit }')
        pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
    done
    theme=${theme:-$global}
    timeout 2 nvim --server "$sock" \
        --remote-expr "execute('if &bg !=# \"$theme\" | set bg=$theme | endif')" >/dev/null 2>&1 &
done
wait
