# HostPath Mount Pivoting

This example shows how mounting host paths into a container can allow an attacker to access sensitive files and potentially compromise the host and cluster.

## Attack Scenario
- The pod uses the public.aws.ecr/docker/library/alpine:3.22 image.
- The container mounts `/etc` from the host using `hostPath`.
- Attacker can read/modify host configuration files.

## Mitigation
- Avoid using hostPath mounts unless absolutely necessary.
- Use PodSecurityPolicies to restrict hostPath usage.

## Files
- `pod.yaml`: Pod spec with hostPath mount.
- `Makefile`: Deploy/remove the example.
