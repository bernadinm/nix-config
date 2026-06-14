#!/usr/bin/env bash

# Check if AC power is connected
ac_power=$(acpi -a | grep -P -o 'on-line')

# Only proceed if AC power is not connected
if [ -z "$ac_power" ]; then
    # Get the current battery level
    battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')

    # CRITICAL: < 8% - hibernate countdown
    if [ "$battery_level" -lt 8 ]; then
        # 30 second countdown before hibernate
        for i in $(seq 30 -1 1); do
            # Check if charger was plugged in
            ac_power=$(acpi -a | grep -P -o 'on-line')
            if [ -n "$ac_power" ]; then
                notify-send -u normal -t 3000 -h string:x-canonical-private-synchronous:battery "Charger Connected" "Hibernate cancelled."
                exit 0
            fi

            # Update countdown notification
            notify-send -u critical -t 1100 -h string:x-canonical-private-synchronous:battery \
                "⚠️ HIBERNATING IN ${i}s ⚠️" \
                "Battery at ${battery_level}%!\nPlug in charger to cancel."

            sleep 1
        done

        # Final check before hibernate
        ac_power=$(acpi -a | grep -P -o 'on-line')
        if [ -z "$ac_power" ]; then
            notify-send -u critical -t 2000 "Hibernating now..." "Battery critically low"
            sleep 1
            systemctl hibernate
        fi
    # Warning: < 15% - just notify
    elif [ "$battery_level" -lt 15 ]; then
        paplay ~/.modern_alert.wav
        notify-send -u normal -t 30000 -h string:x-canonical-private-synchronous:battery "Low Battery" "Your battery is critically low at ${battery_level}%!"
    fi
else
    # If AC is connected, dismiss any lingering low battery notifications
    makoctl dismiss --all
fi

# Sound effect generated with the following script
# import numpy as np

# def generate_tone(frequency, duration, volume=0.5, fade_duration=0.05):
#     """Generate a sine wave tone with a specified frequency, duration, and volume."""
#     t = np.linspace(0, duration, int(samplerate * duration), endpoint=False)
#     tone = np.sin(2 * np.pi * frequency * t) * volume
#     # Apply fade in and fade out
#     fade_in = np.linspace(0, 1, int(samplerate * fade_duration))
#     fade_out = np.linspace(1, 0, int(samplerate * fade_duration))
#     tone[:len(fade_in)] *= fade_in
#     tone[-len(fade_out):] *= fade_out
#     return tone

# # Parameters for a more complex, modern-sounding notification
# samplerate = 44100  # Sample rate in Hz
# tones = [
#     {"frequency": 880, "duration": 0.1, "volume": 0.5},  # Higher pitch A5
#     {"frequency": 1760, "duration": 0.1, "volume": 0.3},  # Even higher pitch A6
# ]
# silence_duration = 0.05  # Duration of silence between tones

# # Generate the sound
# sound = np.array([])
# for tone in tones:
#     sound = np.concatenate([sound, generate_tone(**tone)])
#     sound = np.concatenate([sound, np.zeros(int(samplerate * silence_duration))])  # Add silence

# # Ensure the sound is within 16-bit range
# sound = np.int16(sound * 32767)

# # Save to a WAV file
# modern_wav_file = "/mnt/data/modern_notification_sound.wav"
# write(modern_wav_file, samplerate, sound)

# modern_wav_file

