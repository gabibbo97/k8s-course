.PHONY: enable
enable:
	ansible-playbook \
		-i ../../../../0-environment-setup/ansible.inventory \
		playbook.yml $(ANSIBLE_ARGS)

.PHONY: deploy-demo
deploy-demo:
	sudo podman image pull registry.fedoraproject.org/fedora:42
	cd .. && sh upload-image.sh registry.fedoraproject.org/fedora:42 fedora:42
	kubectl \
		--kubeconfig ../../../../4-k8s-ansible/kubeconfig.yaml \
		apply -f demo.yml