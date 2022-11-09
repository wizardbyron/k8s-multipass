#!/usr/bin/env bash
export PATH=$PATH:/home/$(whoami)/.local/bin

MIRROR=$1

if [ "$MIRROR" == "aliyun" ];then
    MIRROR_URL=mirrors.aliyun.com
elif [ "$MIRROR" == "tencent" ];then
    MIRROR_URL=mirrors.tencent.com
fi

echo "Use mirror pacakge source: $MIRROR_URL"

if [ -n "$MIRROR_URL" ];then
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    sudo sed -i "s/archive.ubuntu.com/$MIRROR_URL/g" /etc/apt/sources.list
fi

sudo sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/g" /etc/needrestart/needrestart.conf # Set auto restart service mode

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y software-properties-common firewalld python3-pip docker.io docker-compose apt-transport-https ca-certificates
sudo systemctl enable --now firewalld
sudo systemctl enable --now docker.service
sudo usermod -aG docker $(whoami)

## Post installation
mkdir $HOME/configs
ssh-keygen -t rsa -P '' -f $HOME/.ssh/identity