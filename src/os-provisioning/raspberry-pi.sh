#!/bin/bash

source ./generate-ssh-key.sh
source ./generate-cloud-init-file.sh

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

provision_os(){
    local image_file="ubuntu-22.04.2-preinstalled-server-arm64+raspi.img.xz"
    local image_url="https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.2-preinstalled-server-arm64+raspi.img.xz"

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

    # Ask for confirmation before formatting the SD card
    read -p "Are you sure you want to format $SD_CARD_DEV? All data will be lost. [y/N]: " yn
    case $yn in
        [Yy]* ) ;;
        * ) echo "Aborting."; return;;
    esac

    flash_image_to_sd_card "$SD_CARD_DEV" "$image_file" "$image_url"
    flash_cloud_init_to_sd_card "$SD_CARD_DEV" "./cloud-init.template" "/home/parallels/.ssh"

    echo "Finished provisioning OS!"
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

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Unmount all partitions of the SD card
        diskutil unmountDisk "$disk_path"
    else
        # Unmount all partitions of the SD card
        umount "$disk_path"* || true
    fi

    # Copy the image to the SD card
    # This will take a while, and there's no progress indicator.
    dd if="$DECOMPRESSED_IMAGE" of="$disk_path" bs=100M status=progress

    # Ensure the system has finished writing data to the SD card
    sync

    echo "Ubuntu image has been written to $disk_path. You can now remove the SD card."
}

# configures sd-card before first booting
flash_cloud_init_to_sd_card(){
    local disk_path="$1"
    local file_path="${2:-./cloud-init.template}"
    local ssh_path="$3"

    local partition_path="${disk_path}1" #$(lsblk -p -o NAME,MOUNTPOINT | grep 'system-boot' |tr -d '├─'| awk '{print $1}')
    # check that the partition is exact part of the $disk_path
    if [[ ! "$partition_path" == "$disk_path"* ]]; then
        echo "The partition $partition_path is not part of the disk $disk_path"
        return
    fi

    echo "The partition $partition_path will be used for cloud-init"


    TMP_DISK="/tmp/pi-disk"
    mkdir -p "$TMP_DISK"

    local ssh_key=$(generate_ssh_key "test-iot" "$ssh_path")
    local generated_file=$(generate_cloud_init_file "$file_path" "$ssh_key")

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # mount all partitions of the SD card
        diskutil mountDisk "$partition_path" "$TMP_DISK"
    else
        # mount all partitions of the SD card
        mount "$partition_path" "$TMP_DISK"
    fi

    cat "$generated_file" > "$TMP_DISK/user-data"

    # unmount the disk if done
    umount "$TMP_DISK"
}

provision_os

# TODO: remove the host from known_hosts
# ssh-keygen -f "~/.ssh/known_hosts" -R "192.168.1.113"
# remove the ssh key file (prefix with iot-) from the .ssh folder
# remove generated cloud-init file