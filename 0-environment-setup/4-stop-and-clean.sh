#!/bin/sh
N_NODES=${N_NODES:-3}

## Stop all
stopService() {
    sudo systemctl stop "$1" &
    sudo systemctl reset-failed "$1" &
}
stopService testbed-dns.service

stopService testbed-registry-proxy-docker-hub.service
stopService testbed-registry-proxy-quay.service
stopService testbed-registry-proxy-k8s.service
stopService testbed-registry-proxy-aws-ecr.service

for node_i in $(seq 1 "${N_NODES}"); do
    stopService "testbed-node${node_i}.service"
done
wait

## Cleanup storage
sudo rm -f \
    disk_node*.qcow2 \
    ci-* \
    ssh.* \
    ssh-node*.sh \
    ansible.inventory

## Remove tap interfaces
find . -name 'qemu-node*.if_name' | while read -r if_file; do
    echo "Removing tap interface $(cat "${if_file}")"
    sudo ip link delete "$(cat "${if_file}")" || true
    sudo rm -f "${if_file}"
done

## Remove bridge
sudo ip link delete br0 || true
