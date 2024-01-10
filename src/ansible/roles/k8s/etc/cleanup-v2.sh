#!/bin/bash

sudo kubeadm reset
# Stop containerd service
sudo systemctl stop containerd
sudo systemctl disable containerd

# Stop kubelet service
sudo systemctl stop kubelet
sudo systemctl disable kubelet

# Uninstall Kubernetes packages
sudo apt-get purge -y --allow-change-held-packages kubeadm kubelet kubectl kubernetes-cni kube*
sudo apt-get autoremove -y

# Remove Kubernetes configuration files
sudo rm -rf /etc/kubernetes

# Reset CNI configuration
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/cni
sudo rm  -rf /etc/modules-load.d/containerd.conf
sudo rm -rf /etc/modules-load.d/containerd.conf
sudo rm -f /usr/share/keyrings/kubernetes-archive-keyring.asc
sudo rm -f /etc/apt/keyrings/docker.gpg
sudo rm -f /etc/sysctl.d/kubernetes.conf 
sudo rm -f /etc/default/kubelet
sudo rm -rf /etc/containerd/
sudo rm -f /etc/docker/daemon.json
sudo rm -rf /etc/systemd/system/kubelet.service.d
sudo rm -f /tmp/join_cluster.sh
sudo rm -rf ~/.kube
sudo rm -rf  /var/lib/etcd 
sudo rm -rf /etc/kubernetes/manifests/kube-apiserver.yaml




# Clean up iptables rules related to Kubernetes
sudo iptables --flush
sudo iptables --delete-chain
sudo iptables -t nat --flush
sudo iptables -t nat --delete-chain


# (Optional) Remove Docker containers and images
# Uncomment the following lines if you want to remove all Docker containers and images
sudo docker stop $(sudo docker ps -aq)
sudo docker rm $(sudo docker ps -aq)
sudo docker rmi $(sudo docker images -q)

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
