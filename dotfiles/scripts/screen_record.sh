#!/run/current-system/sw/bin/bash

# Check if SimpleScreenRecorder is running
if pgrep -f 'simplescreenrecorder --start-hidden --start-recording' > /dev/null
then
    # If it is running, send the stop signal and show a notification
    pkill -f 'simplescreenrecorder --start-hidden --start-recording'
    notify-send "SimpleScreenRecorder" "Recording stopped."
else
    # If it is not running, start it with the specified settings and show a notification
    notify-send -t 1000 "SimpleScreenRecorder" "Recording started."
    simplescreenrecorder --start-hidden --start-recording 
fi
