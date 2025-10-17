.PHONY: generate
generate:
	kubectl create secret docker-registry demo-ips \
	  --docker-server=registry.k8scourse.serics.eu \
	  --docker-username=registry-user \
	  --docker-password=registry-password \
	  --docker-email=registry@k8scourse.serics.eu \
	  --dry-run=client -o yaml > secret.yaml

.PHONY: deploy
deploy: generate
	sudo podman image pull registry.fedoraproject.org/fedora:42
	cd .. && sh upload-image.sh registry.fedoraproject.org/fedora:42 fedora:42
	kubectl \
		--kubeconfig ../../../../4-k8s-ansible/kubeconfig.yaml \
		apply -f secret.yaml -f demo.yml