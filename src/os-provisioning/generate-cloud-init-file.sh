#!/bin/bash

generate_cloud_init_file() {
    # This function expects the template file path as its first argument
    local template_file="$1"
    # This function expects the ssh key as its second argument
    local ssh_key="$2"
    # This function expects the output file path as its third argument, default is ./cloud-init.yaml
    local output_file="${3:-./cloud-init.yaml}"

    # Check if a template file was provided
    if [[ -z "$template_file" ]]; then
        echo "Please provide a template file as the first argument."
        return 1
    fi

    # Check if an SSH key was provided
    if [[ -z "$ssh_key" ]]; then
        echo "Please provide an SSH key as the second argument."
        return 1
    fi

    # Replace the placeholder in the template with the SSH key and write to the output file
    sed "s|__SSH_AUTHORIZED_KEYS__|$ssh_key|g" "$template_file" > "$output_file"

    echo "$output_file"
}
