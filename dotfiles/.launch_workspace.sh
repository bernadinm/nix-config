#!/bin/bash

# Workspace 1: Code
i3-msg 'workspace 1: Code'
i3-msg 'exec termite'  # Replace 'termite' if you use a different terminal
i3-msg 'exec termite'  # Replace 'termite' if you use a different terminal
i3-msg 'split v'
i3-msg 'exec termite'  # Replace 'termite' if you use a different terminal

# Workspace 2: Browser
i3-msg 'workspace 2: Browser'
i3-msg 'exec firefox --new-window https://mail.google.com'  # Gmail
i3-msg 'split h'
i3-msg 'exec firefox --new-window https://calendar.google.com'  # Google Calendar on top right
i3-msg 'split v'
i3-msg 'exec firefox --new-window https://drive.google.com'  # Google Drive on bottom right

# Workspace 3: Logseq and ChatGPT
i3-msg 'workspace 3: Productivity'
i3-msg 'exec termite -e logseq'  # Replace with the command to start Logseq
i3-msg 'split h'
i3-msg 'exec firefox --new-window https://chat.openai.com'  # ChatGPT

# Workspace 4: Communication
i3-msg 'workspace 4: Comms'
i3-msg 'exec firefox --new-window https://messages.google.com'  # Google Messages
i3-msg 'split h'
i3-msg 'exec firefox --new-window https://web.whatsapp.com'  # WhatsApp

# Workspace 5: Proton Suite
i3-msg 'workspace 5: Proton'
i3-msg 'exec firefox --new-window https://mail.protonmail.com'  # ProtonMail
i3-msg 'split h'
i3-msg 'exec firefox --new-window https://calendar.protonmail.com'  # Proton Calendar
i3-msg 'split h'
i3-msg 'exec firefox --new-window https://drive.protonmail.com'  # Proton Drive

# Workspace 6: Social and Messaging
i3-msg 'workspace 6: Social'
i3-msg 'exec firefox --new-window https://instagram.com'  # Instagram
i3-msg 'split h'
i3-msg 'exec slack'  # Slack on top right
i3-msg 'split v'
i3-msg 'exec discord'  # Discord on bottom right

# Workspace 9: Music
i3-msg 'workspace 9: Music'
i3-msg 'exec firefox --new-window https://play.google.com/music'  # Google Play Music

# Replace the placeholder commands with the actual commands for your applications.
