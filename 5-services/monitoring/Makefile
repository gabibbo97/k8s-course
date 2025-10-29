.PHONY: restart-prometheus
restart-prometheus:
	kubectl -n monitoring rollout restart statefulset/prometheus

.PHONY: port-forward
port-forward:
	kubectl -n monitoring port-forward statefulset/prometheus 9090:9090

.PHONY: local-demo
local-demo:
	sudo setenforce 0;
	sudo podman run --rm -it --privileged --pid=host --net=host \
		-v /proc:/host/proc:ro \
		-v /sys:/host/sys:ro \
		-v /:/rootfs:ro \
		--pull=newer \
		quay.io/prometheus/node-exporter \
			--path.procfs=/host/proc --path.sysfs=/host/sys --path.rootfs=/rootfs

.PHONY: logs
logs:
	kubectl -n monitoring rollout status statefulset/prometheus --timeout=10s
	kubectl -n monitoring logs statefulset/prometheus -f

.PHONY: install-kube-state-metrics
install-kube-state-metrics:
	helm upgrade kube-state-metrics oci://ghcr.io/prometheus-community/charts/kube-state-metrics \
		--install \
		--namespace monitoring \
		--values kube-state-metrics-helm-values.yml

.PHONY: prepare-nodes
prepare-nodes:
# https://github.com/prometheus-operator/kube-prometheus/blob/main/docs/kube-prometheus-on-kubeadm.md
	ansible \
		-m lineinfile \
		-a 'path=/etc/kubernetes/manifests/kube-controller-manager.yaml regexp="^(.+)--bind-address=127.0.0.1" line="\1--bind-address=0.0.0.0" backrefs=true' \
		-i ../../0-environment-setup/ansible.inventory \
		--become \
		k8s-servers,
	ansible \
		-m lineinfile \
		-a 'path=/etc/kubernetes/manifests/kube-scheduler.yaml regexp="^(.+)--bind-address=127.0.0.1" line="\1--bind-address=0.0.0.0" backrefs=true' \
		-i ../../0-environment-setup/ansible.inventory \
		--become \
		k8s-servers,