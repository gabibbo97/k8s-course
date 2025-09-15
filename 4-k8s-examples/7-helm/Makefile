CHART=stateless-app
RELEASE=stateless-app

install:
	helm upgrade --install $(RELEASE) ./$(CHART)

uninstall:
	helm uninstall $(RELEASE)

lint:
	helm lint ./$(CHART)
