#!/usr/bin/env bash

# Check if AC power is connected
ac_power=$(acpi -a | grep -P -o 'on-line')

# Only proceed if AC power is not connected
if [ -z "$ac_power" ]; then
    # Get the current battery level
    battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')

    # Notify only if the battery level is less than 15%
    if [ "$battery_level" -lt 15 ]; then
        # Send a notification
        paplay ~/.modern_alert.wav; notify-send -u critical -t 30000 "Low Battery" "Your battery is critically low at ${battery_level}%!"
    fi
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

