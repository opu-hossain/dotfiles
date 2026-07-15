#!/usr/bin/env bash
INTERFACE="enp34s0"
RX_FILE="/sys/class/net/$INTERFACE/statistics/rx_bytes"
TX_FILE="/sys/class/net/$INTERFACE/statistics/tx_bytes"

format_speed() {
    local bytes=$1
    if (( bytes > 1048576 )); then
        awk -v b="$bytes" 'BEGIN { printf "%.1f MB/s", b/1048576 }'
    else
        awk -v b="$bytes" 'BEGIN { printf "%.0f KB/s", b/1024 }'
    fi
}

[ -f "$RX_FILE" ] || { echo '{"text":"no link","class":"disconnected"}'; exit 0; }

prev_rx=$(cat "$RX_FILE")
prev_tx=$(cat "$TX_FILE")

while true; do
    sleep 1
    rx=$(cat "$RX_FILE")
    tx=$(cat "$TX_FILE")
    down=$(format_speed $((rx - prev_rx)))
    up=$(format_speed $((tx - prev_tx)))
    prev_rx=$rx
    prev_tx=$tx
    echo "{\"text\": \"↓ $down  ↑ $up\", \"tooltip\": \"Down: $down | Up: $up\", \"class\": \"connected\"}"
done
