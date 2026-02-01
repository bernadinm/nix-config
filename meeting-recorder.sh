#!/usr/bin/env bash

# Add debug mode
DEBUG=true

# Check if we have write permission for the recordings directory
RECORDING_DIR="$HOME/Recordings/meetings"
PID_FILE="/tmp/meeting-recorder.pid"
TIMESTAMP_FILE="/tmp/meeting-recorder-timestamp"

# Create recordings directory if it doesn't exist
mkdir -p "$RECORDING_DIR" || {
    echo "Error: Cannot create recording directory $RECORDING_DIR"
    exit 1
}

# Function to log debug messages
debug_log() {
    if [ "$DEBUG" = true ]; then
        echo "DEBUG: $1"
    fi
}

# Function to monitor audio sources and handle switches
monitor_audio_sources() {
    local last_source="$DEFAULT_SOURCE"
    local last_meet_source="$MEET_SOURCE"

    while [ -f "$PID_FILE" ]; do
        # Check current sources
        local current_bluetooth=$(pactl list sources | grep -B 1 "bluez_input.50_C2_75_61_4D_71" | grep "Name:" | cut -d: -f2 | tr -d ' ')
        local current_default=$(pactl get-default-source)
        local current_meet_source="bluez_output.50_C2_75_61_4D_71.1.monitor"

        # If bluetooth becomes available
        if [ -n "$current_bluetooth" ] && [ "$last_source" != "$current_bluetooth" ]; then
            debug_log "Bluetooth microphone reconnected, switching..."
            pactl set-default-source "$current_bluetooth"
            # Restart microphone recording
            kill $(ps -o pid= -p $MIC_PID)
            pw-record --target="$current_bluetooth" "${RECORDING_FILE}_mic.wav" &
            MIC_PID=$!
            echo "$MIC_PID $MEET_PID $MONITOR_PID" > "$PID_FILE"
            last_source="$current_bluetooth"
            notify-send "Recording Update" "Switched to Bluetooth microphone"

        # If bluetooth becomes unavailable
        elif [ -z "$current_bluetooth" ] && [[ "$last_source" == *"bluez"* ]]; then
            debug_log "Bluetooth microphone disconnected, falling back to default..."
            # Restart microphone recording with default source
            kill $(ps -o pid= -p $MIC_PID)
            pw-record --target="$current_default" "${RECORDING_FILE}_mic.wav" &
            MIC_PID=$!
            echo "$MIC_PID $MEET_PID $MONITOR_PID" > "$PID_FILE"
            last_source="$current_default"
            notify-send "Recording Update" "Switched to default microphone"
        fi
        
        # If meeting audio source changes
        if [ "$last_meet_source" != "$current_meet_source" ]; then
            debug_log "Meeting audio source changed, switching..."
            kill $(ps -o pid= -p $MEET_PID)
            parec -d "$current_meet_source" | sox -t raw -r 48000 -b 16 -e signed -c 2 - "${RECORDING_FILE}_meet.wav" &
            MEET_PID=$!
            echo "$MIC_PID $MEET_PID $MONITOR_PID" > "$PID_FILE"
            last_meet_source="$current_meet_source"
        fi

        sleep 2  # Check every 2 seconds
    done
}

