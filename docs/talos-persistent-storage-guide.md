# Talos OS Persistent Storage with USB Devices

This guide explains how to configure and manage persistent storage in Talos OS using USB devices mounted on your Proxmox server.

## Overview

In your setup, you have:
- A USB stick mounted on your Proxmox server
- Talos OS running in VMs on Proxmox
- Need for persistent storage for Kubernetes applications

## Architecture Options

### Option 1: USB Passthrough to Talos VMs (Recommended)

Pass the USB device directly to your Talos worker nodes and configure it as persistent storage.

#### Step 1: Configure USB Passthrough in Proxmox

1. **Identify your USB device on Proxmox:**
   ```bash
   lsusb
   lsblk
   ```

2. **Add USB device to VM configuration:**
   - Edit VM configuration: `/etc/pve/qemu-server/{VMID}.conf`
   - Add USB device: `usb0: host=1234:5678` (replace with your USB vendor:product ID)

3. **Hot-plug USB device:**
   ```bash
   qm monitor {VMID}
   (qemu) info usbhost
   (qemu) device_add usb-host,hostbus=1,hostaddr=2,id=usb0
   ```

#### Step 2: Configure Talos Machine Config

Update your `worker.yaml` to include the USB device:

```yaml
machine:
  disks:
    - device: /dev/sdb  # Your USB device (adjust device name)
      partitions:
        - mountpoint: /var/mnt/usb-storage
          size: 100%  # Use entire USB device
```

#### Step 3: Apply Configuration

```bash
# Apply the updated configuration
talosctl apply-config --insecure --nodes $WORKER_IP --file worker.yaml
```


## Best Practices

### 1. Backup Strategy
- Regular backups of USB content to external storage
- Kubernetes-native backup tools (Velero, etc.)

### 2. Monitoring
- Monitor USB device health and space usage
- Set up alerts for storage capacity

### 3. Security
- Use proper filesystem permissions
- Consider encryption for sensitive data

### 4. High Availability
- Consider RAID or replication if using multiple USB devices
- Network storage provides better HA than local storage

## Troubleshooting

### Common Issues

1. **USB device not detected in Talos:**
   - Check Proxmox USB passthrough configuration
   - Verify device is not mounted on Proxmox host

2. **Permission issues:**
   - Ensure proper filesystem permissions on mount points
   - Check Kubernetes service account permissions

3. **Storage not available:**
   - Verify mount points exist and are accessible
   - Check storage class configuration

### Useful Commands

```bash
# Check disk status in Talos
talosctl -n $WORKER_IP get disks

# Check mount points
talosctl -n $WORKER_IP get mounts

# Check Kubernetes storage
kubectl get pv,pvc,sc
kubectl describe pv <pv-name>

# Debug storage issues
kubectl get events --field-selector reason=FailedMount
```
