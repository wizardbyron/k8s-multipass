#!/usr/bin/env bash

KUBE_VERSION="latest" # latest or given version
MIRROR="aliyun" # <empty>/aliyun
NODES=2

multipass launch --name k8s-control-panel --cpus 4 --mem 4G --disk 20G
multipass mount $(pwd)/scripts k8s-control-panel:/opt/k8s/
multipass mount $(pwd)/share k8s-control-panel:/share

CONTROL_PANEL_IP=$(multipass list|grep k8s-control-panel| awk '{print $3}')
multipass exec k8s-control-panel -- . /opt/k8s/init.sh $MIRROR
multipass exec k8s-control-panel -- . /opt/k8s/install-k8s.sh $KUBE_VERSION $MIRROR
multipass exec k8s-control-panel -- . /opt/k8s/setup-control-panel.sh $CONTROL_PANEL_IP $MIRROR

for i in $(seq 1 $NODES) ;do
multipass launch --name k8s-node-$i --cpus 2 --mem 2G --disk 10G
multipass mount $(pwd)/scripts k8s-node-$i:/opt/k8s/
multipass mount $(pwd)/share k8s-node-$i:/share
multipass exec k8s-node-$i -- . /opt/k8s/init.sh $MIRROR
multipass exec k8s-node-$i -- . /opt/k8s/install-k8s.sh $KUBE_VERSION $MIRROR
multipass exec k8s-node-$i -- . /opt/k8s/setup-worker-node.sh
done