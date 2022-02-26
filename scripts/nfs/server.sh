#!/usr/bin/env bash
sudo firewall-cmd --permanent --add-service=nfs
sudo firewall-cmd --permanent --add-service=mountd
sudo firewall-cmd --permanent --add-service=rpc-bind
sudo firewall-cmd --reload

sudo apt -y install nfs-kernel-server

sudo mkdir -p /mnt/nfs-root
sudo chown nobody:nogroup /mnt/nfs-root/
sudo chmod 777 /mnt/nfs-root/

sudo sh -c 'echo "/mnt/nfs-root 192.168.64.*(ro,sync,no_subtree_check)" >> /etc/exports'

sudo exportfs -arv