.PHONY: up
up:
	$(MAKE) -C kubelet-credential-provider enable
	$(MAKE) -C crio deploy
	$(MAKE) -C kubelet-credential-provider deploy-demo
	$(MAKE) -C image-pull-secret deploy
