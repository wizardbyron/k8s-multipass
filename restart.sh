#!/usr/bin/env bash
for INSTANCE in $(multipass list|grep k8s-|awk '{print $1}');do
multipass restart $INSTANCE
done