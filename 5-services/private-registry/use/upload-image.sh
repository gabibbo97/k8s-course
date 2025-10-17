#!/bin/sh
sudo podman image push \
    --creds=registry-user:registry-password \
    --tls-verify=false \
    "$1" \
    registry.k8scourse.serics.eu/"$2"
