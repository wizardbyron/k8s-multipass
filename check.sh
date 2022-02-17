#!/usr/bin/env bash
set -e

NODE_STATUS=$(multipass exec k8s-control-panel -- kubectl get nodes|awk '{print $2}')

for STATUS in $NODE_STATUS; do
    if [ "$STATUS" == "NotReady" ];then
        ALL_READY=0
        break;
    fi
done

if [ -z "$ALL_READY" ];then
    echo "All nodes are ready."    
else
    echo "These node(s) are not ready:"
    multipass exec k8s-control-panel -- kubectl get nodes|grep NotReady
fi