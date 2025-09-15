#!/bin/sh
REGISTRY_IMAGE='public.ecr.aws/docker/library/registry:3.0.0'

# create registry data dir
mkdir -p registry-data

# run registry proxies
runProxy() {
    name=$1
    full_name=$2
    port=$3
    remoteUrl=$4
    sudo systemctl stop "testbed-registry-proxy-${name}.service" >/dev/null 2>&1 || true
    sudo systemctl reset-failed "testbed-registry-proxy-${name}.service" >/dev/null 2>&1 || true
    sudo systemd-run \
        --unit="testbed-registry-proxy-${name}.service" \
        --description="Testbed Registry proxy (${full_name})" \
        --remain-after-exit \
        podman run --replace --name "registry-proxy-${name}" \
            --network host \
            -v "$(pwd)/registry-data:/var/lib/registry:z" \
            -e "REGISTRY_PROXY_REMOTEURL=${remoteUrl}" \
            -e "REGISTRY_HTTP_ADDR=172.16.42.1:${port}" \
            -e "REGISTRY_HTTP_DEBUG_ADDR=172.16.42.1:$((port + 1000))" \
            -e REGISTRY_STORAGE_DELETE_ENABLED=true \
            -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry \
            "${REGISTRY_IMAGE}"
}

runProxy docker-hub "Docker Hub" 5000 https://registry-1.docker.io
runProxy quay       "Quay"       5001 https://quay.io
runProxy k8s        "k8s"        5002 https://registry.k8s.io
runProxy aws-ecr    "AWS ECR"    5003 https://public.ecr.aws
