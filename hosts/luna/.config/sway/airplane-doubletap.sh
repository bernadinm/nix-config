#!/bin/bash
# Airplane mode toggle with double-tap protection
# Prevents accidental airplane mode activation

LOCK_FILE="/tmp/airplane-doubletap-lock"
TIMEOUT=2  # seconds to wait for second tap

if [ -f "$LOCK_FILE" ]; then
    # Second tap within timeout - toggle airplane mode
    rm "$LOCK_FILE"

    # Check current state and toggle
    if nmcli radio wifi | grep -q enabled; then
        nmcli radio wifi off
        notify-send "Airplane Mode" "WiFi disabled"
    else
        nmcli radio wifi on
        notify-send "Airplane Mode" "WiFi enabled"
    fi
else
    # First tap - create lock file and wait
    touch "$LOCK_FILE"
    notify-send "Airplane Mode" "Press again within ${TIMEOUT}s to toggle"

    # Remove lock file after timeout
    (sleep $TIMEOUT && rm -f "$LOCK_FILE") &
fi
