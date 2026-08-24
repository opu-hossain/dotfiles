#!/usr/bin/env bash
# Self-looping module: waybar spawns this once (no "interval" set) and
# reads one new JSON line every time we print one.

SYSFS_NET="${WAYBAR_NETSPEED_SYSFS:-/sys/class/net}"
POLL_SECS=2

ICON_ETH=$'\U000f0200'
ICON_WIFI=$'\uf1eb'
ICON_OFFLINE=$'\U000f092d'
ICON_UP=$'\uf062'
ICON_DOWN=$'\uf063'

get_iface() {
    ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="dev") print $(i+1)}'
}

human() {
    local bytes=$1
    if [ "$bytes" -ge 1048576 ]; then
        awk -v b="$bytes" 'BEGIN{printf "%.1fM", b/1048576}'
    elif [ "$bytes" -ge 1024 ]; then
        awk -v b="$bytes" 'BEGIN{printf "%.1fK", b/1024}'
    else
        printf '%dB' "$bytes"
    fi
}

prev_rx=""
prev_tx=""
prev_iface=""

while true; do
    iface="$(get_iface)"

    if [ -z "$iface" ]; then
        printf '{"text":"%s Offline","tooltip":"No active connection","class":"disconnected"}\n' "$ICON_OFFLINE"
        prev_iface=""
        prev_rx=""
        prev_tx=""
        sleep "$POLL_SECS"
        continue
    fi

    rx="$(cat "$SYSFS_NET/$iface/statistics/rx_bytes" 2>/dev/null)"
    tx="$(cat "$SYSFS_NET/$iface/statistics/tx_bytes" 2>/dev/null)"

    if [ "$iface" != "$prev_iface" ] || [ -z "$prev_rx" ] || [ -z "$prev_tx" ]; then
        # First sample since startup or interface change - nothing to diff yet
        prev_iface="$iface"
        prev_rx="$rx"
        prev_tx="$tx"
        sleep "$POLL_SECS"
        continue
    fi

    down=$(( (rx - prev_rx) / POLL_SECS ))
    up=$(( (tx - prev_tx) / POLL_SECS ))
    [ "$down" -lt 0 ] && down=0
    [ "$up" -lt 0 ] && up=0

    prev_rx="$rx"
    prev_tx="$tx"
    prev_iface="$iface"

    if [ -d "$SYSFS_NET/$iface/wireless" ]; then
        kind="wifi"
        icon="$ICON_WIFI"
    else
        kind="ethernet"
        icon="$ICON_ETH"
    fi

    ip_addr="$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1)"
    [ -z "$ip_addr" ] && ip_addr="no IPv4"

    text="${icon}  ${ICON_UP} $(human "$up")/s  ${ICON_DOWN} $(human "$down")/s"
    tooltip="${iface} (${kind})\r${ip_addr}"

    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$kind"

    sleep "$POLL_SECS"
done
