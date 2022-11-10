#!/usr/bin/env bash
MIRROR_URL=$1

if [ -n "$MIRROR_URL" ];then
    echo "Install pacakges from mirror source: $MIRROR_URL"
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    sudo sed -i "s/archive.ubuntu.com/$MIRROR_URL/g" /etc/apt/sources.list
fi

# Set auto restart service mode
sudo sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/g" /etc/needrestart/needrestart.conf

# Update source and install packages
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y firewalld docker-compose software-properties-common apt-transport-https ca-certificates

# Post installation
sudo systemctl enable --now firewalld
sudo systemctl enable --now docker.service
sudo usermod -aG docker $(whoami)

# Create ssh-key
mkdir $HOME/configs
ssh-keygen -t rsa -P '' -f $HOME/.ssh/identity