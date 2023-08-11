# LOGS
* August
  * TODO: decide the monitoring tool and test scenarios
* July
  * Accidentally, I tore down the whole VM... I confused the disk for installing fresh OS.
  * OS provisioning for raspberry pi is done. It can be found [here](./src/os-provisioning/raspberry-pi.sh).
  * Decided to automate the image preparation.
  * Intended to implement [non-touch bare metal Ubuntu installation](https://www.jimangel.io/posts/automate-ubuntu-22-04-lts-bare-metal/#create-a-bootable-live-server-usb).
    * the attempt is failed due a shortage of USB sticks and some knowledge gaps. Additionally, it was considered as an overhead for such a small project. 
  * Agreed on a test-plan draft
```
      Performance benchmarking:
      * K-bench (https://github.com/vmware-tanzu/k-bench)
      * K8s repo (https://github.com/kubernetes/perf-tests)

      Security testing:
      * CIS K8s (https://www.cisecurity.org/benchmark/kubernetes)
      * Kube-bench (https://devopscube.com/kube-bench-guide/)
      * Kube-bench (https://github.com/aquasecurity/kube-bench)

      Reliability testing:
      * Netflix Chaos Monkey (https://github.com/Netflix/chaosmonkey)
      * Another Chaos Monkey (https://github.com/asobti/kube-monkey)

      * How long does it take to identify an unavailable node?
          * Also how long does it take to boot it up?
      * Can we define the status of a node! For example:
          * If the sensor goes down, would cluster consider the node as unhealthy and try to rebalance the traffic to another node (redundant node)? 
```
* June
  * The solution below is acceptable for local prototyping but can not be considered for real-case scenarios. Instead, we are going to use `ansible` for provisioning OS and dependencies.
* May
  * Multipass was used for VM boots. For automation a simple `sh` script was written [multipass_script.sh](/src/multipass_script.sh)
* April
  * Vagrant doesn't work on mac M1 machine (there are some issues with Virtual Box)