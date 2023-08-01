#!/bin/bash

sudo su -
export IMAGE_URL="https://releases.ubuntu.com/jammy/ubuntu-22.04.2-live-server-amd64.iso"
export ORIG_ISO="ubuntu-22.04.2-live-server-amd64.iso"

# Check if the image file already exists
if [ ! -f "$ORIG_ISO" ]; then
    # If the file does not exist, download the image
    wget "$IMAGE_URL"
fi

read -p "Are you sure you want to modify $ORIG_ISO? [y/N]: " yn

if [[ $yn == [Yy]* ]]; then
    if [ ! -d "livefs-editor" ]; then
        echo "Please install livefs-editor first!"
        exit 1
    fi

    mkdir mnt
    mount -o loop $ORIG_ISO mnt

    cp --no-preserve=all mnt/boot/grub/grub.cfg /tmp/grub.cfg
    sed -i 's/linux	\/casper\/vmlinuz  ---/linux	\/casper\/vmlinuz autoinstall quiet ---/g' /tmp/grub.cfg
    sed -i 's/timeout=30/timeout=1/g' /tmp/grub.cfg

    # copy command exactly as is, it appends `-modded` to the new filename
    export MODDED_ISO="${ORIG_ISO::-4}-modded.iso"
    livefs-edit ./$ORIG_ISO ./$MODDED_ISO --cp /tmp/grub.cfg new/iso/boot/grub/grub.cfg
    ORIG_ISO=$MODDED_ISO
fi

# List all the disk devices
lsblk -p -o NAME,SIZE,TYPE,MOUNTPOINT

read -p "Please enter the device file for the USB (e.g., /dev/sdb): " USB_STICK_DEV

read -p "Are you sure you want to format $USB_STICK_DEV? All data will be lost. [y/N]: " yn
case $yn in
    [Yy]* ) ;;
    * ) echo "Aborting."; return;;
esac

umount "$USB_STICK_DEV"* || true

sudo dd bs=4M if=./$ORIG_ISO of=$USB_STICK_DEV conv=fdatasync status=progress

