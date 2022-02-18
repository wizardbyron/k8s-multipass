# k8s-multipass

Create & destroy a Kubernetes cluster by [Multipass](https://multipass.run).

## Introduction

This repo contains serveral scripts and configuration files that allow you to setup a k8s cluster with 2 nodes(default).

`create.sh` will create a kubernetes control panel node named `k8s-control-panel` and two(default) nodes named `k8s-node-1` and `k8s-node-2` by multipass.

`check.sh` will check nodes are ready.

`destory.sh` will stop and purge all nodes.

`stop.sh` will stop all nodes.

`start.sh` will start all nodes.

`restart.sh` will restart all nodes.

## Prerequisites

* PC with Internet and enough memory and disk space. (Seriously!!!)
* [Multipass](https://multipass.run/)

## Usage

1. Clone this repo: `git clone git@github.com:wizardbyron/provisioners.git`.
2. Update node numbers and it's vCPU, Memory and Disk settings in `create.sh`.
3. Create the cluster simply by `create.sh` and `check.sh` will check all nodes are ready.
4. You can login the control panel by `multipass shell k8s-cluster`.
5. Destroy the cluster simply by `destory.sh` as well.
6. Enjoy your cluster.

## LICENSE

[LICENSE](/LICENSE)
