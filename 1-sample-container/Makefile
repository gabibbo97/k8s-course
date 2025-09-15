IMAGE_NAME := sample-debian-container
CONTAINER_NAME := sample-debian-run

.PHONY: build run clean

build:
	podman build -t $(IMAGE_NAME) .

run:
	podman run --rm -it --name $(CONTAINER_NAME) $(IMAGE_NAME)

clean:
	podman rm -f $(CONTAINER_NAME) || true
	podman rmi -f $(IMAGE_NAME) || true
