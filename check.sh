#!/usr/bin/env bash
set -e

function check_all_nodes_ready(){
    READY_NODES=$(multipass exec k8s-control-panel -- kubectl get nodes|grep "Ready"|wc -l)
    NOT_READY_NODES=$(multipass exec k8s-control-panel -- kubectl get nodes|grep "NotReady"|wc -l)
    echo "$READY_NODES node(s) are Ready, $NOT_READY_NODES node(s) are NotReady."
    if [ -z "$NOT_READY_NODES" ];then
        echo "These node(s) are not ready:"
        multipass exec k8s-control-panel -- kubectl get nodes|grep NotReady
    fi
}

CONTROL_PANEL_STATUS=$(multipass list|grep k8s-control-panel|awk '{print $2}')
if [ "$CONTROL_PANEL_STATUS" == "Running" ];then
    check_all_nodes_ready
    exit 0
else
    echo  "ERROR: k8s-control-panel instance is not running."
    exit 1
fi
