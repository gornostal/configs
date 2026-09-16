function fcd
    set -l dir (tac ~/.local/share/fish/dir_history | awk '!seen[$0]++' | head -100 | while read -l d
            test -d (string replace --regex '^~' $HOME -- $d); and echo $d
        end | fzf --no-sort)
    and cd (string replace --regex '^~' $HOME -- $dir)
end
