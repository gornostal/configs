#!/bin/bash

NVIM_CONFIG_DIR="$HOME/.config/nvim"
TMUX_CONFIG_FILE="$HOME/.tmux.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.config"

if [ -e "$NVIM_CONFIG_DIR" ]; then
    echo "Neovim config already exists at $NVIM_CONFIG_DIR, skipping setup."
else
    ln -s "$SCRIPT_DIR/nvim" "$NVIM_CONFIG_DIR"
    echo "Neovim config linked to $NVIM_CONFIG_DIR"
fi

if [ -e "$TMUX_CONFIG_FILE" ]; then
    echo "Tmux config already exists at $TMUX_CONFIG_FILE, skipping setup."
else
    ln -s "$SCRIPT_DIR/tmux/.tmux.conf" "$TMUX_CONFIG_FILE"
    echo "Tmux config linked to $TMUX_CONFIG_FILE"
fi
