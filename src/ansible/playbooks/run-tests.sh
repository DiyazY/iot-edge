#!/bin/bash

distribution="k0s"
tags=("k0s-idle-1" "k0s-idle-2" "k0s-idle-3" "k0s-idle-4" "k0s-idle-5")
test_type="idle"
# ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/tymesync.yaml

for tag in "${tags[@]}"; do
    mkdir -p ../k-bench-results/${distribution}/${test_type}/${tag}
    output_file="../k-bench-results/${distribution}/${test_type}/${tag}/ansible_output_${distribution}_${tag}.txt"
    # run one round of test
    echo "updating hosts.ini..."
    ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/update-tag-in-inventory.yaml --extra-vars "new_tag=${tag}" > "$output_file" 2>&1
    echo "setting netdata tag..."
    ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/netdata-tag-setup.yaml >> "$output_file" 2>&1
    echo "waiting 30min..."
    sleep 1800 # wait 30 min
    
    start_time=$(date '+%s')
    echo "start time: $start_time"
    sleep 300 # wait 5 mins
    end_time=$(date '+%s')
    echo "end time: $end_time"
    ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/mongodb-derive-data.yaml --extra-vars "start_test=${start_time} end_test=${end_time} test_type=${test_type}" >> "$output_file" 2>&1 

    # TODO: check step

    # commit the changes
    git add "../../."
    git commit -m"${distribution} | ${tag}"
done

ansible-playbook -i inventory/${distribution}/hosts.ini shutdown.yaml