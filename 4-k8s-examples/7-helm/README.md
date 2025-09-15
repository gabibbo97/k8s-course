# Helm deployment example

This folder contains a Helm chart that deploys the stateless NGINX application from the [stateless application example](../2-stateless-application).

## Usage

```sh
helm install stateless-app ./stateless-app
```

To remove the release:

```sh
helm uninstall stateless-app
```
