#!/bin/sh
# API Call Latencies statistic for pods, deployments, namespaces, services



#$1 = experiment number
#$2 = kubernetes distro
#$3 = operation: namespace, pod, deployment, service
#$4 = test suit
#$5 = from_file
#$6 = to_file
toCSV(){
    metrics="create get list update delete"

    for metric in $metrics; do
        median=$(sed -e 's/.\{47\}//' $5 | grep -E "$metric $3 latency" | awk '{print $4}')
        min=$(sed -e 's/.\{47\}//' $5 | grep -E "$metric $3 latency" | awk '{print $5}')
        max=$(sed -e 's/.\{47\}//' $5 | grep -E "$metric $3 latency" | awk '{print $6}')
        echo $2,$3,$4,$1,$metric,$median,$min,$max >> $6
    done
}

operations=("namespace" "pod" "deployment" "service")
distros=("k0s" "k3s" "k8s" "kubeEdge" "openYurt")
testSuits=("cp_light_1client" "cp_heavy_8client" "cp_heavy_12client")

for testSuit in "${testSuits[@]}"; do
    my_file="../../k-bench-results/latency-statistics/$testSuit.csv"
    echo k8s,operations,tests,test-numbers,metrics,medians,mins,maxs > $my_file
    for distro in "${distros[@]}"; do
        for operation in "${operations[@]}"; do
            for i in {1..5}; do
                toCSV $i $distro $operation $testSuit "../../k-bench-results/$distro/$testSuit/$testSuit-$i/kbench.log" $my_file
            done
        done
    done
    cat $my_file
done

