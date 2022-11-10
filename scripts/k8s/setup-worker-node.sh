#!/usr/bin/env bash
echo "Setting up firewalld, refer to https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/"
sudo firewall-cmd --permanent --add-service=bgp # For Calico BGP
sudo firewall-cmd --permanent --add-service=kubelet-worker # For Calico BGP
sudo firewall-cmd --reload

sudo sh -c "/mnt/nfs/join-cp.sh"
