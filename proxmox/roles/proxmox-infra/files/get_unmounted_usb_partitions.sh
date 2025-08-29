#!/bin/bash
# Find USB partitions that are not already mounted
unmounted_partitions=""
for device in $(lsblk -ndo NAME,TRAN | grep usb | awk '{print $1}'); do
  # Check all partitions of this device
  for partition in $(lsblk -ln /dev/$device 2>/dev/null | grep part | awk '{print $1}' || true); do
    mountpoint=$(lsblk -ln /dev/$partition 2>/dev/null | awk '{print $7}' || true)
    if [ -z "$mountpoint" ] || [ "$mountpoint" = "" ]; then
      fstype=$(lsblk -ln /dev/$partition 2>/dev/null | awk '{print $2}' || true)
      if [ ! -z "$fstype" ] && [ "$fstype" != "" ]; then
        unmounted_partitions="$unmounted_partitions /dev/$partition"
      fi
    fi
  done
done
echo "$unmounted_partitions" | tr ' ' '\n' | grep -v '^$' || echo "No unmounted USB partitions found"
