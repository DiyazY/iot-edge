#!/bin/bash

# WIP

distribution="k8s"
test_types=("idle" "cp_light_1client" "cp_heavy_8client" "cp_heavy_12client" "dp_redis_density" "reliability-control" "reliability-worker" "reliability-control-no-pressure-long" "reliability-worker-no-pressure-long")

# ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/tymesync.yaml

# TODO: automate this part kubectl --kubeconfig ../.kube/k0s-config label  nodes <node-name>  beta.kubernetes.io/instance-type=worker

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

        machine="control"
        eth_interface="eno1"
        node_type="master"
        if [[ "$test_type" == *"worker"* ]]; then
            machine="worker"
            eth_interface="eth0"
            node_type="node"
        fi
        echo "Test is going..."
        if [[ "$test_type" == "idle" ]]; then
            start_time=$(date '+%s')
            echo "$start_time" > ../k-bench-results/${distribution}/${test_type}/${tag}/tmp-before.txt
            sleep 300 # wait 5 mins
            end_time=$(date '+%s')
            echo "$end_time" >> ../k-bench-results/${distribution}/${test_type}/${tag}/tmp-after.txt
            ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/mongodb-derive-data.yaml --extra-vars "start_test=${start_time} end_test=${end_time} test_type=${test_type}" >> "$output_file" 2>&1 
        elif [[ "$test_type" == "reliability-control" || "$test_type" == "reliability-worker" ]]; then
            random_number=$((RANDOM % 3))
            if [[ "$machine" == "control" ]]; then
                random_number=0
            fi
            sleep_time=100
            wait_time=600
            echo "Start testing of $machine: $random_number" > "$output_file"
            ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/k-bench-run.yaml --extra-vars "test_type=dp_redis_density" > "${output_file}-density" 2>&1 &
            ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/reliability-test.yaml --extra-vars "node_index=$random_number machine=$node_type eth_interface=$eth_interface test_type=$test_type sleep_time=$sleep_time wait_time=$wait_time" >> "$output_file" 2>&1
            # wait
            start_time=$(cat ../k-bench-results/${distribution}/${test_type}/${tag}/tmp-before.txt)
            echo "start time: $start_time"
            end_time=$(cat ../k-bench-results/${distribution}/${test_type}/${tag}/tmp-after.txt)
            echo "end time: $end_time"
            ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/mongodb-derive-data.yaml --extra-vars "start_test=${start_time} end_test=${end_time} test_type=${test_type}" >> "$output_file" 2>&1 
        elif [[ "$test_type" == "reliability-control-no-pressure-long" || "$test_type" == "reliability-worker-no-pressure-long" ]]; then
            random_number=$((RANDOM % 3))
            if [[ "$machine" == "control" ]]; then
                random_number=0
            fi
            sleep_time=500
            wait_time=200

            echo "Start testing of $machine: $random_number" > "$output_file"
            # ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/k-bench-run.yaml --extra-vars "test_type=dp_redis_density" > "${output_file}-density" 2>&1 &
            ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/reliability-test.yaml --extra-vars "node_index=$random_number machine=$node_type eth_interface=$eth_interface test_type=$test_type sleep_time=$sleep_time wait_time=$wait_time" >> "$output_file" 2>&1
            # wait
            start_time=$(cat ../k-bench-results/${distribution}/${test_type}/${tag}/tmp-before.txt)
            echo "start time: $start_time"
            end_time=$(cat ../k-bench-results/${distribution}/${test_type}/${tag}/tmp-after.txt)
            echo "end time: $end_time"
            ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/mongodb-derive-data.yaml --extra-vars "start_test=${start_time} end_test=${end_time} test_type=${test_type}" >> "$output_file" 2>&1 
        else
            ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/k-bench-run.yaml --extra-vars "test_type=${test_type}" >> "$output_file" 2>&1
            start_time=$(cat ../k-bench-results/${distribution}/${test_type}/${tag}/tmp-before.txt)
            echo "start time: $start_time"
            end_time=$(cat ../k-bench-results/${distribution}/${test_type}/${tag}/tmp-after.txt)
            echo "end time: $end_time"
            ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/mongodb-derive-data.yaml --extra-vars "start_test=${start_time} end_test=${end_time} test_type=${test_type}" >> "$output_file" 2>&1 
        fi

        if [[ "$test_type" == "dp_redis_density" || "$test_type" == "reliability-control" || "$test_type" == "reliability-worker" ]]; then
            kubectl cp kbench-pod-namespace/kbench-pod-oid-0-tid-0:tmp/redisoutput ../k-bench-results/${distribution}/${test_type}/${tag}/ --kubeconfig ../.kube/${distribution}-config >> "$output_file" 2>&1
        fi

        # TODO: check step

        # commit the changes
        git add "../../."
        git commit -m"${distribution} | ${tag}"
    done
    # remove containers for redis tests
    if [[ "$test_type" == "dp_redis_density" || "$test_type" == "reliability-control" || "$test_type" == "reliability-worker" ]]; then
        ansible-playbook -i inventory/${distribution}/hosts.ini ./playbooks/clean-redis-containers.yaml >> "$output_file" 2>&1 
    fi
    echo "waiting 30min..."
    sleep 1800 # wait 30 min
done

ansible-playbook -i inventory/${distribution}/hosts.ini shutdown.yaml