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
TODO: add description