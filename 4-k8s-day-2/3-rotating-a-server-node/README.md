# Assumptions

* Cluster bootstrapped with **kubeadm**.
* You have `kubectl` admin access and SSH to nodes.
* Control plane is fronted by a VIP/load balancer (e.g., keepalived + HAProxy) at `LB_VIP:6443`.

### Confirm cluster health

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get --raw='/readyz?verbose'
```

### Capture labels/taints of the node to be rotated (useful to reapply)

```bash
NODE=old-worker-01
kubectl get node "$NODE" -o json | jq -r '.metadata.labels' > /tmp/"$NODE"-labels.json
kubectl get node "$NODE" -o json | jq -r '.spec.taints // []'  > /tmp/"$NODE"-taints.json
```

---

# Rotate a **Control-Plane** Node (kubeadm)

There are two common patterns:

* **HA control plane (recommended):** Add a new control-plane node, then remove the old one (zero/minimal API downtime).
* **Single control plane:** Temporarily add a second control-plane node, fail traffic over, then remove the old one (brief risk window while joining). 
 
If you truly must keep single-node CP, you can use an etcd snapshot/restore path, but the join-a-new-CP method is simpler and safer.

## Pre-checks

* Your load balancer (e.g., HAProxy) points to **all** healthy control-plane node IPs on `:6443`.
* Get the certificate key so new CP can fetch certs:

```bash
# On an existing CP:
kubeadm init phase upload-certs --upload-certs
# Output: a 64-char hex "certificate key" (save it)
```

* Get a control-plane join command:

```bash
kubeadm token create --print-join-command
# You will append:  --control-plane --certificate-key <KEY>
```

## Prepare the **new control-plane** host

Title

## Join the **new control-plane** node

On the **new** CP:

```bash
kubeadm join LB_VIP:6443 --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH> \
  --control-plane --certificate-key <CERT_KEY>
```

Wait for static pods (`kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, and local `etcd` if stacked) to come up:

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system -o wide
```

## Update/load balancer & verify readiness

* Add the new CP node’s `:6443` to your LB backend (if not auto-discovered).
* Verify API health via LB:

```bash
kubectl get --raw='https://LB_VIP:6443/readyz?verbose' --insecure-skip-tls-verify
```

## Drain and remove the **old control-plane** node

1. Take it **out of the LB** backends for `:6443`.
2. Cordon & drain CP workloads (only control-plane static pods run there; user workloads should be on workers).

```bash
OLD_CP=cp-01
kubectl cordon "$OLD_CP"
kubectl drain "$OLD_CP" --ignore-daemonsets --delete-emptydir-data --grace-period=60 --timeout=15m
```

3. Remove the node from the cluster and clean it:

```bash
kubectl delete node "$OLD_CP"
# On the old CP host:
sudo kubeadm reset -f
```

## Reconcile labels/taints (if the CP was schedulable)

Control planes are often tainted to avoid scheduling workload pods. If you had custom labels or if you allow scheduling:

```bash
NEW_CP=cp-new-01
# Example: ensure default CP taint exists (if desired)
kubectl taint node "$NEW_CP" node-role.kubernetes.io/control-plane=:NoSchedule --overwrite
```

---

# Post-Rotation Checks

```bash
kubectl get nodes -o wide
kubectl get pods -A --field-selector=status.phase!=Running -o wide
kubectl get events -A --sort-by=.lastTimestamp | tail -n 50
```
