up:
	kubectl apply -f configmap.yaml
	kubectl apply -f secret.yaml
	kubectl apply -f deployment.yaml
	kubectl apply -f service.yaml
	kubectl apply -f ingress.yaml

down:
	kubectl delete -f ingress.yaml --ignore-not-found
	kubectl delete -f service.yaml --ignore-not-found
	kubectl delete -f deployment.yaml --ignore-not-found
	kubectl delete -f secret.yaml --ignore-not-found
	kubectl delete -f configmap.yaml --ignore-not-found
