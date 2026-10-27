function fcd
    # fzf can't detect a light background; inside tmux use the colours for its theme
    # (tmux/scripts/theme.sh)
    set -l colors
    set -q TMUX; and set colors --color=(tmux show -gqv @fzf_colors)
    set -l dir (tac ~/.local/share/fish/dir_history | awk '!seen[$0]++' | head -100 | while read -l d
            test -d (string replace --regex '^~' $HOME -- $d); and echo $d
        end | fzf --no-sort $colors)
    and cd (string replace --regex '^~' $HOME -- $dir)
end
