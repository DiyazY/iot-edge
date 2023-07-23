#!/bin/bash

source ./generate-ssh-key.sh
source ./generate-cloud-init-file.sh

provision_os(){
    local disk_path=$(list_and_select_disk)
    local image_file="ubuntu-22.04.2-preinstalled-server-arm64+raspi.img.xz"
    local image_url="https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.2-preinstalled-server-arm64+raspi.img.xz"
    
    flash_image_to_sd_card "$disk_path" "$image_file" "$image_url"
    flash_cloud_init_to_sd_card "$disk_path"
}

# makes the sd-card bootable
flash_image_to_sd_card() {
    local disk_path="$1"
    local image_file="$2"
    local image_url="$3"


    # Check if the image file already exists
    if [ ! -f "$image_file" ]; then
        # If the file does not exist, download the image
        wget "$image_url"
    fi

    # Decompress the image if it hasn't been decompressed already
    DECOMPRESSED_IMAGE="${image_file%.xz}"
    if [ ! -f "$DECOMPRESSED_IMAGE" ]; then
        unxz "$image_file"
    fi

    # Ask for confirmation before formatting the SD card
    read "yn?Are you sure you want to format $disk_path? All data will be lost. [y/N]: "
    case $yn in
        [Yy]* ) ;;
        * ) echo "Aborting."; return;;
    esac

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Unmount all partitions of the SD card
        diskutil unmountDisk "$disk_path"
    else
        # Unmount all partitions of the SD card
        umount "$disk_path"* || true
    fi

    # Copy the image to the SD card
    # This will take a while, and there's no progress indicator.
    sudo dd if="$DECOMPRESSED_IMAGE" of="$disk_path" bs=100M status=progress

    # Ensure the system has finished writing data to the SD card
    sync

    echo "Ubuntu image has been written to $disk_path. You can now remove the SD card."
}

# configures sd-card before first booting
flash_cloud_init_to_sd_card(){
    local disk_path="$1"
    local file_path="${2:-./cloud-init.template}"

    TMP_DISK="/tmp/pi-disk"
    mkdir "$TMP_DISK" // TODO: check this place
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Unmount all partitions of the SD card
        diskutil mountDisk "$disk_path" "$TMP_DISK"
    else
        # Unmount all partitions of the SD card
        mount "$disk_path" "$TMP_DISK"
    fi


    local ssh_key=$(generate_ssh_key "test-iot")
    generate_cloud_init_file "$file_path" "$ssh_key"

    cat "$file_path" > "$TMP_DISK/user-data"

    # unmount the disk if done
    umount "$TMP_DISK"
}

list_and_select_disk(){
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        # List all the disk devices
        diskutil list
        # Ask the user to specify the SD card
        read "SD_CARD_DEV?Please enter the device file for the SD card (e.g., /dev/disk2): "
    else
        # Linux
        # List all the disk devices
        lsblk -p -o NAME,SIZE,TYPE,MOUNTPOINT
        # Ask the user to specify the SD card
        read -p "Please enter the device file for the SD card (e.g., /dev/sdb): " SD_CARD_DEV
    fi

    echo "$SD_CARD_DEV"
}