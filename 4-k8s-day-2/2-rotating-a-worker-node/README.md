# Assumptions

* You are rotating nodes **one at a time**.
* Control plane is healthy and **not** part of this rotation.
* You have SSH access and `kubectl` admin access.
* Your workloads can tolerate eviction according to their **PodDisruptionBudgets (PDBs)**.

---

# Safety checks (do before every node)

```bash
# Cluster health & capacity
kubectl get nodes -o wide
kubectl -n kube-system get pods -o wide
kubectl get poddisruptionbudgets -A
kubectl get events -A --sort-by=.lastTimestamp | tail -n 50

# Ensure replicas > 1 where needed; note PDBs that might block drain
kubectl get deploy,statefulset,daemonset -A -o wide
```

If you’re close to capacity, temporarily scale up another worker first.

---

# Capture the node’s “personality” (labels & taints)

You’ll want to re-apply these to the replacement node.

```bash
NODE=<node-to-rotate>

# Labels
kubectl get node $NODE --show-labels

# Taints
kubectl get node $NODE -o json
```

---

# Cordon & drain the old node

```bash
NODE=<node-to-rotate>

# Prevent new pods from scheduling
kubectl cordon $NODE

# Evict workload pods; ignore DaemonSets; delete EmptyDir data
kubectl drain $NODE \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=120 \
  --timeout=30m

# If PDBs block drain, you’ll see it hang. Options:
#  - temporarily relax PDBs or scale replicas up
#  - for quick maintenance windows: add --disable-eviction for a hard drain (last resort)
```

---

# Remove from the cluster (after pods are gone)

```bash
kubectl delete node $NODE
```

---

# Prepare the new worker node

Title

# Join the new worker to the cluster

From a **control-plane** node:

```bash
# Get the join command (valid for 24h by default)
kubeadm token create --print-join-command
```

Run that **on the new worker**:

```bash
sudo kubeadm join <api-server>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

Verify it appears:

```bash
kubectl get nodes -o wide
```

---

# Reapply labels & taints to the new node

```bash
NEWNODE=<new-node-name>

# Labels
kubectl label node "$NEWNODE" "key=value" --overwrite

# Taints
kubectl taint node "$NEWNODE" key=value:NoSchedule --overwrite
```

---

Confirm:

* Node is **Ready**.
