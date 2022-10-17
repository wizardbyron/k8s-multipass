#!/usr/bin/env bash
SERVER_IP=$1
sudo apt -y install nfs-common
sudo mkdir -p /mnt/nfs
sudo mount $SERVER_IP:/mnt/nfs /mnt/nfs