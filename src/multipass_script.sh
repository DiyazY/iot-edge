#!/bin/bash

# Check if Multipass is installed
if ! command -v multipass &> /dev/null; then
    echo "Multipass is not installed. Please install Multipass before proceeding."
    exit 1
fi

# Check if ssh-copy-id is installed
if ! command -v ssh-copy-id &> /dev/null; then
    echo "ssh-copy-id is not installed. Please install ssh-copy-id before proceeding."
    exit 1
fi

# Check if k3sup is installed
if ! command -v k3sup &> /dev/null; then
    echo "k3sup is not installed. Please install k3sup before proceeding."
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
            multipass launch --name "$vm" --cpus 2 --mem 512M --disk 3G --cloud-init cloud-init.yaml
        fi
    done
}

setup_cluster(){
    # Retrieve the list of Multipass VM names
    vm_names=$(multipass list --format csv | awk -F ',' 'NR>1{print $1}')

    # Retrieve the IP addresses of Multipass VMs
    ip_addresses=()
    for vm in $vm_names
    do
        ip=$(multipass info $vm | awk '/IPv4/{print $2}')  # Retrieve IP address of the VM
        ip_addresses+=($ip)
    done

    # Set the first VM as the master node
    master_ip=${ip_addresses[0]}
    echo "Installing K3s on the master node with IP '$master_ip'..."
    k3sup install --ip $master_ip --user root --ssh-key $HOME/.ssh/iot-edge

    # Join the remaining VMs as worker nodes
    worker_ips=("${ip_addresses[@]:1}")  # Exclude the first IP address
    for worker_ip in "${worker_ips[@]}"
    do
        echo "Installing K3s on worker node at $worker_ip and joining to the master node..."
        k3sup join --ip $worker_ip --server-ip $master_ip --user root --ssh-key $HOME/.ssh/iot-edge
    done

    echo "K3s cluster setup complete!"
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
    echo "4. Install k3s"
    echo "5. Exit"

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
            setup_cluster
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac

    echo
done
