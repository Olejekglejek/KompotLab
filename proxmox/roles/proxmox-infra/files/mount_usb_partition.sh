#!/bin/bash
# Mount a USB partition with appropriate filesystem support
# Usage: mount_usb_partition.sh <partition_device>

partition="$1"
if [ -z "$partition" ] || [ "$partition" = "No unmounted USB partitions found" ]; then
  exit 0
fi

# Get filesystem type
fstype=$(blkid -o value -s TYPE "$partition" 2>/dev/null || echo "unknown")
# Get partition label or use device name
label=$(blkid -o value -s LABEL "$partition" 2>/dev/null || basename "$partition")

# Create mount point
mount_point="/mnt/usb/$label"
mkdir -p "$mount_point"

echo "Mounting $partition ($fstype) to $mount_point"

# Mount with appropriate options based on filesystem type and available tools
case "$fstype" in
  "vfat"|"fat32"|"fat16")
    mount -t vfat "$partition" "$mount_point" -o defaults,uid=0,gid=0,umask=022
    ;;
  "ntfs")
    # Try ntfs-3g first, fallback to ntfs, then generic mount
    if command -v mount.ntfs-3g >/dev/null 2>&1; then
      mount -t ntfs-3g "$partition" "$mount_point" -o defaults,uid=0,gid=0,umask=022
    elif command -v mount.ntfs >/dev/null 2>&1; then
      mount -t ntfs "$partition" "$mount_point" -o defaults,uid=0,gid=0,umask=022
    else
      echo "Warning: No NTFS support available, trying generic mount"
      mount "$partition" "$mount_point"
    fi
    ;;
  "ext2"|"ext3"|"ext4")
    mount -t "$fstype" "$partition" "$mount_point"
    ;;
  "exfat")
    # Try exfat-fuse first, then generic mount
    if command -v mount.exfat-fuse >/dev/null 2>&1; then
      mount -t exfat "$partition" "$mount_point" -o defaults,uid=0,gid=0,umask=022
    else
      echo "Warning: No ExFAT support available, trying generic mount"
      mount "$partition" "$mount_point"
    fi
    ;;
  *)
    echo "Unknown filesystem type: $fstype, trying generic mount"
    mount "$partition" "$mount_point"
    ;;
esac

if [ $? -eq 0 ]; then
  echo "Successfully mounted $partition to $mount_point"
  echo "$partition $mount_point $fstype defaults 0 0" >> /tmp/usb_mounts_temp
else
  echo "Failed to mount $partition"
  rmdir "$mount_point" 2>/dev/null || true
fi
