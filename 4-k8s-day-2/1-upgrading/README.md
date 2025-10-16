# Kubernetes Node Upgrade Guide

## Prerequisites

- Access to the node (SSH or console)
- Sudo privileges
- Backup important data
  - `cp -r /etc/kubernetes ...` on a server node

## Autmated upgrade

This assumes there exists a kubeconfig file at `/etc/kubernetes/admin.conf` (for all nodes).

```sh
# settings
export NODE_NAME=<node-name>
export K8S_VERSION=<version>
export KUBECONFIG=/etc/kubernetes/admin.conf
export IS_FIRST_CONTROL_PLANE=1

# checks
if ! [ -f "${KUBECONFIG}" ]; then
  echo "KUBECONFIG file not found!"
  exit 1
fi

# cordon
kubectl drain "${NODE_NAME}" --ignore-daemonsets --delete-emptydir-data

# upgrade kubeadm
apt-mark unhold kubeadm
apt-get update
apt-get install -y kubeadm="${K8S_VERSION}-1.1"
apt-mark hold kubeadm

# upgrade node
if [ $IS_FIRST_CONTROL_PLANE -eq 1 ]; then
  kubeadm upgrade plan "${K8S_VERSION}" --yes
  kubeadm upgrade apply "${K8S_VERSION}" --yes
else
  kubeadm upgrade node --yes
fi

# upgrade kubelet and kubectl
apt-mark unhold kubelet kubectl
apt-get update
apt-get install -y kubelet="${K8S_VERSION}-1.1" kubectl="${K8S_VERSION}-1.1"
apt-mark hold kubelet kubectl
systemctl daemon-reload
systemctl restart kubelet

# uncordon
kubectl uncordon "${NODE_NAME}"
```
