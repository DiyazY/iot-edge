#!/bin/bash

generate_ssh_key() {
    # This function expects the key name as its first argument
    local key_name="iot-$1"
    # This function expects the path as its second argument
    local ssh_path="${2:-$HOME/.ssh}"
    # This function expects a flag indicating whether to overwrite existing keys as its third argument
    local overwrite="$3"


    # Check if a key name was provided
    if [[ -z "$key_name" ]]; then
        echo "Please provide a key name as the first argument."
        return 1
    fi

    # Ensure the path exists
    mkdir -p "$ssh_path"

    # Check if the key already exists
    if [[ -f "$ssh_path/$key_name" && "$overwrite" || ! -f "$ssh_path/$key_name" ]]; then
        ssh-keygen -t rsa -b 4096 -f "$ssh_path/$key_name" -q -N ""
    fi

    # Output the public key
    cat "$ssh_path/${key_name}.pub"
}
