# Kubernetes Node Upgrade Guide

## Prerequisites

- Access to the node (SSH or console)
- Sudo privileges
- Backup important data
  - `cp -r /etc/kubernetes ...` on a server node

## Steps

### 1. Drain the Node

This safely evicts workloads:

```sh
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

### 2. Upgrade kubeadm

Update the `kubeadm` tool:

```sh
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=<version>
sudo apt-mark hold kubeadm
```
Replace `<version>` with the desired Kubernetes version (e.g., `1.29.0-00`).

### 3. Verify Upgrade Plan

Check the upgrade plan:

```sh
sudo kubeadm upgrade plan
```

### 4. Upgrade the Node

Apply the upgrade:

```sh
sudo kubeadm upgrade node
```

### 5. Upgrade kubelet and kubectl

Update the node components:

```sh
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=<version> kubectl=<version>
sudo systemctl restart kubelet
sudo apt-mark hold kubelet kubectl
```

### 6. Uncordon the Node

Bring the node back online:

```sh
kubectl uncordon <node-name>
```

## Notes

- Repeat for each node in the cluster.
- Monitor workloads