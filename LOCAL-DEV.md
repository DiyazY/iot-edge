# Local Development
## Start working with Vagrant (doesn't work on Mac M1)
- all commands: `cd src` 
- to run VMs `vagrant up;`
  - to ssh into VM `vagrant ssh [machine1];`
  - list all VMs `vagrant status;`
- to stop VM(s) `vagrant halt [machine1 machine2];`
- to remove VM(s) `vagrant destroy [machine1 machine2];`

## Start working with Multipass
- all commands: `cd src` 
- chmod +x multipass_script.sh

## OS provisioning

### raspberry pi
To provision an OS on raspberry pi the next steps are required:
* connect sd-card to a machine.
* go to directory: `cd src/os-provisioning`
* run a script with sudo permission: `sudo ./raspberry-pi.sh`.
* if the image is already downloaded, the script will ask which disk to use/format. Otherwise it starts downloading, and then asks.
* after providing a correct name of disk, it will copy uncompressed image to an SD card (check the name of the disk carefully!!!)
* after preparing bootable SD card it will kick off the configuration process
* specifically, it creates cloud-init file with newly generated ssh-keys and mounts it to `system-boot` partition of SD-card.
* assemble raspberry pi...
* ssh to it: `ssh -i ~/.ssh/local-private-ssh-key [rpi-user]@[ip-address]`

### NUC 
To provision an OS on NUC the next steps are required:
* connect usb-stick #1 to a machine.
  * run script with sudo permission: `sudo src/os-provisioning/nuc.sh`.
  * ...wait
  * take out usb-stick #1
* connect usb-stick #2 to a machine.
  * run script with sudo permission: `sudo src/os-provisioning/nuc-cloud-init.sh`.
  * ...wait
  * take out usb-stick #2
* connect both USB-sticks to NUC
* Boot NUC from USB-stick #1
  * ...wait (or follow instructions if image was not modified)
    * Ensure the “Try or Install Ubuntu Server” option is highlighted using the up or down arrows.
    * Press e to edit the grub commands (launches a new screen)
    * Using the arrow keys, insert `autoinstall quiet` in the line that says `linux /casper/vmlinuz ---` before the dashes resulting in the full line appearing as: `linux /casper/vmlinuz autoinstall quiet ---`
Press F10 to save and exit
  * when the installation is finished, NUC will shut down
  * **IMPORTANT: remove USB-sticks and only after that turn on NUC!!!**
