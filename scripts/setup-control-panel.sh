#!/usr/bin/env bash

CONTROL_PANEL_IP=$1
K8S_IMAGE_REPO=$2

# Setup firewalld for k8s
echo "Setting up firewalld for k8s, refer to https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/"
sudo firewall-cmd --zone=public --permanent --add-port=179/tcp # For Calico BGP
sudo firewall-cmd --zone=public --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8000/tcp
sudo firewall-cmd --zone=public --permanent --add-port=10250-10252/tcp
sudo firewall-cmd --reload

# Install and setup control panel
echo "Setup Kubernetes Control Panel, IP: $CONTROL_PANEL_IP, Image Ropo: $K8S_IMAGE_REPO"
sudo sh -c "echo '$(hostname -i) k8scp' >> /etc/hosts"
if [ -n "$K8S_IMAGE_REPO" ];then
    K8S_IMAGE_REPO_URL="registry.aliyuncs.com/google_containers"
else
    K8S_IMAGE_REPO_URL="k8s.gcr.io"
fi

sudo kubeadm init --v=5 \
    --image-repository=$K8S_IMAGE_REPO_URL \
    --apiserver-advertise-address=$CONTROL_PANEL_IP \
    --service-cidr=10.0.0.0/16 \
    --pod-network-cidr=192.168.0.0/16

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

# Install and setup calico
echo "Install and configure calico"
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
cat <<EOF | sudo tee $HOME/configs/calico.yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 26
      cidr: $CONTROL_PANEL_IP/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF
kubectl create -f $HOME/configs/calico.yaml

# Create join-cluster.sh
echo "$(kubeadm token create --print-join-command --ttl 0) --v=5" > /share/join-cluster.sh
chmod 755 /share/join-cluster.sh

# Install helm
echo "Install helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

