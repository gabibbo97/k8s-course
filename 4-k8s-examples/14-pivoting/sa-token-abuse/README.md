# ServiceAccount Token Abuse

This example demonstrates how a compromised pod can use its ServiceAccount token to access the Kubernetes API and escalate privileges.

## Attack Scenario
- The pod uses the public.aws.ecr/docker/library/alpine:3.22 image.
- The container reads its ServiceAccount token and uses it to access the Kubernetes API.
- Attacker can list secrets, create pods, etc., depending on RBAC.

## Mitigation
- Use least-privilege RBAC for ServiceAccounts.
- Disable automounting ServiceAccount tokens if not needed.

## Files
- `pod.yaml`: Pod spec with default ServiceAccount.
- `Makefile`: Deploy/remove the example.
