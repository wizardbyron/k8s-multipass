#!/usr/bin/env bash
echo "Setting up firewalld, refer to https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/"
sudo firewall-cmd --permanent --add-service=bgp # For Calico BGP
sudo firewall-cmd --permanent --add-port=10250/tcp # Kubelet API
sudo firewall-cmd --permanent --add-port=30000-32767/tcp
sudo firewall-cmd --reload

sudo sh -c "/mnt/nfs-root/join-cluster.sh"
