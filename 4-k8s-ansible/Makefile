.PHONY: install-prequisites
install-prequisites:
	ansible-galaxy collection install -r requirements.yml

.PHONY: run-playbook
run-playbook: install-prequisites
	ansible-playbook -i ../0-environment-setup/ansible.inventory playbook.yml -v $(ANSIBLE_ARGS)
