#!/bin/bash

# WIP

distribution="k0s"
test_types=("cp_light_1client" "cp_heavy_8client" "cp_heavy_12client" "dp_redis_density")
# "idle"

# ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/tymesync.yaml
for test_type in "${test_types[@]}"; do
    for i in {1..5}; do
        tag="${test_type}-${i}"
        mkdir -p ../k-bench-results/${distribution}/${test_type}/${tag}
        output_file="../k-bench-results/${distribution}/${test_type}/${tag}/ansible_output_${distribution}_${tag}.txt"
        # run one round of test
        echo "updating hosts.ini..."
        ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/update-tag-in-inventory.yaml --extra-vars "new_tag=${tag}" > "$output_file" 2>&1
        echo "setting netdata tag..."
        ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/netdata-tag-setup.yaml >> "$output_file" 2>&1
        echo "waiting 30min..."
        sleep 1800 # wait 30 min

         if [[ "$test_type" == "idle" ]]; then
            start_time=$(date '+%s')
            echo "start time: $start_time"
            sleep 300 # wait 5 mins
            end_time=$(date '+%s')
            echo "end time: $end_time"
            ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/mongodb-derive-data.yaml --extra-vars "start_test=${start_time} end_test=${end_time} test_type=${test_type}" >> "$output_file" 2>&1 
        else
            ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/k-bench-run.yaml --extra-vars "test_type=${test_type}" >> "$output_file">> "$output_file" 2>&1
            start_time=$(cat ./playbooks/tmp-before.txt)
            echo "start time: $start_time"
            end_time=$(cat ./playbooks/tmp-after.txt)
            echo "end time: $end_time"
            ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/mongodb-derive-data.yaml --extra-vars "start_test=${start_time} end_test=${end_time} test_type=${test_type}" >> "$output_file" 2>&1 
        fi

        if [[ "$test_type" == "dp_redis_density" ]]; then
            kubectl cp kbench-pod-namespace/kbench-pod-oid-0-tid-0:tmp/redisoutput ../../k-bench-results/${distribution}/${test_type}/${tag}/ --kubeconfig ../../.kube/${distribution}-config
        fi

        # TODO: check step

        # commit the changes
        git add "../../."
        git commit -m"${distribution} | ${tag}"
    done
    echo "waiting 30min..."
    sleep 1800 # wait 30 min
done

ansible-playbook -i inventory/${distribution}/hosts.ini shutdown.yaml