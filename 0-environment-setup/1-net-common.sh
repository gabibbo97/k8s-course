#!/bin/sh

## stop firewall
sudo systemctl stop firewalld || true

## bridge
if ! sudo ip link | grep -q br0; then
    echo 'Creating bridge'
    sudo ip link add br0 type bridge
    sudo ip addr add 172.16.42.1/24 dev br0
    sudo ip link set br0 up
fi

## NAT rules
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null
default_gw_if=$(ip route show default | head -n 1 | awk '{ print $5 }')
if ! sudo iptables -t nat -C POSTROUTING -s 172.16.42.0/24 -o "$default_gw_if" -j MASQUERADE 2>/dev/null; then
    echo 'Adding NAT masquerade rule'
    sudo iptables -t nat -A POSTROUTING -s 172.16.42.0/24 -o "$default_gw_if" -j MASQUERADE
fi
if ! sudo iptables -C FORWARD -s 172.16.42.0/24 -o "$default_gw_if" -j ACCEPT 2>/dev/null; then
    echo 'Adding NAT forward rule'
    sudo iptables -A FORWARD -s 172.16.42.0/24 -o "$default_gw_if" -j ACCEPT
fi
