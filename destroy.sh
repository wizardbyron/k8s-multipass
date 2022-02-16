#!/usr/bin/env bash
for instance in $(multipass list|grep k8s-|awk '{print $1}');do
multipass stop $instance
multipass delete $instance -p
done