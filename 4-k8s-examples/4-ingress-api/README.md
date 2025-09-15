# Stateless application example

This folder contains an example of a stateless application deployed on Kubernetes using a Deployment controller and exposed via Ingress.

The application is a simple NGINX web server that serves static content.

Files:

- `deployment.yaml`: defines a Deployment that manages a set of NGINX pods.
- `service.yaml`: defines a Service of type ClusterIP that exposes the NGINX pods to internal traffic.
- `configmap.yaml`: a simple HTML file (`index.html`) that is served by the NGINX web server, mounted via a ConfigMap.
- `secret.yaml`: a simple HTML file (`secret.html`) that is served by the NGINX web server, mounted via a Secret.
- `ingress.yaml`: defines an Ingress resource to manage external access to the services in a cluster.
