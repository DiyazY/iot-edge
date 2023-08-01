#!/bin/bash

# List all the disk devices
lsblk -p -o NAME,SIZE,TYPE,MOUNTPOINT

read -p "Please enter the device file for the USB (e.g., /dev/sdb): " USB_STICK_DEV

read -p "Are you sure you want to format $USB_STICK_DEV? All data will be lost. [y/N]: " yn
case $yn in
    [Yy]* ) ;;
    * ) echo "Aborting."; return;;
esac

sudo umount "$USB_STICK_DEV"* || true

# format using the FAT32 (`-F 32`) format and name (`-n`) the volume 'CIDATA' (`-I` for ignoring safety checks)
sudo mkfs.vfat -I -F 32 -n 'CIDATA' $USB_STICK_DEV

mkdir /tmp/cidata
sudo mount $USB_STICK_DEV /tmp/cidata

cd /tmp/cidata
touch meta-data

# TODO: contunue here
