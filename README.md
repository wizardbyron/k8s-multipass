# k8s-multipass

Create & destroy a Kubernetes cluster by [Multipass](https://multipass.run).

## Prerequisites

* PC with Internet and enough memory and disk space. (Seriously!!!)
* [Multipass](https://multipass.run/)

## Usage

1. Clone this repo.
2. Execute `./k8sctl [create|start|stop|restart|destroy]` to create/start/stop/restart/destroy the cluster which has 1 control plane and 2 nodes.
3. (Option)You can excute `./k8sctl check` to check all nodes and pods are ready.
4. (Option)You can excute `./k8sctl status` to check cluster status.
5. You can login the control plane node by `./k8sctl login`. Or `multipass shell` with instance name like `k8s-control-plane`,`k8s-node-1`.

## LICENSE

[LICENSE](/LICENSE)
