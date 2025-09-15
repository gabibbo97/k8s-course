# Network Policies Example

This folder contains examples of Kubernetes Network Policies that demonstrate how to control network traffic between pods and namespaces.

The examples use two Alpine containers deployed in different namespaces to show various network policy patterns.

## Files:

- `01-workloads.yaml`: Creates two namespaces (`frontend` and `backend`) with Alpine deployments and services
- `02-deny-all-ingress.yaml`: Denies all incoming traffic to pods in the frontend namespace
- `03-deny-all-egress.yaml`: Denies all outgoing traffic from pods in the backend namespace
- `04-allow-frontend-to-backend.yaml`: Allows frontend pods to communicate with backend pods on port 5432
- `05-allow-external-to-frontend.yaml`: Allows external traffic to reach frontend pods on port 8080
- `06-allow-dns-egress.yaml`: Allows DNS traffic (UDP/TCP port 53) from backend pods
- `07-allow-same-namespace.yaml`: Allows communication between pods within the same namespace

## Usage:

Deploy the workloads first:
```bash
make workloads
```

Then apply network policies individually or all at once:
```bash
make policies
```

To test connectivity between pods, exec into a pod and use tools like `nc`, `telnet`, or `ping`.

## Testing Network Policies:

1. Deploy workloads and verify pods are running:
   ```bash
   kubectl get pods -n frontend
   kubectl get pods -n backend
   ```

2. Test connectivity before applying policies:
   ```bash
   kubectl exec -n frontend deployment/frontend-app -- nc -zv backend-service.backend 5432
   ```

3. Apply network policies and test again to see the restrictions in effect.

Here are some example checks you can run after applying specific policies:

- **01-deny-all-ingress.yaml** – from the backend namespace, try to reach the
  frontend service. The connection should be blocked:
  ```bash
  kubectl exec -n backend deployment/backend-app -- nc -zv frontend-service.frontend 80
  ```

- **02-deny-all-egress.yaml** – from the backend namespace, attempt to reach an
  external address. This should fail until egress is allowed:
  ```bash
  kubectl exec -n backend deployment/backend-app -- nc -zv 8.8.8.8 53
  ```

- **03-allow-frontend-to-backend.yaml** – confirm that frontend pods can talk
  to the backend on port 5432:
  ```bash
  kubectl exec -n frontend deployment/frontend-app -- nc -zv backend-service.backend 5432
  ```

- **05-allow-dns-egress.yaml** – after applying the DNS egress rule, verify that
  DNS lookups work from the backend namespace:
  ```bash
  kubectl exec -n backend deployment/backend-app -- nslookup kubernetes.default
  ```

## Cleanup:

```bash
make down
```
