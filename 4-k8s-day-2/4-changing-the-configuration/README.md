# Changing the cluster configuration

## Cluster configuration

1. Edit the ClusterConfiguration

```sh
kubectl edit configmap -n kube-system kubeadm-config
```

### On control plane nodes

Download the config file and upload to the node: `kubectl -n kube-system get configmap kubeadm-config -o yaml > config.yaml`

```sh
# Certificates
kubeadm init phase certs <component-name> --config <config-file>

# For Kubernetes control plane components flags
kubeadm init phase control-plane <component-name> --config <config-file>

# For local etcd flags
kubeadm init phase etcd local --config <config-file>
```

## Kubelet configuration

1. Edit the KubeletConfiguration

```sh
kubectl edit configmap -n kube-system kubelet-config
```

### On each node

1. `kubeadm upgrade node phase kubelet-config`
2. `systemctl restart kubelet`