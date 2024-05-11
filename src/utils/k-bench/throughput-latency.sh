#!/bin/sh

#$1 = experiment number
#$2 = kubernetes distro
#$3 = test suit
#$4 = from_file
#$5 = to_file
toCSV(){ # TODO: fix this part: 1. values comes in arbitrary order 2. pods can not have higher number of pods than deployments

    pod_results=$(grep -n -E 'Pod Results' $4)
    pod_number=($(echo "$pod_results" | cut -d ':' -f 1))

    dep_results=$(grep -n -E 'Deployment Results' $4)
    dep_number=($(echo "$dep_results" | cut -d ':' -f 1))
    # echo "---- $4"
    # echo $pod_number $dep_number
    
    if [ ${dep_number} -gt ${pod_number} ]; then
        pod_results_pod_number_of_pods=$(sed -e 's/.\{47\}//' $4 | grep -E "Number of initialized pods" | awk '{ print $5}' | head -1 )
        pod_results_pod_creation_throughput=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod creation throughput" | awk '{ print $5}' | head -1 )
        echo pod,$2,$3,$1,$pod_results_pod_number_of_pods,throughput,$pod_results_pod_creation_throughput >> $5
        pod_results_pod_creation_latency=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod creation average latency" | awk '{ print $5}' | head -1 ) 
        echo pod,$2,$3,$1,$pod_results_pod_number_of_pods,latency,$pod_results_pod_creation_latency >> $5

        deployment_results_pod_number_of_pods=$(sed -e 's/.\{47\}//' $4 | grep -E "Number of initialized pods" | awk '{ getline; print $5}' )
        deployment_results_pod_creation_throughput=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod creation throughput" | awk '{ getline; print $5}' )
        echo deployment,$2,$3,$1,$deployment_results_pod_number_of_pods,throughput,$deployment_results_pod_creation_throughput >> $5
        deployment_results_pod_creation_latency=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod creation average latency" | awk '{ getline; print $5}' )
        echo deployment,$2,$3,$1,$deployment_results_pod_number_of_pods,latency,$deployment_results_pod_creation_latency >> $5
    else
        deployment_results_pod_number_of_pods=$(sed -e 's/.\{47\}//' $4 | grep -E "Number of initialized pods" | awk '{ print $5}'| head -1 )
        deployment_results_pod_creation_throughput=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod creation throughput" | awk '{ print $5}' | head -1)
        echo deployment,$2,$3,$1,$deployment_results_pod_number_of_pods,throughput,$deployment_results_pod_creation_throughput >> $5
        deployment_results_pod_creation_latency=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod creation average latency" | awk '{ print $5}'| head -1 )
        echo deployment,$2,$3,$1,$deployment_results_pod_number_of_pods,latency,$deployment_results_pod_creation_latency >> $5

        pod_results_pod_number_of_pods=$(sed -e 's/.\{47\}//' $4 | grep -E "Number of initialized pods" | awk '{ getline; print $5}' )
        pod_results_pod_creation_throughput=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod creation throughput" | awk '{ getline; print $5}' )
        echo pod,$2,$3,$1,$pod_results_pod_number_of_pods,throughput,$pod_results_pod_creation_throughput >> $5
        pod_results_pod_creation_latency=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod creation average latency" | awk '{ getline; print $5}' ) 
        echo pod,$2,$3,$1,$pod_results_pod_number_of_pods,latency,$pod_results_pod_creation_latency >> $5
    fi
    
}

distros=("k0s" "k3s" "k8s" "kubeEdge" "openYurt")
testSuits=("cp_light_1client" "cp_heavy_8client" "cp_heavy_12client")

for testSuit in "${testSuits[@]}"; do
    my_file="../../k-bench-results/throughput-latency-statistics/$testSuit.csv"
    echo type,k8s,tests,test-numbers,number-of-pods,metics,value > $my_file
    for distro in "${distros[@]}"; do
        for i in {1..5}; do
            toCSV $i $distro $testSuit "../../k-bench-results/$distro/$testSuit/$testSuit-$i/kbench.log" $my_file
        done
    done
    cat $my_file
done