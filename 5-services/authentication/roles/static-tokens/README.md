# Static tokens

## Via user

```yaml
kubectl apply -f - <<EOF
# role
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
# rolebinding
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: my-static-account-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: User
  name: static-token-user
  namespace: default
EOF
```

## Via group

```yaml
kubectl apply -f - <<EOF
# role
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: configmap-reader
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "watch", "list"]
# rolebinding
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: my-static-group-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: configmap-reader
subjects:
- kind: Group
  name: static-token-users
  namespace: default
EOF
```

## Usage

```bash
curl -k -H 'Authorization: Bearer n7VmDaNueoEbZMYzHObq04udeMZnkte4' https://172.16.42.5:6443/api/v1/namespaces/default/pods
```

```bash
curl -k -H 'Authorization: Bearer n7VmDaNueoEbZMYzHObq04udeMZnkte4' https://172.16.42.5:6443/api/v1/namespaces/default/configmaps
```
