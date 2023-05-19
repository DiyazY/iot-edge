#!/bin/bash

# Check if Multipass is installed
if ! command -v multipass &> /dev/null; then
    echo "Multipass is not installed. Please install Multipass before proceeding."
    exit 1
fi

# Function to create or start VMs
create_vms() {
    # Define an array of VM names
    vms=("vm1" "vm2" "vm3")

    # Loop through the VM names and create/start the VMs
    for vm in "${vms[@]}"
    do
        if multipass info "$vm" &> /dev/null; then
            echo "VM '$vm' already exists. Starting the VM..."
            multipass start "$vm"
        else
            echo "Creating VM '$vm'..."
            multipass launch --name "$vm" --cpus 1 --mem 256M --disk 3G
        fi
    done
}

# Function to stop VMs
stop_vms() {
    multipass stop --all
}

# Function to remove VMs
remove_vms() {
    multipass delete --all --purge
}

# Interactive menu
while true
do
    echo "Please select an option:"
    echo "1. Launch/Start VMs"
    echo "2. Stop VMs"
    echo "3. Remove VMs"
    echo "4. Exit"

    read -p "Option: " option

    case $option in
        1)
            create_vms
            ;;
        2)
            stop_vms
            ;;
        3)
            remove_vms
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac

    echo
done
