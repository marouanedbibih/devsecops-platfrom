# Jenkins Deployment on Kubernetes

This guide details the steps to deploy Jenkins on a Kubernetes cluster (K3s, EKS, GKE, etc.) using the official Bitnami Helm chart and an NGINX Ingress for service exposure.

## Prerequisites

- Functional Kubernetes cluster (v1.19+)
- [Helm 3](https://helm.sh/docs/intro/install/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured with cluster access
- NGINX Ingress Controller installed on the cluster
- Access to the following files in this repository:
  - `jenkins-values.yaml` (Helm configuration)
  - `jenkins-ingress.yaml` (Ingress configuration)

## Installation

### 1. Create Jenkins namespace

```bash
kubectl create namespace jenkins
```

### 2. Install Jenkins with Helm

Add the Bitnami repository if not already done:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Install Jenkins using the `jenkins-values.yaml` file:

```bash
helm install jenkins bitnami/jenkins -n jenkins -f jenkins-values.yaml
```

Verify that Jenkins pods are running:

```bash
kubectl get pods -n jenkins
```

Wait until the pod is in `Running` state (this may take a few minutes).

### 3. Apply the Ingress

Apply the Ingress file to expose Jenkins:

```bash
kubectl apply -f jenkins-ingress.yaml
```

Verify that the Ingress is correctly configured:

```bash
kubectl get ingress -n jenkins
```

## Accessing Jenkins

Once deployed, Jenkins should be accessible at the URL configured in your Ingress (typically `http://jenkins.localhost` or the URL specified in `jenkins-ingress.yaml`).

> **Note**: You may need to add an entry in your `/etc/hosts` file if using a local hostname. For example:  
> `127.0.0.1 jenkins.localhost`

### Login Credentials

Default credentials are defined in the `jenkins-values.yaml` file. Typically:
- Username: `admin`
- Password: Check the `jenkins-values.yaml` file or retrieve it with the following command if automatically generated:

```bash
kubectl get secret -n jenkins jenkins -o jsonpath="{.data.jenkins-password}" | base64 --decode
```

## Troubleshooting

### Pod in CrashLoopBackOff state

If the Jenkins pod is in `CrashLoopBackOff` state:

1. Check the pod logs:
   ```bash
   kubectl logs -n jenkins -l app.kubernetes.io/name=jenkins
   ```

2. Check allocated resources:
   ```bash
   kubectl describe pod -n jenkins -l app.kubernetes.io/name=jenkins
   ```

3. If the issue is related to persistence, you can delete the PVC (caution, this deletes data):
   ```bash
   kubectl delete pvc -n jenkins data-jenkins-0
   ```

### Access or Authentication Issues

1. Verify that the Ingress is correctly configured:
   ```bash
   kubectl describe ingress -n jenkins
   ```

2. Check that the service is exposed on the correct port:
   ```bash
   kubectl get svc -n jenkins
   ```

3. If you've forgotten the password, you can reset it by modifying the secret:
   ```bash
   kubectl delete secret -n jenkins jenkins
   kubectl create secret generic jenkins -n jenkins --from-literal=jenkins-password=new_password
   kubectl rollout restart statefulset -n jenkins jenkins
   ```

## Persistence and Plugins

### Persistence

Jenkins data is persistent thanks to a PVC (PersistentVolumeClaim) configured in the Helm chart. The volume is mounted at `/bitnami/jenkins` in the container.

To check the PVC status:

```bash
kubectl get pvc -n jenkins
```

> **Warning**: When deleting the deployment, make sure to keep the PVC if you want to preserve the data.

### Plugins

The Jenkins deployment includes plugins configured in the `jenkins-values.yaml` file. To install additional plugins:

1. Access the Jenkins interface
2. Navigate to *Manage Jenkins* > *Manage Plugins*
3. Install the necessary plugins

Alternatively, you can add the list of plugins in the `jenkinsPlugins` section of the `jenkins-values.yaml` file and update the deployment:

```bash
helm upgrade jenkins bitnami/jenkins -n jenkins -f jenkins-values.yaml
```

## Maintenance

To update Jenkins to a newer version:

```bash
helm repo update
helm upgrade jenkins bitnami/jenkins -n jenkins -f jenkins-values.yaml
```