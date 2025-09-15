# Pod Security Context Example

This example demonstrates how to use pod-level `securityContext` settings to improve container isolation and security.

## Features
- Sets `runAsUser` and `fsGroup` for all containers in the pod.
- Uses a `seccompProfile` for syscall filtering.

## Attack/Mitigation
- Restricts container processes to a non-root user.
- Limits filesystem access to a specific group.
- Applies syscall restrictions for defense in depth.

## Files
- `pod.yaml`: Pod spec with pod-level securityContext.
- `Makefile`: Deploy/remove the example.
