#!/bin/bash
# Hyprland Workspace Restoration Script
# Auto-launches your preferred apps on designated workspaces

# Wait for Hyprland to fully start
sleep 2

# Workspace 1: Terminal/Coding
hyprctl dispatch workspace 1
alacritty &
sleep 0.5

# Workspace 2: Browser
hyprctl dispatch workspace 2
firefox &
sleep 1

# Workspace 3: Communications (optional - uncomment what you use)
# hyprctl dispatch workspace 3
# sh ~/.launch_whatsapp.sh &
# slack &
# sleep 1

# Workspace 4: Productivity
hyprctl dispatch workspace 4
sh ~/.launch_notion.sh &
sleep 0.5
sh ~/.launch_logseq.sh &
sleep 1

# Workspace 5: Email (optional - uncomment what you use)
# hyprctl dispatch workspace 5
# sh ~/.launch_gmail.sh &
# sh ~/.launch_protonmail.sh &
# sleep 1

# Workspace 6: Music/Media (optional)
# hyprctl dispatch workspace 6
# sh ~/.launch_music.sh &
# spotify &

# Return to workspace 1 (terminal)
sleep 1
hyprctl dispatch workspace 1

echo "Workspace layout restored!"
