# Privileged Container Pivoting

This example demonstrates how running a container with `privileged: true` can allow an attacker to escape the container and compromise the host and cluster.

## Attack Scenario
- The pod uses the public.aws.ecr/docker/library/alpine:3.22 image.
- The container is started with `privileged: true`.
- Attacker can access host devices, load kernel modules, and potentially escape to the host.

## Mitigation
- Never run containers as privileged unless absolutely necessary.
- Use PodSecurityPolicies or Pod Security Standards to restrict privileged containers.

## Files
- `pod.yaml`: Pod spec with privileged container.
- `Makefile`: Deploy/remove the example.
