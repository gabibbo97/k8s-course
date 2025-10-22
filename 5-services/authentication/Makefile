.PHONY: run-client-ca
run-client-ca:
	ansible-playbook -i ../../0-environment-setup/ansible.inventory playbook.yml --tags client-ca -v

.PHONY: run-static-tokens
run-static-tokens:
	ansible-playbook -i ../../0-environment-setup/ansible.inventory playbook.yml --tags static-tokens -v
