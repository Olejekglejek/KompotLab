#!/bin/bash
echo "=== Currently mounted USB devices ==="
mount | grep -E "(usb|/mnt/usb)" || echo "No USB devices currently mounted via standard mount points"
echo ""
echo "=== All mounts in /mnt/usb ==="
if [ -d "/mnt/usb" ]; then
  ls -la /mnt/usb/ || echo "No mounts found in /mnt/usb"
  for mount_point in /mnt/usb/*/; do
    if mountpoint -q "$mount_point" 2>/dev/null; then
      echo "Mounted: $mount_point"
      df -h "$mount_point"
    fi
  done
else
  echo "/mnt/usb directory does not exist"
fi
