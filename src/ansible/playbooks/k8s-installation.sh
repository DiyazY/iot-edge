#!/bin/bash

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl # this is required by k8s

sudo systemctl enable --now kubelet

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sudo modprobe overlay
sudo modprobe br_netfilter


# verify that things are running
lsmod | grep br_netfilter
lsmod | grep overlay

# verify that these [net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward] are set to 1
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# containerd steps - begin
# sudo wget -O /tmp/containerd-1.7.11-linux-amd64.tar.gz https://github.com/containerd/containerd/releases/download/v1.7.11/containerd-1.7.11-linux-amd64.tar.gz
# sudo tar Cxzvf /usr/local /tmp/containerd-1.7.11-linux-amd64.tar.gz

# rpi
sudo wget -O /tmp/containerd-2.0.3-linux-arm64.tar.gz https://github.com/containerd/containerd/releases/download/v2.0.3/containerd-2.0.3-linux-arm64.tar.gz
sudo tar Cxzvf /usr/local /tmp/containerd-2.0.3-linux-arm64.tar.gz

# sudo wget -O /usr/local/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
# the line below is used on raspberry pi
sudo wget -O /etc/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# sudo wget -O /tmp/runc.amd64 https://github.com/opencontainers/runc/releases/download/v1.1.11/runc.amd64
# sudo install -m 755 /tmp/runc.amd64 /usr/local/sbin/runc

# rpi
sudo wget -O /tmp/runc.arm64 https://github.com/opencontainers/runc/releases/download/v1.2.5/runc.arm64
sudo install -m 755 /tmp/runc.arm64 /usr/local/sbin/runc

mkdir -p /opt/cni/bin
# sudo wget -O /tmp/cni-plugins-linux-amd64-v1.4.0.tgz https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
# sudo tar Cxzvf /opt/cni/bin /tmp/cni-plugins-linux-amd64-v1.4.0.tgz

# rpi
sudo wget -O /tmp/cni-plugins-linux-arm64-v1.6.2.tgz https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-arm64-v1.6.2.tgz
sudo tar Cxzvf /opt/cni/bin /tmp/cni-plugins-linux-arm64-v1.6.2.tgz
# containerd steps - end

sudo mkdir /etc/containerd
sudo touch /etc/containerd/config.toml
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# in /etc/containerd/config.toml change SystemCgroup to true
# [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
#   ...
#   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#     SystemdCgroup = true

# new containerd 2.X
# version = 3
# [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
#   SystemdCgroup = true

sudo systemctl restart containerd

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# till this line things are the same for master and nodes

# master node - begin
ip route show # Look for a line starting with "default via"

sudo kubeadm init --apiserver-advertise-address [your ip address] --pod-network-cidr

sudo cp /etc/kubernetes/kubelet.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# disabling swap stopped kubelet issue
sudo systemctl restart kubelet



# kubelet refuses to do anything, kubeadm points at kubelet
# disabling cgroup as kubeadm suggested
sudo sed -i "s/cgroupDriver: systemd/cgroupDriver: cgroupfs/g" /var/lib/kubelet/config.yaml
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# didn't help... do one more time kubeadm reset
sudo kubeadm reset
sudo kubeadm init --apiserver-advertise-address [your ip address] # 

# eventually, flunnel requires cidr
sudo cat /etc/kubernetes/manifests/kube-controller-manager.yaml | grep -i cluster-cidr
# shown empty
sudo kubeadm init --apiserver-advertise-address [your ip address] --pod-network-cidr [cidr-ip]
sudo cp /etc/kubernetes/kubelet.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# then I had troubles with certificate
sudo kubeadm init phase certs all # this doesn't help
# kubeadm reset and rebooting the machine allows to proceed further

# run this from a remote machine

# NOTE: for kubeedge run it with env variable: export KUBECONFIG=/home/d-user/.kube/config
# Acutally, kubeedge has its sown CNI compatible networking plugin: edgemesh (https://github.com/kubeedge/kubeedge/issues/1662)

kubectl --kubeconfig ../.kube/[config-path] apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml --validate=false

# master node - end


###
# preparing worker nodes.
###
sudo apt-get update
# and run all previous steps except 

# run on worker nodes (those are in local net... and only for testing)
# get the token: kubeadm token create --print-join-command
kubeadm join 192.168.1.106:6443 --token ibwhz4.d287l59q08bpoyhp --discovery-token-ca-cert-hash sha256:626b5d1d474caa116b44472748477a62f6bc7407760966db44bee7f4000e585e 


# kube-dns issue: https://github.com/containerd/containerd/issues/4857#issuecomment-747238907

###
# Cleaning the worker nodes
###
# run k8s-drain-worker.yaml playbook

# cleaning ip tables if needed
# sudo iptables -P INPUT ACCEPT
# sudo iptables -P FORWARD ACCEPT
# sudo iptables -P OUTPUT ACCEPT
# sudo iptables -t nat -F
# sudo iptables -t mangle -F
# sudo iptables -F
# sudo iptables -X

# sudo ip6tables -P INPUT ACCEPT
# sudo ip6tables -P FORWARD ACCEPT
# sudo ip6tables -P OUTPUT ACCEPT
# sudo ip6tables -t nat -F
# sudo ip6tables -t mangle -F
# sudo ip6tables -F
# sudo ip6tables -X

# iptables -nvL