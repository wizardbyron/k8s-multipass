#!/usr/bin/env bash

K8S_IMAGE_REPO=$1

# Setup firewalld for k8s
echo "Setting up firewalld for k8s, refer to https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/"
sudo firewall-cmd --zone=public --permanent --add-port=179/tcp # For Calico BGP
sudo firewall-cmd --zone=public --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8000/tcp
sudo firewall-cmd --zone=public --permanent --add-port=10250-10252/tcp
sudo firewall-cmd --reload

# Install and setup control panel
echo "Setup Kubernetes Control Panel, Image Ropo: $K8S_IMAGE_REPO"

if [ -n "$K8S_IMAGE_REPO" ];then
    K8S_IMAGE_REPO_URL="registry.aliyuncs.com/google_containers"
else
    K8S_IMAGE_REPO_URL="k8s.gcr.io"
fi

sudo kubeadm init --v=5 \
    --image-repository=$K8S_IMAGE_REPO_URL \
    --apiserver-advertise-address=$(hostname -I|awk '{print $1}') \
    --service-cidr=10.0.0.0/16 \
    --pod-network-cidr=10.1.0.0/16

if [ $? = 0 ]; then
    sudo sed -i 's/- --port=0$/#- --port=0/' /etc/kubernetes/manifests/kube-controller-manager.yaml
    sudo sed -i 's/- --port=0$/#- –-port=0/' /etc/kubernetes/manifests/kube-scheduler.yaml

    echo "Setting up kubectl for $(whoami)"
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
else
    exit 1
fi

# Create join-cluster.sh
echo "$(kubeadm token create --print-join-command --ttl 0) --v=5" > /share/join-cluster.sh
chmod 755 /share/join-cluster.sh

# Install helm
echo "Install helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install and setup calico
echo "Install and configure calico"
curl -o calico.yaml https://docs.projectcalico.org/manifests/calico.yaml
sed -i 's/# - name: CALICO_IPV4POOL_CIDR/- name: CALICO_IPV4POOL_CIDR/' calico.yaml
sed -i 's/#   value: "192.168.0.0\/16"/  value: "10.1.0.0\/16"/' calico.yaml
kubectl apply -f calico.yaml
