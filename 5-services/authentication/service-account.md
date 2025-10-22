# Authenticating via service accounts

## Example: Creating and Using a Service Account for Kubernetes Authentication

This example demonstrates how to:
- Create a service account
- Assign roles to it
- Retrieve its token
- Authenticate to Kubernetes using the service account

### 1. Create a Service Account

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-serviceaccount
  namespace: default
# if this is specified pods with this ServiceAccount are restricted to these secrets
# secrets:
# - kind: Secret
#   name: my-secret
#   namespace: my-namespace
EOF
```

### 2. Assign a Role to the Service Account

For example, to grant read access to pods in the `default` namespace:

```bash
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
EOF
```

Then we associate a role binding (via client)

```bash
kubectl create rolebinding my-service-account-binding \
	--role=pod-reader \
	--serviceaccount=default:my-serviceaccount \
	-n default
```

or via API

```bash
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: my-service-account-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: ServiceAccount
  name: my-serviceaccount
  namespace: default
EOF
```

### 3. Retrieve the Service Account Token

Tokens are stored as secrets referenced by ServiceAccount. 

To get a token:

```bash
token=$(kubectl create token my-serviceaccount -n default)
echo $token
echo $token | cut -d . -f 1 | base64 -d | jq
echo $token | cut -d . -f 2 | base64 -d | jq
```

### 4. Use the Token to Authenticate (e.g., with kubectl)

You can use the token to configure a new context in your kubeconfig:

```bash
kubectl config set-credentials my-service-account \
	--token=<PASTE_TOKEN_HERE>
kubectl config set-context my-sa-context \
	--cluster=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}') \
	--user=my-serviceaccount \
	--namespace=default
kubectl config use-context my-sa-context
```

Now, any `kubectl` command will use the service account's permissions.

```bash
curl -k -H "Authorization: Bearer $token" https://172.16.42.5:8443/api/v1/namespaces/default/pods
```

### References

- [Kubernetes Service Accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
