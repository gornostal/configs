#!/bin/bash

NVIM_CONFIG_DIR="$HOME/.config/nvim"
TMUX_CONFIG_FILE="$HOME/.tmux.conf"
FISH_CONFIG_DIR="$HOME/.config/fish"
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

mkdir -p "$FISH_CONFIG_DIR/functions" "$FISH_CONFIG_DIR/conf.d"

for src in config.fish; do
    dest="$FISH_CONFIG_DIR/$src"
    if [ -e "$dest" ]; then
        echo "Fish $src already exists at $dest, skipping."
    else
        ln -s "$SCRIPT_DIR/fish/$src" "$dest"
        echo "Fish $src linked to $dest"
    fi
done

for src in fcd.fish fish_prompt.fish __log_dir.fish; do
    dest="$FISH_CONFIG_DIR/functions/$src"
    if [ -e "$dest" ]; then
        echo "Fish function $src already exists at $dest, skipping."
    else
        ln -s "$SCRIPT_DIR/fish/functions/$src" "$dest"
        echo "Fish function $src linked to $dest"
    fi
done

for src in omf.fish rustup.fish; do
    dest="$FISH_CONFIG_DIR/conf.d/$src"
    if [ -e "$dest" ]; then
        echo "Fish conf.d/$src already exists at $dest, skipping."
    else
        ln -s "$SCRIPT_DIR/fish/conf.d/$src" "$dest"
        echo "Fish conf.d/$src linked to $dest"
    fi
done
