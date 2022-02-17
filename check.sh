#!/usr/bin/env bash
set -e
CONTROL_PANEL_STATUS=$(multipass list|grep k8s-control-panel|awk '{print $2}')

if [ "$CONTROL_PANEL_STATUS" == "Running" ];then
    READY_NODES=$(multipass exec k8s-control-panel -- kubectl get nodes|grep "Ready"|awk '{print $2}'|wc -l)
    NOT_READY_NODES=$(multipass exec k8s-control-panel -- kubectl get nodes|grep "NotReady"|awk '{print $2}'|wc -l)
    echo "$READY_NODES node(s) are Ready, $NOT_READY_NODES node(s) are NotReady."
    if [ -z "$NOT_READY_NODES" ];then
        echo "These node(s) are not ready:"
        multipass exec k8s-control-panel -- kubectl get nodes|grep NotReady
    fi
else
    echo  "ERROR: k8s-control-panel instance is not running."
fi
