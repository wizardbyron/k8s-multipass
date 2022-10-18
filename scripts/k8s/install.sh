#!/usr/bin/env bash
KUBE_VERSION=$1

echo "Check google reachable."
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

if [ -n "$KUBE_VERSION" ];then
  VERSION_STRING="=$KUBE_VERSION0"
else
  VERSION_STRING=""
fi

echo "Kubernetes package URL:$K8S_PKG_URL, Version: $KUBE_VERSION"

sudo sh -c "curl https://$K8S_PKG_URL/apt/doc/apt-key.gpg | apt-key add -"
echo "deb https://$K8S_PKG_URL/apt/ kubernetes-xenial main"|sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update -y
sh -c "sudo apt install -y kubelet$VERSION_STRING kubeadm$VERSION_STRING kubectl$VERSION_STRING"
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# Install calicoctl
echo "Install calicoctl"
sudo curl -L https://github.com/projectcalico/calico/releases/download/v3.22.0/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
sudo chmod +x /usr/local/bin/calicoctl
