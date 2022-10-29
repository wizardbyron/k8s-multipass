#!/usr/bin/env bash
K8S_VER=$1

if [ -z "$K8S_VER" ];then
    echo "Kubernetes version MUST BE given while install."
    exit 1
fi

echo "Check packages.cloud.google.com reachable."
ping -c1 packages.cloud.google.com
GOOGLE_REACHABLE=$?

if [ "$GOOGLE_REACHABLE" -ne 0 ];then
    MIRROR_URL=mirrors.aliyun.com
fi

### Setup Docker
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

# Install kubelet, kubeadm and kubectl
echo "Install Kubernetes packages via package manager."

if [ "$GOOGLE_REACHABLE" -eq 0 ];then
  K8S_PKG_URL="packages.cloud.google.com"
else
  K8S_PKG_URL="$MIRROR_URL/kubernetes"
fi


echo "Install Kubernetes $K8S_VER packages from $K8S_PKG_URL"
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://$K8S_PKG_URL/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://$K8S_PKG_URL/apt kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sh -c "sudo apt-get install -y --no-upgrade kubelet=$K8S_VER.0-00 kubeadm=$K8S_VER.0-00 kubectl=$K8S_VER.0-00"
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet