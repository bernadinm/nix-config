#!/bin/bash
# Voice Note - Record audio and transcribe with Whisper
# Toggle recording with keybinding, auto-transcribes when stopped

RECORDING_FILE="/tmp/voice_note_recording.wav"
PID_FILE="/tmp/voice_note_pid"
TRANSCRIPT_DIR="$HOME/Documents/voice_notes"

mkdir -p "$TRANSCRIPT_DIR"

if [ -f "$PID_FILE" ]; then
    # Stop recording
    PID=$(cat "$PID_FILE")
    kill "$PID" 2>/dev/null
    rm "$PID_FILE"

    notify-send "Voice Note" "Recording stopped. Transcribing..."

    # Transcribe with whisper
    TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
    TRANSCRIPT_FILE="$TRANSCRIPT_DIR/transcript_$TIMESTAMP.txt"

    # Run whisper and get transcript
    whisper "$RECORDING_FILE" --model tiny --language en --output_format txt --output_dir /tmp 2>/dev/null

    if [ -f "/tmp/voice_note_recording.txt" ]; then
        TRANSCRIPT=$(cat /tmp/voice_note_recording.txt)

        # Save to file
        echo "$TRANSCRIPT" > "$TRANSCRIPT_FILE"

        # Copy to clipboard
        echo "$TRANSCRIPT" | wl-copy

        notify-send "Voice Note" "Transcribed and copied to clipboard"

        # Clean up
        rm -f /tmp/voice_note_recording.txt
    else
        notify-send "Voice Note" "Transcription failed"
    fi

    rm -f "$RECORDING_FILE"
else
    # Start recording
    notify-send "Voice Note" "Recording started... Press again to stop"

    # Record audio using ffmpeg (works with PipeWire/PulseAudio)
    ffmpeg -f pulse -i default -ar 16000 -ac 1 "$RECORDING_FILE" -y 2>/dev/null &
    echo $! > "$PID_FILE"
fi
