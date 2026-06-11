#!/usr/bin/env bash
# Double-tap airplane mode toggle
# Requires two presses within 500ms to activate
STAMP_FILE="/tmp/.airplane-key-last-press"
WINDOW_MS=500

now_ms=$(date +%s%N | cut -b1-13)

if [[ -f "$STAMP_FILE" ]]; then
    last_ms=$(cat "$STAMP_FILE")
    diff=$((now_ms - last_ms))

    if [[ $diff -le $WINDOW_MS ]]; then
        # Double tap detected — toggle airplane mode
        rm -f "$STAMP_FILE"
        wifi_state=$(nmcli radio wifi)
        if [[ "$wifi_state" == "enabled" ]]; then
            nmcli radio wifi off
            notify-send -u critical "Airplane Mode" "WiFi disabled"
        else
            nmcli radio wifi on
            notify-send "Airplane Mode" "WiFi enabled"
        fi
        exit 0
    fi
fi

# First tap — record timestamp
echo "$now_ms" > "$STAMP_FILE"
