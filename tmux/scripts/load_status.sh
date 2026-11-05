#!/bin/sh
# 1-minute load average; highlighted like ram_status.sh when above 20
awk '{
    if ($1 > 20) printf "#[fg=white,bg=red,bold]LA %.1f#[default]", $1
    else printf "LA %.1f", $1
}' /proc/loadavg
