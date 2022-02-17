#!/usr/bin/env bash
set -e
export PATH=$PATH:/home/$(whoami)/.local/bin

MIRROR=$1
if [ "$MIRROR" == "tencent" ];then
    MIRROR_URL=mirrors.tencent.com
elif [ "$MIRROR" == "aliyun" ];then
    MIRROR_URL=mirrors.aliyun.com
fi

if [ -n "$MIRROR_URL" ];then
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    sudo sed -i "s/archive.ubuntu.com/$MIRROR_URL/g" /etc/apt/sources.list
fi

sudo apt update -y
sudo apt install -y software-properties-common git firewalld curl python3-pip unzip docker.io tcpdump ntp openssh-server apt-transport-https ca-certificates curl
sudo apt full-upgrade -y
sudo systemctl enable --now firewalld
python3 -m pip install --upgrade pip

### Upgrade pip
echo "Upgrade pip."
if [ -n "$MIRROR_URL" ];then
    sudo sh -c "python3 -m pip install --upgrade -i https://$MIRROR_URL/pypi/simple pip"
else
    sudo sh -c "python3 -m pip install --upgrade pip"
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

sudo systemctl enable --now docker.service
sudo systemctl restart docker
sudo usermod -aG docker $(whoami)


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
KUBE_VERSION=$2
if [ "$KUBE_VERSION" == "latest" ];then
  VERSION_STRING=""
else
  VERSION_STRING="=$KUBE_VERSION0"
fi

if [ -n "$MIRROR" ];then
    K8S_PKG_URL="$MIRROR_URL/kubernetes"
else
    K8S_PKG_URL=packages.cloud.google.com
fi

sudo apt install -y apt-transport-https ca-certificates curl
curl https://$K8S_PKG_URL/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://$K8S_PKG_URL/apt/ kubernetes-xenial main"|sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update -y
sh -c "sudo apt install -y kubelet$VERSION_STRING kubeadm$VERSION_STRING kubectl$VERSION_STRING"
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

## post installation
mkdir $HOME/configs
ssh-keygen  -t rsa -P '' -f $HOME/.ssh/identity

## Alias
alias pip="python3 -m pip"