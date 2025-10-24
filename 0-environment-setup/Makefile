#
# Cloud image
#

CLOUD_IMAGE_VERSION := 20251024-2275
CLOUD_IMAGE_URL := https://cloud.debian.org/images/cloud/trixie/daily/$(CLOUD_IMAGE_VERSION)/debian-13-genericcloud-amd64-daily-$(CLOUD_IMAGE_VERSION).qcow2

debian-cloud-image: debian-cloud-image-$(CLOUD_IMAGE_VERSION).qcow2 remove-old-cloud-images
	ln -sf $(CURDIR)/debian-cloud-image-$(CLOUD_IMAGE_VERSION).qcow2 $(CURDIR)/$@

debian-cloud-image-$(CLOUD_IMAGE_VERSION).qcow2:
	wget -O $@ $(CLOUD_IMAGE_URL)

.PHONY: remove-old-cloud-images
remove-old-cloud-images:
	find . -maxdepth 1 -type f -name 'debian-cloud-image-*.qcow2' ! -name 'debian-cloud-image-$(CLOUD_IMAGE_VERSION).qcow2' -exec rm -f {} \;

#
# targets
#

N_NODES ?= 5

.PHONY: up
up: debian-cloud-image
	sh 1-net-common.sh
	env N_NODES=$(N_NODES) sh 2-dns.sh
	env N_NODES=$(N_NODES) sh 3-start-vms.sh
# 	env N_NODES=$(N_NODES) sh auxiliary-services-registry.sh

.PHONY: down
down:
	env N_NODES=$(N_NODES) sh 4-stop-and-clean.sh

.PHONY: logs
logs:
	units=''; \
	for node_i in $$(seq 1 "$(N_NODES)"); do \
		units="$$units -u testbed-node$${node_i}.service"; \
	done; \
	set -x; \
	sudo journalctl --no-hostname -o short-iso -u testbed-dns.service $$units -f

.PHONY: restart
restart:
	$(MAKE) down
	$(MAKE) up
	$(MAKE) wait

.PHONY: wait
wait:
	until ansible all, -i ansible.inventory -m ping; do sleep 1; done

.PHONY: restart-dns
restart-dns:
	sudo systemctl stop testbed-dns.service || true
	sh 2-dns.sh
