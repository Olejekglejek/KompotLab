# USB Management Scripts

This directory contains scripts used by the `mount_usbs.yml` task file for managing USB devices on Proxmox hosts.

## Scripts:

- **`detect_usb_storage.sh`** - Detects and lists all USB storage devices
- **`get_usb_block_info.sh`** - Gets detailed block device information for USB devices
- **`get_unmounted_usb_partitions.sh`** - Finds USB partitions that are not currently mounted
- **`mount_usb_partition.sh`** - Mounts a USB partition with appropriate filesystem support
- **`show_mounted_usb_status.sh`** - Shows current USB mount status and disk usage
- **`usb-manager.sh`** - Main USB management script installed to `/usr/local/bin/`

## Usage:

These scripts are automatically deployed and executed by the Ansible playbook. The main management script `usb-manager.sh` is installed permanently on the target system for manual USB management.

### Manual Usage (on target system):
```bash
usb-manager.sh list        # List all USB devices
usb-manager.sh mount-all   # Mount all USB storage devices
usb-manager.sh unmount-all # Unmount all USB devices
usb-manager.sh status      # Show mount status
```
