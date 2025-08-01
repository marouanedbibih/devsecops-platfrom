# Rancher Installation Guide

This guide outlines the process for installing Rancher, a complete container management platform, on a Kubernetes cluster using Helm and a custom configuration.

## About Rancher

Rancher is an open-source platform for managing Kubernetes clusters across any infrastructure. It provides a unified UI and tools for deploying, managing, and operating containerized workloads.

## Prerequisites

Before installing Rancher, ensure you have:

- A running Kubernetes cluster (v1.21+)
- Helm 3 installed on your local machine
- NGINX Ingress Controller installed in your cluster
- `kubectl` configured to communicate with your cluster
- Domain name pointing to your cluster (rancher.localhost in this config)

## Installation Steps

### 1. Add the Rancher Helm Repository

```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
```

### 2. Create Namespace

```bash
kubectl create namespace cattle-system
```

### 3. Install Rancher with Custom Values

The repository already contains a custom `rancher-values.yaml` file for Rancher configuration. You can modify this file to suit your needs.

```bash
helm upgrade --install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --create-namespace \
  -f rancher-values.yaml
```

### 4. Verify the Installation

```bash
kubectl -n cattle-system get pods
```

Wait until all pods are in `Running` state and check that the ingress has been created:

```bash
kubectl -n cattle-system get ingress
```

## Upgrading or Reinstalling Rancher

To upgrade or reinstall Rancher with updated configuration:

```bash
helm upgrade rancher rancher-stable/rancher \
  --namespace cattle-system \
  --values ./rancher-values.yaml \
  --wait
```

## Accessing Rancher

1. Access Rancher UI by navigating to `https://rancher.localhost` in your web browser 
   (ensure this hostname resolves to your cluster IP, or add it to your hosts file for local development)

2. Login credentials:
   - Username: `admin`
   - Password: `admin1234` (from the bootstrapPassword in values.yaml)

> **IMPORTANT**: Change the default admin password immediately after first login for security purposes.

## Troubleshooting

If you encounter issues:

1. Check pod status: `kubectl -n cattle-system get pods`
2. View pod logs: `kubectl -n cattle-system logs -l app=rancher`
3. Verify ingress configuration: `kubectl -n cattle-system get ingress -o yaml`

## Uninstalling Rancher

If you need to remove Rancher:

```bash
helm uninstall rancher -n cattle-system
kubectl delete namespace cattle-system
```