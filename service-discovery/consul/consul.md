# Consul Installation on Kubernetes

This guide covers the deployment of HashiCorp Consul on Kubernetes using the Bitnami Helm chart.

> **Note**: For details on ingress and SSL configuration, refer to [ingress.md](../../docs/k8s/ingress.md)

## Prerequisites

  * A running Kubernetes cluster (VM-based or cloud)
  * `kubectl` and `helm` configured
  * Domain pointing to your cluster IP (e.g., `consul.marouanedbibih.studio`)

## 1\. Add Bitnami Repo & Update

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

## 2\. Customize Values Files

  * Create `values.yaml` from Bitnami chart default:

    [values.yaml](./values.yaml)

  * Then create the custom ingress file for Consul:

    [ingress.yaml](./ingress.yaml)

## 4\. Install Consul

  * Create a namespace for Consul
  * Access to the folders on `kubernetes/consul`

<!-- end list -->

```bash
kubectl create namespace consul

helm install consul bitnami/consul --namespace consul --values values.yaml --wait
```

## 5\. Validate the Installation

```bash
kubectl get all -n consul
kubectl logs -n consul -l app.kubernetes.io/name=consul
```

## 7\. UI & DNS Access

  * Access the UI at: `https://consul.marouanedbibih.studio`
  * Headless service endpoint: `consul-headless.consul.svc.cluster.local`

## 9\. Upgrade

```bash
helm upgrade consul bitnami/consul -n consul -f values.yaml
```

## Notes

  * Secure with ACLs in production
  * Enable metrics for Prometheus integration
  * Update Helm chart regularly for security patches