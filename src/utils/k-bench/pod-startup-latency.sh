#!/bin/sh
# Pod Startup Latencies statistic




#$1 = experiment number
#$2 = kubernetes distro
#$3 = test suit
#$4 = from_file
#$5 = to_file
toCSV(){

    pod_results_pod_number_of_pods=$(sed -e 's/.\{47\}//' $4 | grep -E "Number of initialized pods" | awk '{ print $5}' | head -1 )
    median=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod startup total latency \(server\)" | awk '{print $6}' | head -1)
    min=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod startup total latency \(server\)" | awk '{print $7}' | head -1)
    max=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod startup total latency \(server\)" | awk '{print $8}' | head -1)
    echo $2,$3,$1,$pod_results_pod_number_of_pods,$median,$min,$max >> $5

    deployment_results_pod_number_of_pods=$(sed -e 's/.\{47\}//' $4 | grep -E "Number of initialized pods" | awk '{ getline; print $5}' )
    median=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod startup total latency \(server\)" | awk '{getline; print $6}' )
    min=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod startup total latency \(server\)" | awk '{getline; print $7}' )
    max=$(sed -e 's/.\{47\}//' $4 | grep -E "Pod startup total latency \(server\)" | awk '{getline; print $8}' )
    echo $2,$3,$1,$deployment_results_pod_number_of_pods,$median,$min,$max >> $5
    
}

operations=("namespace" "pod" "deployment" "service")
distros=("k0s" "k3s" "k8s" "kubeEdge" "openYurt")
testSuits=("cp_light_1client" "cp_heavy_8client" "cp_heavy_12client")


my_file="../../k-bench-results/pod-startup-latency/pod-startup-latency.csv"
echo k8s,tests,test-numbers,number-of-pods,medians,mins,maxs > $my_file
for testSuit in "${testSuits[@]}"; do
    for distro in "${distros[@]}"; do
        for i in {1..5}; do
            toCSV $i $distro $testSuit "../../k-bench-results/$distro/$testSuit/$testSuit-$i/kbench.log" $my_file
        done
    done
    cat $my_file
done

