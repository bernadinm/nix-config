#!/bin/bash
if lsmod | grep -q btusb; then
  echo "Disabling Bluetooth to save power..."
  sudo modprobe -r btusb
  notify-send "Bluetooth Disabled" "Hardware powered off for battery savings"
else
  echo "Enabling Bluetooth..."
  sudo modprobe btusb
  sleep 2
  sudo systemctl restart bluetooth
  notify-send "Bluetooth Enabled" "Hardware powered on and ready"
fi