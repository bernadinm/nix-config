#!/bin/bash
# Sway Workspace Restoration Script
# Auto-launches your preferred apps on designated workspaces

# Wait for Sway to fully start
sleep 2

# Workspace 1: Terminal/Coding
swaymsg workspace 1
alacritty &
sleep 0.5

# Workspace 2: Browser
swaymsg workspace 2
firefox &
sleep 1

# Workspace 3: Communications (optional - uncomment what you use)
# swaymsg workspace 3
# sh ~/.launch_whatsapp.sh &
# slack &
# sleep 1

# Workspace 4: Productivity
swaymsg workspace 4
sh ~/.launch_notion.sh &
sleep 0.5
sh ~/.launch_logseq.sh &
sleep 1

# Workspace 5: Email (optional - uncomment what you use)
# swaymsg workspace 5
# sh ~/.launch_gmail.sh &
# sh ~/.launch_protonmail.sh &
# sleep 1

# Workspace 6: Music/Media (optional)
# swaymsg workspace 6
# sh ~/.launch_music.sh &
# spotify &

# Return to workspace 1 (terminal)
sleep 1
swaymsg workspace 1

echo "Workspace layout restored!"
