# nvm.sh is bash-only, so run it there. Changes to PATH (`nvm use`) stay in bash.
function nvm --description 'Run nvm via bash'
    bash -c 'source ~/.nvm/nvm.sh --no-use && nvm "$@"' nvm $argv
end
