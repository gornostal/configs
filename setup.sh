#!/bin/bash
# Link every config into place, overwriting whatever is there, so the repo is the
# only copy. A real file or dir in the way is moved to <path>.bak.<timestamp>
# first, so local edits that never made it into the repo are not lost.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"

link() {
    local src="$1" dest="$2"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "ok        $dest"
        return
    fi
    if [ -L "$dest" ]; then
        echo "relink    $dest (was -> $(readlink "$dest"))"
        rm "$dest"
    elif [ -e "$dest" ]; then
        # a plain `ln -sf` would delete a file, or nest the link inside a dir
        echo "backup    $dest -> $dest.bak.$STAMP"
        mv "$dest" "$dest.bak.$STAMP"
    else
        echo "link      $dest"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
}

link "$SCRIPT_DIR/claude-code/commands" "$HOME/.claude/commands"

chmod +x "$SCRIPT_DIR"/bin/*
for src in "$SCRIPT_DIR"/bin/*; do
    link "$src" "$HOME/bin/$(basename "$src")"
done

link "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"

# Match Kitty's config directory overrides; link the whole directory so includes
# and automatic themes always use the repo files too.
KITTY_CONFIG_DEST="${KITTY_CONFIG_DIRECTORY:-${XDG_CONFIG_HOME:-$HOME/.config}/kitty}"
link "$SCRIPT_DIR/kitty" "$KITTY_CONFIG_DEST"

for src in "$SCRIPT_DIR"/desktop/*.desktop; do
    link "$src" "$HOME/.local/share/applications/$(basename "$src")"
done
# Icon=kitty only resolves if the icon is in the theme path; the installer's
# ~/.local/kitty.app/share isn't on XDG_DATA_DIRS.
KITTY_ICONS="$HOME/.local/kitty.app/share/icons/hicolor"
for size in 256x256/apps/kitty.png scalable/apps/kitty.svg; do
    [ -e "$KITTY_ICONS/$size" ] && link "$KITTY_ICONS/$size" "$HOME/.local/share/icons/hicolor/$size"
done

link "$SCRIPT_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
chmod +x "$SCRIPT_DIR"/tmux/scripts/*.sh "$SCRIPT_DIR"/tmux/scripts/*.py
link "$SCRIPT_DIR/tmux/scripts" "$HOME/.config/tmux/scripts"

# Fish is linked file by file: ~/.config/fish also holds machine-local state
# (fish_variables, installer-written completions) that must stay out of the repo.
link "$SCRIPT_DIR/fish/config.fish" "$HOME/.config/fish/config.fish"
for src in "$SCRIPT_DIR"/fish/functions/*.fish; do
    link "$src" "$HOME/.config/fish/functions/$(basename "$src")"
done
for src in "$SCRIPT_DIR"/fish/conf.d/*.fish; do
    link "$src" "$HOME/.config/fish/conf.d/$(basename "$src")"
done