# Function to find audio sources
find_sources() {
    echo "Detecting audio sources..."
    
    # Debug: List all available sources
    debug_log "Available audio sources:"
    pactl list sources | grep -E "Name:|Source|bluetooth"
    
    # Specifically look for your bluetooth headset
    BLUETOOTH_MIC=$(pactl list sources | grep -B 1 "bluez_input.50_C2_75_61_4D_71" | grep "Name:" | cut -d: -f2 | tr -d ' ')
    
    if [ -n "$BLUETOOTH_MIC" ]; then
        DEFAULT_SOURCE="$BLUETOOTH_MIC"
        echo "Found Bluetooth microphone: $BLUETOOTH_MIC"
        # Force set bluetooth as default source
        pactl set-default-source "$BLUETOOTH_MIC"
    else
        DEFAULT_SOURCE=$(pactl get-default-source)
        echo "Using default microphone: $DEFAULT_SOURCE"
    fi
    
    # Try to find system audio output (this will capture Meet audio)
    MEET_SOURCE="bluez_output.50_C2_75_61_4D_71.1.monitor"
    echo "Using system audio for meeting: $MEET_SOURCE"
    
    if [ -z "$DEFAULT_SOURCE" ]; then
        echo "No audio source found!"
        exit 1
    fi
    
    # Test directory permissions
    debug_log "Testing directory permissions for: $RECORDING_DIR"
    if [ ! -w "$RECORDING_DIR" ]; then
        echo "Error: Cannot write to $RECORDING_DIR"
        ls -la "$RECORDING_DIR"
        exit 1
    fi
    
    # Debug: Show final audio configuration
    debug_log "Final audio configuration:"
    debug_log "Input source: $DEFAULT_SOURCE"
    debug_log "Meeting source: $MEET_SOURCE"
    debug_log "Default source: $(pactl get-default-source)"
}

# Function to start recording
start_recording() {
    # Generate timestamp and save it
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    RECORDING_FILE="$RECORDING_DIR/meeting_$TIMESTAMP"
    echo "$RECORDING_FILE" > "$TIMESTAMP_FILE"
    
    find_sources
    
    echo "Starting recording..."
    echo "Recording to: $RECORDING_FILE"
    
    # Record microphone/bluetooth with error checking
    debug_log "Starting microphone recording..."
    pw-record --target="$DEFAULT_SOURCE" "${RECORDING_FILE}_mic.wav" &
    MIC_PID=$!
    debug_log "Microphone recording PID: $MIC_PID"
    
    # Record system audio with error checking
    debug_log "Starting system audio recording..."
    parec -d "$MEET_SOURCE" | sox -t raw -r 48000 -b 16 -e signed -c 2 - "${RECORDING_FILE}_meet.wav" &
    MEET_PID=$!
    debug_log "Meeting recording PID: $MEET_PID"
    
    # Start the audio source monitor in the background
    monitor_audio_sources &
    MONITOR_PID=$!
    debug_log "Started audio source monitor (PID: $MONITOR_PID)"
    
    # Save PIDs to file
    echo "$MIC_PID $MEET_PID $MONITOR_PID" > "$PID_FILE"
    
    echo "Recording started!"
    echo "Input source (your mic): $DEFAULT_SOURCE"
    echo "Meeting audio source: $MEET_SOURCE"
    echo "PIDs: Mic=$MIC_PID Meet=$MEET_PID Monitor=$MONITOR_PID"
    echo "Press Ctrl+C or run './meeting-recorder.sh stop' to stop recording"
    
    notify-send "Meeting Recording Started" "Recording from: ${DEFAULT_SOURCE##*/}" -i audio-input-microphone
}

