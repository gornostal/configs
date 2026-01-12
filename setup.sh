#!/bin/bash

NVIM_CONFIG_DIR="$HOME/.config/nvim"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -e "$NVIM_CONFIG_DIR" ]; then
    echo "Neovim config already exists at $NVIM_CONFIG_DIR, skipping setup."
    exit 0
fi

mkdir -p "$HOME/.config"
ln -s "$SCRIPT_DIR/nvim" "$NVIM_CONFIG_DIR"
echo "Neovim config linked to $NVIM_CONFIG_DIR"
