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
* run a script with sudo permission: `sudo src/os-provisioning/raspberry-pi.sh`.
* if the image is already downloaded, the script will ask which disk to use/format. Otherwise it starts downloading, and then asks.
* after providing a correct name of disk, it will copy uncompressed image to an SD card
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
  * when the installation is finished, NUC will shut down
  * **IMPORTANT: remove USB-sticks and only after that turn on NUC!!!**

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