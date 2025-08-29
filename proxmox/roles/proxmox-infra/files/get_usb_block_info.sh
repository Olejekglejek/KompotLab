#!/bin/bash
# Get all block devices that are USB connected
for device in $(lsblk -ndo NAME,TRAN | grep usb | awk '{print $1}'); do
  echo "=== Device: /dev/$device ==="
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,LABEL,UUID /dev/$device || true
  echo "---"
done