* More info can be found in [this great article](https://www.jimangel.io/posts/automate-ubuntu-22-04-lts-bare-metal/#check-ansible-connections)

## OS configuration and software provisioning
First change the directory: `cd src/ansible`;
* decided to use ansible for configuration management and software provisioning
* ping the machines: `ansible iot_cluster -m ping -i inventory/hosts.ini`
  * if it doesn't work, check inventory file for correct ip addresses and user name: `ansible-inventory -i inventory/hosts.ini --list`
* run hello-world playbook: `ansible-playbook -i inventory/hosts.ini hello-world.yaml`
* shutdown machines: `ansible-playbook -i inventory/hosts.ini shutdown.yaml` (note: it will print error messages, but it will work)

### k3s
* install k3s: `ansible-playbook playbooks/k3s.yaml -i inventory/k3s/hosts.ini`
  * scp [d-user]@[master_ip]:~/.kube/config .kube/k3s-config
  * check the cluster: `kubectl --kubeconfig .kube/k3s-config get nodes`
    * I prefer using k9s: `k9s --kubeconfig .kube/k3s-config`
* if ip addresses are changed, do this on each worker node: (TODO: automate this)
  * `sudo nano /etc/systemd/system/k3s-node.service` and correct the ip address of a master node
  * `sudo systemctl daemon-reload`
  * `sudo systemctl restart k3s-node`
  * and also change the ip address on a master node in `~/.kube/config` file
### netdata
* first of all, provide values in `roles/netdata/vars/main.yaml`:
  * `claim_token` - token for netdata cloud
  * `claim_rooms` - room for netdata cloud
* install netdata: `ansible-playbook playbooks/netdata.yaml -i inventory/hosts.ini`
* check the metrics in netdata cloud: `https://app.netdata.cloud/spaces/[space_name]`
* after changing `tag` in `inventory/hosts.ini` file, it is necessary to reflect it in all nodes, run: `ansible-playbook playbooks/netdata-tag-setup.yaml -i inventory/hosts.ini`. After that, netdata will populate metrics data with that tag.

### sync time
* install `ansible-galaxy install linux-system-roles.timesync` (run it from `src/ansible` directory)
* run `ansible-playbook playbooks/timesync.yaml -i inventory/hosts.ini`

### k-bench: preliminary work
* install k-bench: `ansible-playbook playbooks/k-bench-install.yaml -i inventory/hosts.ini`
* k-bench configurations might be extended in `roles/k-bench/etc/[config_name]/config.json`

#### k-bench: execution
* set up the `k8s_distribution` variable in `inventory/hosts.ini` file
  * and `tag` to indicate the number of runs (e.g. `tag=1`, or `tag=k3s-1`)
* run `ansible-playbook playbooks/k-bench-run.yaml -i inventory/hosts.ini`
* To check results 
  * `cd src/k-bench-results/[k8s_distribution]/[test_name]`
  * pod and deployment throughput statistics: `sed -e 's/.\{47\}//' ./kbench.log | grep -E 'Pod creation throughput|Pod creation average|Deployment Results|Pod Results|Pod startup total latency'`

#### k-bench: derive data
* WIP: run `ansible-playbook playbooks/k-bench-derive.yaml -i inventory/hosts.ini`

### kube-bench (security tests)
* install run it on a master node: `ansible-playbook playbooks/kube-bench-install.yaml -i inventory/hosts.ini`
* run security tests: `ansible-playbook playbooks/kube-bench-run.yaml -i inventory/hosts.ini` (it should produce file in repo).
* TODO: find out how to analyze the results.


### TIPS
* if router was restarted, it might be necessary to update the ip addresses in `inventory/hosts.ini` file
  * check the ip addresses in your router settings: they should start with `ubuntu-*` prefixes.
  * then run `ansible-playbook -i inventory/hosts.ini identify_nodes.yaml`.
  * this will display what nodes are: master, sidecar and nodes.
  * update hosts.ini file accordingly.
* failing netdata installation: 
  * for some reason, ansible fails to install netdata... You can run this task manually on the machine:
  * run `cd /opt/netdata; sudo bash ./netdata-installer.sh --enable-exporting-mongodb --disable-telemetry`
  * check if MongoDB is enabled: `netdata -W buildinfo`
  * after installation run `netdata.yaml` playbook again: `ansible-playbook playbooks/netdata.yaml -i inventory/hosts.ini`
* Sidecar node:
  * install mongodb on that machine (see `src/utils/mongodb.sh` script)
* `dp_redis_density` test requires some modification:
  * in roles/k-bench/etc/dp_redis_density/config.json change `YamlSpec` value to `"YamlSpec": "/home/{user-name}/.k-bench/configs/dp_redis_density/redis_pod.yaml"`
  * to get memtier benchmark results: `kubectl cp kbench-pod-namespace/kbench-pod-oid-0-tid-0:tmp/redisoutput ../k-bench-results/k3s/dp_redis_density/k3s-dp-redis-density-[test-number]/ --kubeconfig ../.kube/k3s-config`
  * and then to clean: on control plane machine `sudo .k-bench/cleanup.sh`
* k3s nodes NotReady statuses:
  * https://github.com/k3s-io/k3s/issues/1857
  * https://dev.to/arthurkay/k3s-node-status-notready-4j3m
  * Sometimes they are not ready, but it is possible to run tests anyway.
* dp_redis_density test needs the intervention in a master node. In `~/.k-bench/configs/dp_redis_density/redis_pod.yaml`, change line #17 to `worker`.
* before each distribution tests `kubectl --kubeconfig ../.kubeconfig label  nodes <node-name>  beta.kubernetes.io/instance-type=worker`
  * TODO: automate this step
* when run `reliability` tests, ensure that all eth interfaces are set correctly
* k0s wraps kubectl, thus, it should be reached out by `k0s kubectl`
* for k8s turn off swapping, `sudo swapoff -a`

# TODOs
* ~~add systemctl start mongod ~~
* manual installation of netdata works, but it takes a lot of time. 
  * ~~node_* installed netdata, but data is not sent yet!~~
* ~~pass tag through many places to mark test results with an appropriate test execution~~
* ~~Play with labels: https://learn.netdata.cloud/docs/configuring/organize-systems-metrics-and-alerts~~
* there is also new k8s distribution `SuperEdge`
* reduce the number of tests for density tests to 3 pods. Also make k3s's control plane act as a control machine, not worker. Try this:
  * (First check if it already tainted: kubectl --kubeconfig ../.kube/[k8s-config] describe node [node_name] | grep Taints)
  * kubectl taint nodes <control-plane-node-name> node-role.kubernetes.io/master=:NoSchedule
  * kubectl drain <control-plane-node-name> --ignore-daemonsets --delete-local-data
  * kubectl get pods -o wide