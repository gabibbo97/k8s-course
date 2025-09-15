# Stateful Application

This example shows how to deploy a stateful application using a StatefulSet, a Headless Service, and a PersistentVolumeClaim (PVC).

The application is an alpine pod that mounts a PVC and writes the current date to a file every 5 seconds.

Files:

- `statefulset.yaml`: defines a StatefulSet that manages a set of alpine pods.
- `headless-service.yaml`: defines a Headless Service that allows the StatefulSet to manage the network identities of its pods.
- `pvc.yaml`: defines a PersistentVolumeClaim that requests storage from a PersistentVolume.
