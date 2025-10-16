# Extra Capabilities Pivoting

This example demonstrates how granting extra Linux capabilities (e.g., NET_ADMIN) to a container can allow an attacker to perform actions that may compromise the cluster.

## Attack Scenario
- The pod uses the public.aws.ecr/docker/library/alpine:3.22 image.
- The container is granted the `NET_ADMIN` capability.
- Attacker can manipulate network interfaces, routing, etc.

## Mitigation
- Grant only the minimum capabilities required.
- Use PodSecurityPolicies to restrict capabilities.

## Files
- `pod.yaml`: Pod spec with extra capabilities.
- `Makefile`: Deploy/remove the example.
