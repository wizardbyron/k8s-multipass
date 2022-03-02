#!/usr/bin/env bash
NAME_SERVER=$1
sudo apt install -y resolvconf

cat <<EOF | sudo tee /etc/resolvconf/resolv.conf.d/head
nameserver $NAME_SERVER
EOF

sudo resolvconf -u