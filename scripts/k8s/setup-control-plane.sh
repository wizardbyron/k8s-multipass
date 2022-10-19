#!/usr/bin/env bash
echo "Check google reachable."
ping -c1 packages.cloud.google.com
GOOGLE_REACHABLE=$?

# Setup firewalld for k8s
echo "Setting up firewalld for k8s, refer to https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/"
sudo firewall-cmd --permanent --add-service=bgp
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=etcd-client
sudo firewall-cmd --permanent --add-service=etcd-server
sudo firewall-cmd --permanent --add-service=kube-apiserver
sudo firewall-cmd --permanent --add-port=10250/tcp # Kubelet API
sudo firewall-cmd --permanent --add-port=10257/tcp # kube-controller-manager
sudo firewall-cmd --permanent --add-port=10259/tcp # kube-scheduler
sudo firewall-cmd --reload

# Install and setup control plane
echo "Setup Kubernetes Control plane."
if [ "$GOOGLE_REACHABLE" -eq 0 ];then
    # K8S_IMAGE_REPO_URL="registry.k8s.io"
    K8S_IMAGE_REPO_URL="k8s.gcr.io"
else
    K8S_IMAGE_REPO_URL="registry.aliyuncs.com/google_containers"
fi
echo "Kubernetes image source: $K8S_IMAGE_REPO_URL"

sudo kubeadm init --v=5 \
    --pod-network-cidr=10.0.0.0/16 \
    --apiserver-advertise-address=$(hostname -I|awk '{print $1}') \
    --image-repository=$K8S_IMAGE_REPO_URL

if [ $? -eq 0 ]; then
    sudo sed -i 's/- --port=0$/#- --port=0/' /etc/kubernetes/manifests/kube-controller-manager.yaml
    sudo sed -i 's/- --port=0$/#- –-port=0/' /etc/kubernetes/manifests/kube-scheduler.yaml

    echo "Setting up kubectl for $(whoami)"
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
else
    exit 1
fi

# Create join-cp.sh for nodes join this control plane
echo "sudo $(kubeadm token create --print-join-command --ttl 0) --v=5" > /mnt/nfs/join-cp.sh
chmod 755 /mnt/nfs/join-cp.sh

# Install and setup calico
echo "Install and configure calico"
curl -o $HOME/configs/calico.yaml https://docs.projectcalico.org/manifests/calico.yaml
sed -i 's/# - name: CALICO_IPV4POOL_CIDR/- name: CALICO_IPV4POOL_CIDR/' $HOME/configs/calico.yaml
sed -i 's/#   value: "192.168.0.0\/16"/  value: "10.0.0.0\/16"/' $HOME/configs/calico.yaml
kubectl apply -f $HOME/configs/calico.yaml

# Install helm
echo "Install helm"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm