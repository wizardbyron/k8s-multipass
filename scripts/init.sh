#!/usr/bin/env bash

export PATH=$PATH:/home/$(whoami)/.local/bin

KUBE_VERSION=$1

echo "Check google package source reachable."
curl -f -s http://packages.cloud.google.com

if [ $? -ne 0 ];then
    MIRROR_URL=mirrors.aliyun.com
    echo "Use mirror pacakge source: $MIRROR_URL"
fi

if [ -n "$MIRROR_URL" ];then
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    sudo sed -i "s/archive.ubuntu.com/$MIRROR_URL/g" /etc/apt/sources.list
fi

sudo apt update -y
sudo apt install -y software-properties-common firewalld python3-pip docker.io apt-transport-https ca-certificates
sudo apt full-upgrade -y
sudo systemctl enable --now firewalld
python3 -m pip install --upgrade pip

### Upgrade pip
echo "Upgrade pip."
if [ -n "$MIRROR_URL" ];then
    sudo sh -c "python3 -m pip install --upgrade -i https://$MIRROR_URL/pypi/simple pip"
else
    sudo sh -c "python3 -m pip install --upgrade pip"
fi

pip install --user docker-compose

# Install calicoctl
echo "Install calicoctl"
sudo curl -L https://github.com/projectcalico/calico/releases/download/v3.22.0/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
sudo chmod +x /usr/local/bin/calicoctl

## Post installation
mkdir $HOME/configs
ssh-keygen -t rsa -P '' -f $HOME/.ssh/identity

## Set Alias
alias pip="python3 -m pip"