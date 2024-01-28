#!/usr/bin/env bash

# Get the current battery level
battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')

if [ "$battery_level" -le 5 ]; then
    # Send a notification
    notify-send -u critical "Low Battery" "Your battery is critically low at ${battery_level}%!"
fi
