#!/bin/sh
pct=$(free | awk 'NR==2 {printf "%.0f", $3/$2*100}')
if [ "$pct" -ge 90 ]; then
    printf '#[fg=white,bg=red,bold]RAM %s%%#[default]' "$pct"
else
    printf 'RAM %s%%' "$pct"
fi
