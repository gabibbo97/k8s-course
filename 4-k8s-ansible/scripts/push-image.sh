#!/bin/sh
sudo podman image push \
    --tls-verify=false \
    --creds registry-user:registry-password \
    "$1" \
    "registry.k8scourse.serics.eu/$1"
