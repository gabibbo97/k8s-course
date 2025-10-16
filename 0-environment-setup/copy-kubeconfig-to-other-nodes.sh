#!/bin/sh

# download kubeconfig
echo 'Downloading kubeconfig from node1...'
sh ssh.sh node1 sudo cat /etc/kubernetes/admin.conf > /tmp/kubeconfig.yaml

# copy kubeconfig to other nodes
echo "Copying kubeconfig to other nodes..."
ansible --become -m copy -a 'src=/tmp/kubeconfig.yaml dest=/etc/kubernetes/admin.conf force=yes' -i ansible.inventory k8s-workers,
