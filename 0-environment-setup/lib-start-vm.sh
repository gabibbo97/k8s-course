#!/bin/sh

NODE_N=${NODE_N:-1}

#
# tunables
#

## Enable KSM
echo 1 | sudo tee /sys/kernel/mm/ksm/run || true

#
# disk
#
disk_name="disk_node${NODE_N}.qcow2"
if [ -f "${disk_name}" ]; then
  rm -f "${disk_name}"
fi
cp debian-cloud-image "${disk_name}"
qemu-img resize -f qcow2 "${disk_name}" 200G

#
# networking
#

tap_name="tap${NODE_N}"
sudo ip link del "${tap_name}" 2> /dev/null || true
if ! sudo ip tuntap list | grep -q "${tap_name}"; then
  echo 'Creating TAP'
  sudo ip tuntap add dev "${tap_name}" mode tap user "$(id -u)" group "$(id -g)"
  sudo ip link set "${tap_name}" master br0
  sudo ip link set "${tap_name}" up
  printf '%s' "${tap_name}" > "qemu-node${NODE_N}.if_name"
fi

#
# ssh script
#

cat > "ssh-node${NODE_N}.sh" <<EOF
#!/bin/sh
exec ssh \
  -i "${PWD}"/ssh.key \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  -o ServerAliveInterval=10 \
  -o ServerAliveCountMax=3 \
    user@172.16.42.${NODE_N}0 \
      "\$@"
EOF

#
# cloud init
#
rm -f "ci-seed-node${NODE_N}.iso"
cat > "ci-data-node${NODE_N}" <<EOF
#cloud-config
timezone: Etc/UTC

growpart:
  devices: ['/']
  mode: auto

resize_rootfs: true

hostname: node${NODE_N}
fqdn: node${NODE_N}.k8scourse.serics.eu

ntp:
  enabled: true
  ntp_client: systemd-timesyncd
  pools:
    - 0.it.pool.ntp.org
    - 1.it.pool.ntp.org
    - 2.it.pool.ntp.org
    - 3.it.pool.ntp.org

# package_reboot_if_required: true
# package_update: true
# package_upgrade: true

manage_etc_hosts: true

final_message: |
  cloud-init has finished

users:
  - name: user
    gecos: User
    lock_passwd: false
    plain_text_passwd: password
    ssh_authorized_keys:
      - $(cat ssh.key.pub | tr -d '\n')
    sudo: 'ALL=(ALL) NOPASSWD:ALL'
    shell: /bin/bash
EOF

cloud-localds "ci-seed-node${NODE_N}.iso" "ci-data-node${NODE_N}"

exec qemu-system-x86_64 \
    -machine q35 \
    -accel accel=kvm \
    -cpu host \
    -smp cpus=2 \
    -m size=4096 \
    -drive "file=${PWD}/ci-seed-node${NODE_N}.iso,if=virtio,index=0,readonly=yes" \
    -drive "file=${PWD}/${disk_name},snapshot=on,if=virtio,index=1,cache=unsafe,aio=io_uring" \
    -netdev "tap,id=net0,ifname=${tap_name},script=no,downscript=no" \
    -device "virtio-net-pci,netdev=net0,mac=EE:00:00:00:00:${NODE_N}0" \
    -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng,rng=rng0 \
    -bios /usr/share/OVMF/OVMF_CODE.fd \
    -nographic -vga none