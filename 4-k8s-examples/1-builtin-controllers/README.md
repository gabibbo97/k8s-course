# Builtin controllers

Please find here some examples of builtin controllers in Kubernetes.

- `replicaset.yaml`: example of a ReplicaSet controller, which ensures that a specified number of pod replicas are running at any given time.
- `deployment.yaml`: example of a Deployment controller, which provides declarative updates for Pods and ReplicaSets.
- `statefulset.yaml`: example of a StatefulSet controller, which manages the deployment and scaling of a set of Pods, and provides guarantees about the ordering and uniqueness of these Pods.
- `daemonset.yaml`: example of a DaemonSet controller, which ensures that all (or some) Nodes run a copy of a Pod.
- `job.yaml`: example of a Job controller, which creates one or more Pods and ensures that a specified number of them successfully terminate.
- `cronjob.yaml`: example of a CronJob controller, which creates Jobs on a time-based schedule
