#!/bin/bash

case "$1" in
  "list")
    echo "=== USB Devices ==="
    lsusb
    echo ""
    echo "=== USB Storage Devices ==="
    lsblk -o NAME,TYPE,SIZE,MOUNTPOINT,FSTYPE,VENDOR,MODEL,TRAN | grep -E "(NAME|usb)" || echo "No USB storage devices found"
    ;;
  "mount-all")
    echo "Mounting all unmounted USB storage devices..."
    for device in $(lsblk -ndo NAME,TRAN | grep usb | awk '{print $1}'); do
      for partition in $(lsblk -ln /dev/$device 2>/dev/null | grep part | awk '{print $1}' || true); do
        mountpoint=$(lsblk -ln /dev/$partition 2>/dev/null | awk '{print $7}' || true)
        if [ -z "$mountpoint" ]; then
          fstype=$(blkid -o value -s TYPE "/dev/$partition" 2>/dev/null || echo "unknown")
          label=$(blkid -o value -s LABEL "/dev/$partition" 2>/dev/null || basename "$partition")
          mount_point="/mnt/usb/$label"
          mkdir -p "$mount_point"
          echo "Mounting /dev/$partition to $mount_point..."
          mount "/dev/$partition" "$mount_point" && echo "Success" || echo "Failed"
        fi
      done
    done
    ;;
  "unmount-all")
    echo "Unmounting all USB devices from /mnt/usb..."
    for mount_point in /mnt/usb/*/; do
      if mountpoint -q "$mount_point" 2>/dev/null; then
        echo "Unmounting $mount_point..."
        umount "$mount_point" && rmdir "$mount_point" && echo "Success" || echo "Failed"
      fi
    done
    ;;
  "status")
    echo "=== USB Mount Status ==="
    mount | grep -E "(usb|/mnt/usb)" || echo "No USB devices mounted"
    echo ""
    if [ -d "/mnt/usb" ]; then
      ls -la /mnt/usb/
    fi
    ;;
  *)
    echo "USB Manager Script"
    echo "Usage: $0 {list|mount-all|unmount-all|status}"
    echo ""
    echo "  list        - List all USB devices and storage"
    echo "  mount-all   - Mount all unmounted USB storage devices"
    echo "  unmount-all - Unmount all USB devices from /mnt/usb"
    echo "  status      - Show current USB mount status"
    ;;
esac
