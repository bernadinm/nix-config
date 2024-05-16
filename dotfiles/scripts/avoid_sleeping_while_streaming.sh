#!/usr/bin/env bash

# Function to check if there are active uncorked audio streams in PulseAudio
check_audio_pulseaudio() {
    # Check if any sink input is not corked
    pactl list sink-inputs | grep -q 'Corked: no'
}

# Detect if PulseAudio or PipeWire is being used
if command -v pactl &> /dev/null; then
    CHECK_AUDIO="check_audio_pulseaudio"
else
    echo "PulseAudio not detected. Exiting."
    exit 1
fi

# Main loop to monitor audio activity and manage caffeine
CAFE_PID=0
while true; do
    if $CHECK_AUDIO; then
        if [ $CAFE_PID -eq 0 ] || ! kill -0 $CAFE_PID 2> /dev/null; then
            # Prevent sleep by starting caffeine if not already running
            caffeine &
            CAFE_PID=$!
        fi
    else
        if [ $CAFE_PID -ne 0 ] && kill -0 $CAFE_PID 2> /dev/null; then
            # Kill caffeine process if it's running
            kill $CAFE_PID
            CAFE_PID=0
        fi
    fi
    sleep 10 # Check every 10 seconds
done
