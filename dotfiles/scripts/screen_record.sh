#!/run/current-system/sw/bin/bash

# TODO(bernadinm): fix this, it stays running and doesn't properly end some times
set -x
STATE_FILE="/tmp/ssr_state"
COMMAND_PIPE="/tmp/ssr_command_pipe"

# Ensure the command pipe exists
if [ ! -p "$COMMAND_PIPE" ]; then
    mkfifo "$COMMAND_PIPE"
fi

# Function to ensure SSR is running and set up to read from the command pipe
ensure_ssr_running() {
    if ! pgrep -x "simplescreenrecorder" > /dev/null; then
        # Start SimpleScreenRecorder and ensure it reads from the command pipe
        simplescreenrecorder --start-hidden < "$COMMAND_PIPE" &
        echo "SimpleScreenRecorder started."
        notify-send -t 5000 "SimpleScreenRecorder (SSR)" "SSR was not running, started now."
    fi
}

# Function to start recording
start_recording() {
    echo "record-start" > "$COMMAND_PIPE"
    echo "recording" > "$STATE_FILE"
    notify-send -t 1000 "SimpleScreenRecorder (SSR)" "Recording started."
}

# Function to stop recording
stop_recording() {
    echo "record-save" > "$COMMAND_PIPE"
    rm "$STATE_FILE"
    notify-send -t 5000 "SimpleScreenRecorder (SSR)" "Recording saved."
}

# Ensure SSR is running
ensure_ssr_running

# Toggle recording based on current state
if [ -f "$STATE_FILE" ]; then
    stop_recording
else
    start_recording
fi
