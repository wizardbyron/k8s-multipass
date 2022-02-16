#!/usr/bin/env bash

# Update docker settings
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl restart docker

# Setup Network
cat <<EOF | sudo tee /etc/sysctl.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-arptables = 0
EOF
sudo sysctl -p

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system

# Switch off swap
sudo swapoff -a
echo "sudo swapoff -a">>$HOME/.bashrc

echo "Install Kubernetes packages via package manager."

KUBE_VERSION=$1
PACKAGE_MIRROR=$2


if [ "$PACKAGE_MIRROR" = "aliyun" ];then
  PACKAGE_URL=mirrors.aliyun.com/kubernetes
elif [ "$PACKAGE_MIRROR" = "tencent" ];then
  PACKAGE_URL=mirrors.tencent.com/kubernetes
else
  PACKAGE_URL=packages.cloud.google.com
fi


sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl
curl https://$PACKAGE_URL/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://$PACKAGE_URL/apt/ kubernetes-xenial main"|sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
ZERO=0
sh -c "sudo apt install -y kubelet=$KUBE_VERSION$ZERO kubeadm=$KUBE_VERSION$ZERO kubectl=$KUBE_VERSION$ZERO"
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet