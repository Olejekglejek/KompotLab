#!/bin/bash
# Find all USB storage devices
lsblk -o NAME,TYPE,SIZE,MOUNTPOINT,FSTYPE,VENDOR,MODEL,TRAN | grep usb || echo "No USB storage devices found"
