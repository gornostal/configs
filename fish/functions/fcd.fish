function fcd
    set dir (cat ~/.local/share/fish/dir_history | sort -u | while read -l d; test -d $d; and echo $d; end | fzf)
    and cd $dir
end
