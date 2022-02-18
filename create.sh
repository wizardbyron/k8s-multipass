#!/usr/bin/env bash

K8S_VER="latest" # latest or given version
MIRROR="aliyun" # <empty>/aliyun
NODES=2

function cluster_cmd(){
    COMMAND=$1
    for INSTANCE in $(multipass list|grep k8s-|awk '{print $1}');do
    multipass $COMMAND $INSTANCE
    done
}

function setup_control_panel(){
    multipass launch --name k8s-control-panel --cpus 4 --mem 4G --disk 20G
    multipass mount $(pwd)/scripts k8s-control-panel:/opt/k8s/
    multipass mount $(pwd)/share k8s-control-panel:/share
    multipass exec k8s-control-panel -- . /opt/k8s/init.sh $MIRROR $K8S_VER
    multipass exec k8s-control-panel -- . /opt/k8s/setup-control-panel.sh $MIRROR
}

function setup_node(){
    NODE_INDEX=$1
    multipass launch --name k8s-node-$NODE_INDEX --cpus 2 --mem 2G --disk 10G
    multipass mount $(pwd)/scripts k8s-node-$NODE_INDEX:/opt/k8s/
    multipass mount $(pwd)/share k8s-node-$NODE_INDEX:/share
    multipass exec k8s-node-$NODE_INDEX -- . /opt/k8s/init.sh $MIRROR $K8S_VER
    multipass exec k8s-node-$NODE_INDEX -- . /opt/k8s/setup-worker-node.sh
}

function create_cluster(){
    setup_control_panel
    for INDEX in $(seq 1 $NODES) ;do
        setup_node $INDEX &
    done
    wait

}

create_cluster
echo "Kubernetes cluster has been setup, Please restart all nodes by `./restart.sh`"