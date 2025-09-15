#!/bin/sh
N_NODES=${N_NODES:-3}

#
# create etc hosts
#

ansible --become localhost, -m ansible.builtin.lineinfile -a "path=/etc/hosts line='172.16.42.142 registry.k8scourse.serics.eu' regexp='^172[.]16[.]42[.]142' state=present"

#
# number of servers
#

if [ $N_NODES -lt 3 ]; then
  N_SERVERS=1
else
  N_SERVERS=3
fi

DNSMASQ_ARGS=''
for node_i in $(seq 1 "${N_NODES}"); do
    DNSMASQ_ARGS="${DNSMASQ_ARGS} --dhcp-host=EE:00:00:00:00:${node_i}0,172.16.42.${node_i}0,node${node_i}"
    if [ $node_i -le $N_SERVERS ]; then
      DNSMASQ_ARGS="${DNSMASQ_ARGS} --srv-host=_k8s-server._tcp.k8scourse.serics.eu,node${node_i}.k8scourse.serics.eu.,6443,1,1"
    fi
    DNSMASQ_ARGS="${DNSMASQ_ARGS} --address=/registry.k8scourse.serics.eu/172.16.42.142"
done

# shellcheck disable=SC2086
sudo systemd-run \
    --unit=testbed-dns.service \
    --description="Testbed DNS Service" \
    --remain-after-exit \
    dnsmasq \
        --keep-in-foreground \
        --bind-interfaces --interface br0 \
        --listen-address 172.16.42.1 \
        --address=/host.k8scourse.serics.eu/172.16.42.1 \
        --address=/api-lb.k8scourse.serics.eu/172.16.42.5 \
        --dhcp-fqdn \
        --domain=k8scourse.serics.eu \
        --dhcp-authoritative \
        --dhcp-range=172.16.42.0,static,255.255.255.0,12h \
        ${DNSMASQ_ARGS} \
        --dhcp-option=3,172.16.42.1 \
        --cache-size=10000 \
        --no-resolv \
        --no-hosts \
        --server=1.1.1.1 \
        --server=1.0.0.1 \
        --log-dhcp --log-queries --log-facility=-
