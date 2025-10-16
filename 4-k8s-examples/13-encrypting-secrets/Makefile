.PHONY: kubeadm-config-original.yaml

kubeadm-config-original.yaml:
	kubectl --kubeconfig ../../4-k8s-ansible/kubeconfig.yaml get configmap -n kube-system kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' > $@

kubeadm-config-patched.yaml: kubeadm-config-original.yaml
	kubectl patch --local --type merge -f kubeadm-config-original.yaml --patch-file patch-enable-at-rest.yaml -o yaml > $@

.PHONY: apply-kubeadm-config
apply-kubeadm-config: kubeadm-config-patched.yaml
	kubectl --kubeconfig ../../4-k8s-ansible/kubeconfig.yaml -n kube-system create configmap kubeadm-config --from-file=ClusterConfiguration=kubeadm-config-patched.yaml -o yaml --dry-run=client | kubectl --kubeconfig ../../4-k8s-ansible/kubeconfig.yaml -n kube-system apply -f -

.PHONY: enable
enable: apply-kubeadm-config
	ansible -i ../../0-environment-setup/ansible.inventory -m copy -a 'src=kubeadm-config-patched.yaml dest=/tmp/kubeadm-config.yaml force=yes' k8s-servers
	ansible -i ../../0-environment-setup/ansible.inventory --become -m copy -a 'src=encryption-provider-config.yaml dest=/etc/kubernetes/encryption-provider-config.yaml force=yes' k8s-servers
	ansible -i ../../0-environment-setup/ansible.inventory --become -m command -a 'kubeadm init phase control-plane apiserver --config /tmp/kubeadm-config.yaml' k8s-servers

.PHONY: recrypt
recrypt:
	kubectl --kubeconfig ../../4-k8s-ansible/kubeconfig.yaml get secrets --all-namespaces -o json | kubectl --kubeconfig ../../4-k8s-ansible/kubeconfig.yaml replace -f -
