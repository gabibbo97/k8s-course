# Authentication via client CA

## Example: Authenticating to Kubernetes using a client CA (self-signed via cert-manager)

This example demonstrates how to authenticate to a Kubernetes cluster using a client certificate signed by a custom Certificate Authority (CA) managed by cert-manager.

### 1. Prerequisites

- cert-manager installed in your cluster
- Cluster admin access
- `kubectl` and `openssl` installed locally

### 2. Create a Self-Signed CA with cert-manager

See the manifests inside the role

**PLEASE NOTE THAT ON KUBEADM CLUSTERS YOU WILL DESTROY YOUR TOKENS, SO IF YOU WANT TO PRESERVE THEM, USE THE ORIGINAL KUBERNETES CA CERTIFICATE AUTHORITY**

### 3. Issue a Client Certificate

See the manifests inside the role

After a few seconds, the secret `demo-user-cert` will contain the user's certificate and key.

### 4. Configure the Kubernetes API Server

Edit the API server manifest (usually `/etc/kubernetes/manifests/kube-apiserver.yaml`) to add:

```
--client-ca-file=/etc/kubernetes/pki/client-ca.crt
```

Copy the CA certificate from the `client-ca-secret` to the specified location on ALL of the control plane nodes.

Restart the API server if necessary.

### 5. Configure kubectl for the User

Extract the certificate and key from the `demo-user-cert` secret:

```bash
kubectl get secret demo-user-cert -n cert-manager -o jsonpath='{.data.tls\.crt}' | base64 -d > demo-user.crt
kubectl get secret demo-user-cert -n cert-manager -o jsonpath='{.data.tls\.key}' | base64 -d > demo-user.key
kubectl get secret client-ca-secret -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d > client-ca.crt
```

Set up a new context in your kubeconfig:

```bash
kubectl config set-credentials demo-user \
	--client-certificate=demo-user.crt \
	--client-key=demo-user.key
kubectl config set-context demo-user-context \
	--cluster=<your-cluster-name> \
	--user=demo-user
kubectl config set-cluster <your-cluster-name> \
	--certificate-authority=client-ca.crt \
	--server=https://<api-server-endpoint>
kubectl config use-context demo-user-context
```

### 6. Test Authentication

Try to list pods (access will depend on RBAC):

```bash
kubectl get pods --all-namespaces
```

If RBAC is not configured for this user, you may get a `forbidden` error, which means authentication worked but authorization is missing.
