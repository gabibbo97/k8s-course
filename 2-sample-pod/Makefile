POD_YAML := sample-pod.yaml

.PHONY: run clean logs

run:
	@echo "Running podman play kube $(POD_YAML) as root..."
	sudo podman play kube $(POD_YAML)

clean:
	@echo "Cleaning up pod..."
	sudo podman pod rm -if debian-sample-pod

logs:
	@echo "Fetching logs..."
	sudo podman pod logs --names debian-sample-pod
