#!/bin/bash

source ./generate-ssh-key.sh
source ./generate-cloud-init-file.sh

flash_cloud_init_to_usb(){
    local ssh_key_name="${1:-iot-key}"
    local ssh_path="$2"
    local file_path="${3:-./cloud-init-usb.template}"

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

    # validate the name 
    sudo dosfslabel $USB_STICK_DEV

    local ssh_key=$(generate_ssh_key "$ssh_key_name" "$ssh_path")

    local generated_file=$(generate_cloud_init_file "$file_path" "$ssh_key")

    local local_path=$(pwd)

    mkdir -p /tmp/cidata
    sudo mount $USB_STICK_DEV /tmp/cidata

    cd /tmp/cidata
    sudo touch meta-data

    # sudo sh -c cat "$local_path/$generated_file" > "/tmp/cidata/user-data"
    sudo cat "$local_path/$generated_file" | sudo tee /tmp/cidata/user-data > /dev/null

    cd -

    echo "Installed cloud-init to USB stick!"
}

flash_cloud_init_to_usb "iot-key" "/home/parallels/.ssh" "./cloud-init-usb.template"