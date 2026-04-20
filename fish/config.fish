fish_add_path ~/bin ~/.local/bin ~/.dotnet/tools
fish_add_path $HOME/.npm-global/bin

abbr sl "screen -ls"
abbr r "rsync -poghb --backup-dir=/tmp/rsync -e /dev/null --progress"
abbr op "xdg-open"
abbr hserver "python3 -m http.server"
abbr l 'ls -lA'
abbr v nvim
abbr weather "curl wttr.in"

alias G 'grep -E -i --color'
abbr L less
abbr X0 'xargs -0'

# drop long lines
abbr NOLL 'ut -c1-200'

# git
abbr gs "git status"
abbr ga "git add -A"
abbr ss 'git stash save -u'
abbr sp 'git stash pop'
abbr c 'git checkout'
abbr amendall "git add -A; and git commit --amend -C HEAD"

# LVM
abbr snap-start 'sudo lvcreate -s -n snap -L 20G /dev/elementary-vg/root'
abbr snap-revert 'sudo lvconvert --merge /dev/mapper/elementary--vg-snap'
abbr snap-persist 'sudo lvremove /dev/mapper/elementary--vg-snap'

# Docker
abbr d2p 'set -x DOCKER_HOST (podman info --format "unix://{{.Host.RemoteSocket.Path}}")'
abbr d 'sudo -E docker'
abbr di 'sudo docker images'
abbr dc 'sudo -E docker compose'
abbr dps 'sudo docker ps'
abbr dr 'sudo docker run --rm'
abbr dkrc 'sudo docker kill (sudo docker ps -q)' # kill running containers
abbr dsc 'sudo docker rm -v (sudo docker ps -a -q -f status=exited)' # delete stopped containers
abbr ddi 'sudo docker rmi (sudo docker images -q -f dangling=true)' # delete dangling images
abbr ddv 'sudo docker volume rm (sudo docker volume ls -q -f dangling=true)' # delete dangling volumes
abbr dst 'sudo docker stats --format "table {{.Name}}\t{{.Container}}\t{{.CPUPerc}}"'

# Podman
abbr p 'podman'
abbr pc 'podman compose'

# kubens autocompletion
abbr k 'kubectl'
abbr kl 'kubectl logs -f --tail=300'
complete --command kubens --arguments '(kubens)'

# dotnet
abbr dn 'dotnet'

# Wayland - force native Wayland for GTK, Qt, and Electron apps
set -gx GDK_BACKEND wayland
set -gx QT_QPA_PLATFORM wayland
set -gx ELECTRON_OZONE_PLATFORM_HINT wayland

# Deno
set -gx DENO_INSTALL ~/.deno

# AI
abbr x "codex -s danger-full-access"
abbr cv "claude --dangerously-skip-permissions"
abbr cop "copilot --disable-builtin-mcps --allow-all-paths --allow-all-tools"

# Turnip
abbr tip turnip
set -gx AWS_PROFILE default-mfa

# Dir history (absolute paths, persistent)
source ~/.config/fish/functions/__log_dir.fish
bind \cg 'fcd; commandline -f repaint'
