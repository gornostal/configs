function __log_dir --on-variable PWD
    echo $PWD >> ~/.local/share/fish/dir_history
end
