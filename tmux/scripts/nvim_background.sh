#!/bin/sh
# Set 'background' (dark|light) in every running Neovim; run by the tmux theme hooks.
# Neovim 0.11 reads the terminal's background once at startup and ignores live theme
# switches, so this tells it through each instance's default server socket.
# catppuccin (flavour "auto") then swaps mocha/latte.
for sock in "$XDG_RUNTIME_DIR"/nvim.*.0; do
    [ -S "$sock" ] || continue
    timeout 2 nvim --server "$sock" --remote-expr "execute('set background=$1')" >/dev/null 2>&1 &
done
wait
