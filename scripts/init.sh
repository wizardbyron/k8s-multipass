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

sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y software-properties-common firewalld python3-pip docker.io apt-transport-https ca-certificates
sudo systemctl enable --now firewalld

### Upgrade pip
echo "Upgrade pip."
if [ -n "$MIRROR_URL" ];then
    sudo sh -c "python3 -m pip install --upgrade -i https://$MIRROR_URL/pypi/simple pip"
else
    sudo sh -c "python3 -m pip install --upgrade pip"
fi

# install docker-compose
pip install --user docker-compose


## Post installation
mkdir $HOME/configs
ssh-keygen -t rsa -P '' -f $HOME/.ssh/identity

## Set Alias
alias pip="python3 -m pip"