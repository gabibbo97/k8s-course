kubeadm-config-original.yaml:
	kubectl --kubeconfig ../../3-k8s-ansible/kubeconfig.yaml get configmap -n kube-system kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' > $@

kubeadm-config-patched.yaml: kubeadm-config-original.yaml
	kubectl patch --local --type merge -f kubeadm-config-original.yaml --patch-file patch-enable-auditing.yaml -o yaml > $@

.PHONY: enable-auditing
enable-auditing: kubeadm-config-patched.yaml
	kubectl --kubeconfig ../../3-k8s-ansible/kubeconfig.yaml -n kube-system create configmap kubeadm-config --from-file=ClusterConfiguration=kubeadm-config-patched.yaml -o yaml --dry-run=client | kubectl --kubeconfig ../../3-k8s-ansible/kubeconfig.yaml -n kube-system apply -f -
	ansible -i ../../0-environment-setup/ansible.inventory -m copy -a 'src=kubeadm-config-patched.yaml dest=/tmp/kubeadm-config.yaml force=yes' k8s-servers
	ansible -i ../../0-environment-setup/ansible.inventory --become -m copy -a 'src=audit-log-policy.yaml dest=/etc/kubernetes/audit-policy.yaml force=yes' k8s-servers
	ansible -i ../../0-environment-setup/ansible.inventory --become -m command -a 'kubeadm init phase control-plane apiserver --config /tmp/kubeadm-config.yaml' k8s-servers
