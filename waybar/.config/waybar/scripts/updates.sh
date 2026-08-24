#!/usr/bin/env bash

official="$(checkupdates 2>/dev/null)"
aur=""

if command -v yay &>/dev/null; then
    aur="$(yay -Qua 2>/dev/null)"
elif command -v paru &>/dev/null; then
    aur="$(paru -Qua 2>/dev/null)"
fi

official_count=0
[ -n "$official" ] && official_count=$(grep -c '^' <<< "$official")

aur_count=0
[ -n "$aur" ] && aur_count=$(grep -c '^' <<< "$aur")

total=$((official_count + aur_count))

if [ "$total" -eq 0 ]; then
    printf '{"text":"","alt":"clean","tooltip":"System is up to date","class":"clean"}\n'
    exit 0
fi

names="$(printf '%s\n%s\n' "$official" "$aur" | awk 'NF {print $1}' | head -n 12 | paste -sd '|' -)"
names="${names//|/\\r}"
if [ "$total" -gt 12 ]; then
    names="${names}\\r...and $((total - 12)) more"
fi
names="${names//\"/\\\"}"

printf '{"text":" %s","alt":"pending","tooltip":"%s","class":"pending"}\n' "$total" "$names"
