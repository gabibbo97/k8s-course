.PHONY: sync
sync:
	rsync \
		-avrd \
		-e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' \
		--progress \
		--exclude '**/*.qcow2' \
		$(CURDIR)/ \
		$(REMOTE):k8s-course/
