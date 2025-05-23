# Marouane Dbibih Infrastructure

This repository contains documentation and configuration files for deploying and managing the ACS GMAO platform on Kubernetes. Below you will find links to the main documentation for each component.

## Documentation Index

- [Jenkins](./jenkins/jenkins.md)
- [Rancher](./rancher/rancher.md)
- [Nginx Ingress](./docs/k8s/ingress.md)
- [Helm Usage](./docs/k8s/helm.md)
- [Nexus](./kubernetes/nexus/nexus.md)
- [SonarQube](./sonarqube/sonarqube-values.yaml)

## 1. Kubernetes
## 1.1 Nginx Ingress
NGINX Ingress Controller is deployed on the Kubernetes cluster to manage external access to services. It provides load balancing, SSL termination, and URL routing. The controller is installed using Helm and configured with a custom values file. The NGINX Ingress Controller is exposed as a LoadBalancer service, allowing external traffic to reach the services within the cluster.

For the full deployment and configuration guide, see: [NGINX Ingress Guide](./docs/k8s/ingress.md)
## 1.2 Sonarqube
SonarQube is deployed on the Kubernetes cluster to provide continuous inspection of code quality and security. It is installed using a custom values file to configure the database, authentication, and other settings. The SonarQube service is exposed via the NGINX Ingress Controller, allowing access through a domain name. The deployment includes persistent storage for data retention.
For the full deployment and configuration guide, see: [SonarQube Guide](./sonarqube/sonarqube-values.yaml)
## 1.3 Jenkins
Jenkins is deployed on the Kubernetes cluster to automate the software development process through continuous integration and continuous delivery (CI/CD). It is installed using a custom values file to configure plugins, security settings, and persistent storage. The Jenkins service is exposed via the NGINX Ingress Controller, allowing access through a domain name. The deployment includes persistent storage for build artifacts and configurations.
For the full deployment and configuration guide, see: [Jenkins Guide](./jenkins/jenkins.md)
## 1.4 Consul

Consul is deployed on the Kubernetes cluster to provide service discovery, distributed key-value storage, and health checking for microservices. It enables secure communication between services and supports dynamic configuration updates. The Consul UI is accessible for monitoring and management, and DNS integration allows services to resolve each other easily within the cluster. For production, it is recommended to secure Consul with ACLs and enable metrics for observability.

For the full deployment and configuration guide, see: [Consul Guide](./kubernetes/consul/consul.md)

