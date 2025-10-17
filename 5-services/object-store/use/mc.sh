#!/bin/sh
sudo podman run --rm -it \
    --network=host \
    --volume minio-mc:/root/.mc:z \
    quay.io/minio/mc:RELEASE.2025-08-13T08-35-41Z \
    --insecure alias set local https://s3.k8scourse.serics.eu minio minio123 > /dev/null
sudo podman run --rm -it \
    -v "$PWD:$PWD:z" \
    -w "$PWD" \
    --network=host \
    --volume minio-mc:/root/.mc:z \
    quay.io/minio/mc:RELEASE.2025-08-13T08-35-41Z \
    --insecure "$@"
sudo podman volume rm -f minio-mc > /dev/null