# Function to stop recording
stop_recording() {
    if [ -f "$PID_FILE" ] && [ -f "$TIMESTAMP_FILE" ]; then
        echo "Stopping recording..."
        read MIC_PID MEET_PID MONITOR_PID < "$PID_FILE"
        RECORDING_FILE=$(cat "$TIMESTAMP_FILE")
        
        debug_log "Stopping processes: MIC_PID=$MIC_PID MEET_PID=$MEET_PID MONITOR_PID=$MONITOR_PID"
        debug_log "Recording file: $RECORDING_FILE"
        
        # Kill all processes
        kill $MONITOR_PID 2>/dev/null
        pkill -P $MIC_PID 2>/dev/null
        kill $MIC_PID 2>/dev/null
        if [ -n "$MEET_PID" ]; then
            pkill -P $MEET_PID 2>/dev/null
            kill $MEET_PID 2>/dev/null
        fi
        
        rm "$PID_FILE" "$TIMESTAMP_FILE"
        
        # Wait a moment for files to be written
        sleep 2
        
        # Debug directory contents
        debug_log "Recording directory contents:"
        ls -la "$RECORDING_DIR"
        
        # Check if files exist and show their sizes
        if [ -f "${RECORDING_FILE}_mic.wav" ]; then
            echo "Microphone recording saved:"
            ls -lh "${RECORDING_FILE}_mic.wav"
        else
            echo "Warning: Microphone recording file not found!"
            debug_log "Expected file: ${RECORDING_FILE}_mic.wav"
        fi
        
        if [ -f "${RECORDING_FILE}_meet.wav" ]; then
            echo "Meeting recording saved:"
            ls -lh "${RECORDING_FILE}_meet.wav"
            
            # Combine audio files with adjusted volumes
            echo "Combining audio files..."
            ffmpeg -i "${RECORDING_FILE}_mic.wav" -i "${RECORDING_FILE}_meet.wav" \
                   -filter_complex "[0:a]volume=1.0[a1];[1:a]volume=0.8[a2];[a1][a2]amix=inputs=2:duration=longest" \
                   "${RECORDING_FILE}_combined.wav" -y 2>/dev/null
            
            echo "Combined recording saved:"
            ls -lh "${RECORDING_FILE}_combined.wav"
        fi
        
        notify-send "Meeting Recording Stopped" "Files saved in: ${RECORDING_DIR}" -i audio-input-microphone
    else
        echo "No active recording found."
    fi
}

# Function to show status
show_status() {
    if [ -f "$PID_FILE" ] && [ -f "$TIMESTAMP_FILE" ]; then
        read MIC_PID MEET_PID MONITOR_PID < "$PID_FILE"
        RECORDING_FILE=$(cat "$TIMESTAMP_FILE")
        
        echo "Recording is active:"
        echo "Microphone recording PID: $MIC_PID"
        [ -n "$MEET_PID" ] && echo "Meeting audio recording PID: $MEET_PID"
        [ -n "$MONITOR_PID" ] && echo "Audio monitor PID: $MONITOR_PID"
        
        # Show current audio sources
        echo "Current audio sources:"
        echo "Input: $(pactl get-default-source)"
        echo "Output monitor: $(pactl get-default-sink).monitor"
        
        # Show recording duration
        if [ -f "${RECORDING_FILE}_mic.wav" ]; then
            DURATION=$(date -u -d @$(($(date +%s) - $(stat -c %Y "${RECORDING_FILE}_mic.wav"))) +%H:%M:%S)
            echo "Recording duration: $DURATION"
            echo "Recording file: $RECORDING_FILE"
        fi
    else
        echo "No active recording."
    fi
}

# Function to list recordings
list_recordings() {
    echo "Available recordings in $RECORDING_DIR:"
    if [ -d "$RECORDING_DIR" ]; then
        ls -lh "$RECORDING_DIR" | grep -v '^total'
    else
        echo "No recordings directory found."
    fi
}

# Function to play a recording
play_recording() {
    if [ -n "$1" ]; then
        RECORDING="$1"
    else
        # Get most recent recording
        RECORDING=$(ls -t "$RECORDING_DIR"/*.wav | head -n 1)
    fi
    
    if [ -f "$RECORDING" ]; then
        echo "Playing: $RECORDING"
        vlc "$RECORDING" &
    else
        echo "Recording not found: $RECORDING"
        echo "Available recordings:"
        list_recordings
    fi
}

# Handle command line arguments
case "$1" in
    start)
        start_recording
        ;;
    stop)
        stop_recording
        ;;
    status)
        show_status
        ;;
    list)
        list_recordings
        ;;
    play)
        if [ -n "$2" ]; then
            play_recording "$2"
        else
            # Play most recent recording if no file specified
            play_recording
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status|list|play}"
        echo "  start         - Start recording"
        echo "  stop          - Stop recording"
        echo "  status        - Show recording status"
        echo "  list          - List available recordings"
        echo "  play <file>   - Play a recording"
        exit 1
        ;;
esac