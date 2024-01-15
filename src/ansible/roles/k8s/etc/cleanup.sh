#!/bin/bash

# Stop containerd service
sudo systemctl stop containerd
sudo systemctl disable containerd

# Stop kubelet service
sudo systemctl stop kubelet
sudo systemctl disable kubelet

# Uninstall Kubernetes packages
sudo apt-get purge -y kubeadm kubelet kubectl kubernetes-cni kube*
sudo apt-get autoremove -y

# Remove Kubernetes configuration files
sudo rm -rf /etc/kubernetes

# Reset CNI configuration
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/cni
sudo rm  -rf /etc/modules-load.d/containerd.conf
sudo rm /usr/share/keyrings/kubernetes-archive-keyring.asc
sudo rm -rf /etc/containerd/

# Clean up iptables rules related to Kubernetes
sudo iptables --flush
sudo iptables --delete-chain

# (Optional) Remove Docker containers and images
# Uncomment the following lines if you want to remove all Docker containers and images
# sudo docker stop $(sudo docker ps -aq)
# sudo docker rm $(sudo docker ps -aq)
# sudo docker rmi $(sudo docker images -q)

# Flush iptables
sudo iptables -F
sudo iptables -t nat -F

# Remove Docker networks
# sudo docker network prune -f

# Stop and remove all containerd containers
sudo ctr -n=k8s.io containers ls | awk '{print $1}' | xargs -I {} sudo ctr -n=k8s.io containers rm {}

# Remove containerd container snapshots
sudo ctr -n=k8s.io snapshots ls | awk '{print $1}' | xargs -I {} sudo ctr -n=k8s.io snapshots rm {}

echo "Kubernetes and related components have been uninstalled."
