#!/usr/bin/env bash


# Setup firewalld for k8s
function setup_firewalld(){
    echo "Setting up firewalld for k8s, refer to https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/"
    sudo firewall-cmd --zone=public --permanent --add-port=179/tcp # For Calico BGP
    sudo firewall-cmd --zone=public --permanent --add-port=2379-2380/tcp
    sudo firewall-cmd --zone=public --permanent --add-port=6443/tcp
    sudo firewall-cmd --zone=public --permanent --add-port=8000/tcp
    sudo firewall-cmd --zone=public --permanent --add-port=10250-10252/tcp
    sudo firewall-cmd --reload
    return $?
}

function setup_flannel(){
    echo "Install and configure flannel"
    curl -o $HOME/configs/kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    sed -i 's/- --kube-subnet-mgr$/- --kube-subnet-mgr\n        - --iface=eth1/' $HOME/configs/kube-flannel.yml
    sed -i 's/10.244.0.0\/16/192.168.0.0\/16/' $HOME/configs/kube-flannel.yml
    kubectl create -f $HOME/configs/kube-flannel.yml
    return $?
}

function setup_calico(){
    echo "Install and configure calico"
    curl -o $HOME/configs/calico.yaml https://docs.projectcalico.org/manifests/calico.yaml
    sed -i 's/# - name: CALICO_IPV4POOL_CIDR/- name: CALICO_IPV4POOL_CIDR/' $HOME/configs/calico.yaml
    sed -i 's/#   value: "192.168.0.0\/16"/  value: "192.168.0.0\/16"/' $HOME/configs/calico.yaml
    kubectl apply -f $HOME/configs/calico.yaml
    return $?
}

# Initial k8s master cluster
function setup_control_panel(){
    CONTROL_PANEL_IP=$1
    K8S_IMAGE_REPO=$2
    echo "Setup Kubernetes Control Panel, IP: $CONTROL_PANEL_IP, Image Ropo: $K8S_IMAGE_REPO"
    sudo sh -c "echo '$(hostname -i) k8scp' >> /etc/hosts"
    if [ "$K8S_IMAGE_REPO" = "aliyun" ];then
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
}


setup_firewalld
setup_control_panel $1 $2
# setup_calico
setup_flannel

# create join-cluster.sh
echo "$(kubeadm token create --print-join-command --ttl 0) --v=5" > /share/join-cluster.sh
chmod 755 /share/join-cluster.sh

# Install helm
echo "Install helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

