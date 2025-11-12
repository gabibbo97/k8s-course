.PHONY: install-loki
install-loki:
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm upgrade --install \
		--create-namespace --namespace logging \
		--values values-loki.yml \
		--version 6.44.0 \
		loki grafana/loki

.PHONY: install-promtail
install-promtail:
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm upgrade --install \
		--create-namespace --namespace logging \
		--values values-promtail.yml \
		promtail grafana/promtail

.PHONY: install-grafana
install-grafana:
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm upgrade --install \
		--create-namespace --namespace logging \
		--values values-grafana.yml \
		grafana grafana/grafana

.PHONY: port-forward-grafana
port-forward-grafana:
	kubectl -n logging port-forward svc/grafana 3000:80