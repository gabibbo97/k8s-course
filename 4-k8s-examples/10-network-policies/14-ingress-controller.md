# Ingress Controller

We want:
- Ingress controller to be able to connect any pod in the cluster
- Ingress controller to be accessible by an external load balancer

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      kubernetes.io/app: ingress-controller
  policyTypes:
    - Ingress
    - Egress
  ingress:
    from:
    - ipBlock:
        cidr: 172.16.42.1/32
    - namespaceSelector: {}
  egress:
    to:
    - ipBlock:
        cidr: 172.16.42.1/32
    - namespaceSelector: {}
```
