#!/usr/bin/env bash
set -e

READY_NODES=$(multipass exec k8s-control-panel -- kubectl get nodes|grep "Ready"|awk '{print $2}'|wc -l)
NOT_READY_NODES=$(multipass exec k8s-control-panel -- kubectl get nodes|grep "NotReady"|awk '{print $2}'|wc -l)

echo "$READY_NODES node(s) are Ready, $NOT_READY_NODES node(s) are NotReady."

if [ -z "$NOT_READY_NODES" ];then
    echo "These node(s) are not ready:"
    multipass exec k8s-control-panel -- kubectl get nodes|grep NotReady
elif [ ! -z "READY_NODES" ] && [ "$NOT_READY_NODES" -eq 0 ];then
    echo "All nodes are ready."
fi
