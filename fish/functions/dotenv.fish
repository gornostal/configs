function dotenv --description 'Load KEY=value pairs from a .env file into the current shell'
    set -l file (test -n "$argv[1]"; and echo $argv[1]; or echo .env)
    if not test -f $file
        echo "dotenv: $file not found" >&2
        return 1
    end
    for line in (grep -v '^\s*#' $file | grep -v '^\s*$')
        set -l kv (string split -m 1 '=' -- $line)
        set -l key (string trim -- $kv[1])
        set -l val (string trim -- $kv[2])
        set val (string replace -r '^"(.*)"$' '$1' -- $val)
        set val (string replace -r "^'(.*)'\$" '$1' -- $val)
        set -gx $key $val
    end
end
