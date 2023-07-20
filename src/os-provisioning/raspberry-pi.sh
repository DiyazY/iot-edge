#!/bin/bash

flash_image_to_sd_card() {
    export IMAGE_FILE="ubuntu-22.04.2-preinstalled-server-arm64+raspi.img.xz"
    export IMAGE_URL="https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.2-preinstalled-server-arm64+raspi.img.xz"


    # Check if the image file already exists
    if [ ! -f "$IMAGE_FILE" ]; then
        # If the file does not exist, download the image
        wget "$IMAGE_URL"
    fi

    # Decompress the image if it hasn't been decompressed already
    DECOMPRESSED_IMAGE="${IMAGE_FILE%.xz}"
    if [ ! -f "$DECOMPRESSED_IMAGE" ]; then
        unxz "$IMAGE_FILE"
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        # List all the disk devices
        diskutil list
        # Ask the user to specify the SD card
        read "SD_CARD_DEV?Please enter the device file for the SD card (e.g., /dev/disk2): "

        # Ask for confirmation before formatting the SD card
        read "yn?Are you sure you want to format $SD_CARD_DEV? All data will be lost. [y/N]: "
        case $yn in
            [Yy]* ) ;;
            * ) echo "Aborting."; return;;
        esac

        # Unmount all partitions of the SD card
        diskutil unmountDisk "$SD_CARD_DEV"
    else
        # Linux
        # List all the disk devices
        lsblk -p -o NAME,SIZE,TYPE,MOUNTPOINT
        # Ask the user to specify the SD card
        read -p "Please enter the device file for the SD card (e.g., /dev/sdb): " SD_CARD_DEV

        # Ask for confirmation before formatting the SD card
        read -p "Are you sure you want to format $SD_CARD_DEV? All data will be lost. [y/N]: " yn
        case $yn in
            [Yy]* ) ;;
            * ) echo "Aborting."; return;;
        esac

        # Unmount all partitions of the SD card
        umount "$SD_CARD_DEV"* || true
    fi

    # Copy the image to the SD card
    # This will take a while, and there's no progress indicator.
    sudo dd if="$DECOMPRESSED_IMAGE" of="$SD_CARD_DEV" bs=100M status=progress

    # Ensure the system has finished writing data to the SD card
    sync

    echo "Ubuntu image has been written to $SD_CARD_DEV. You can now remove the SD card."
}
