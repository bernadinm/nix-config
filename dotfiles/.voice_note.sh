#!/bin/bash
# Voice Note - Record audio and transcribe with Groq Whisper API
# Toggle recording with keybinding, auto-transcribes when stopped
# Shows recording indicator in waybar (signal RTMIN+9)

RECORDING_FILE="/tmp/voice_note_recording.wav"
PID_FILE="/tmp/voice_note_pid"
TRANSCRIPT_DIR="$HOME/Documents/voice_notes"
GROQ_TOOL="$HOME/Documents/coding/python/groq-whisper-v2-stt"

mkdir -p "$TRANSCRIPT_DIR"

# Update waybar indicator
update_waybar() {
    pkill -RTMIN+9 waybar 2>/dev/null
}

if [ -f "$PID_FILE" ]; then
    # Stop recording
    PID=$(cat "$PID_FILE")
    kill "$PID" 2>/dev/null
    rm "$PID_FILE"
    update_waybar

    notify-send "Voice Note" "⏹️ Recording stopped. Transcribing..."

    # Check if recording file exists and has content
    if [ ! -f "$RECORDING_FILE" ] || [ ! -s "$RECORDING_FILE" ]; then
        notify-send -u critical "Voice Note" "No audio recorded!"
        exit 1
    fi

    TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
    TRANSCRIPT_FILE="$TRANSCRIPT_DIR/transcript_$TIMESTAMP.txt"

    # Use Groq Whisper for transcription (fast cloud API)
    cd "$GROQ_TOOL"
    source venv/bin/activate

    RESULT=$(python main.py "$RECORDING_FILE" -o "$TRANSCRIPT_FILE" -q 2>&1)
    EXIT_CODE=$?

    deactivate

    if [ $EXIT_CODE -eq 0 ] && [ -f "$TRANSCRIPT_FILE" ]; then
        # Copy transcript to clipboard
        cat "$TRANSCRIPT_FILE" | wl-copy

        # Show preview in notification
        PREVIEW=$(head -c 100 "$TRANSCRIPT_FILE")
        notify-send "Voice Note ✓" "Copied to clipboard:\n$PREVIEW..."
    else
        notify-send -u critical "Voice Note" "Transcription failed:\n$RESULT"
    fi

    rm -f "$RECORDING_FILE"
else
    # Start recording
    notify-send "Voice Note" "🎙️ Recording... Press Super+V to stop"

    # Record audio using ffmpeg (works with PipeWire/PulseAudio)
    ffmpeg -f pulse -i default -ar 16000 -ac 1 "$RECORDING_FILE" -y 2>/dev/null &
    echo $! > "$PID_FILE"
    update_waybar
fi
