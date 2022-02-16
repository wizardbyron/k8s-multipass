#!/usr/bin/env bash
set -e
export PATH=$PATH:/home/$(whoami)/.local/bin

MIRROR=$1
if [ "$MIRROR" = "tencent" ];then
    MIRROR_URL=mirrors.tencent.com
elif [ "$MIRROR" = "aliyun" ];then
    MIRROR_URL=mirrors.aliyun.com
fi

if [ -n "$MIRROR_URL" ];then
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    sudo sed -i "s/archive.ubuntu.com/$MIRROR_URL/g" /etc/apt/sources.list
fi

sudo apt update -y
sudo apt install -y software-properties-common git firewalld curl python3-pip unzip docker.io tcpdump ntp openssh-server
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

### Setup Docker
if [ $? = 0 ]; then
    sudo usermod -aG docker $(whoami)
    sudo systemctl enable --now docker.service
    sudo systemctl restart docker
else
    echo "Install docker-ce failed, Please retry or install with mirror."
    exit 1
fi



## post installation
mkdir $HOME/configs
ssh-keygen  -t rsa -P '' -f $HOME/.ssh/identity

## Alias
alias pip="python3 -m pip"