.PHONY: up
up:
	sudo podman network create test-net
	sudo podman run --rm -d --name test1 --network test-net --entrypoint /bin/sh public.ecr.aws/docker/library/alpine:3.22 -c 'while true; do sleep 30; done'
	sudo podman run --rm -d --name test2 --network test-net --entrypoint /bin/sh public.ecr.aws/docker/library/alpine:3.22 -c 'while true; do sleep 30; done'

.PHONY: down
down:
	sudo podman network rm -f test-net || true
