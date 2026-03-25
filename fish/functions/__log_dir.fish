function __log_dir --on-variable PWD
    set -l dir (string replace --regex "^$HOME" "~" $PWD)
    echo $dir >> ~/.local/share/fish/dir_history
end
