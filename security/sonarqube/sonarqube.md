Here's a reformatted and improved structure for your SonarQube installation guide, enhancing clarity and organization:

# SonarQube Installation on Kubernetes

This guide provides comprehensive instructions for deploying **SonarQube** on a Kubernetes cluster. We'll use the **Bitnami Helm chart**, configure **Ingress**, and secure access with a **Let's Encrypt SSL certificate**.

-----

## Table of Contents

  * [1. Prerequisites](#1-prerequisites)
  * [2. Installation Steps](#2-installation-steps)
      * [2.1. Add Bitnami Helm Repository](#21-add-bitnami-helm-repository)
      * [2.2. Customize Configuration Files](#22-customize-configuration-files)
      * [2.3. Deploy SonarQube](#23-deploy-sonarqube)
  * [3. Validate Installation](#3-validate-installation)
  * [4. Access SonarQube UI](#4-access-sonarqube-ui)
  * [5. Upgrade SonarQube](#5-upgrade-sonarqube)
  * [6. Important Notes](#6-important-notes)

-----

## 1. Prerequisites

Before you begin, ensure you have the following configured in your environment:

  * A **Kubernetes cluster** with an **NGINX Ingress Controller** installed and running.
  * A **domain name** pointing to your cluster's Ingress Controller, for example: `sonarqube.marouanedbibih.studio`.
  * The **`kubectl` CLI tool** configured to interact with your Kubernetes cluster.
  * **Helm v3+** installed on your local machine.
  * **cert-manager** configured with a **Let's Encrypt ClusterIssuer**.

-----

## 2. Installation Steps

### 2.1. Add Bitnami Helm Repository

Start by adding the Bitnami Helm repository and updating your local Helm repositories:

```bash
# Add Bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update Helm repositories
helm repo update
```

### 2.2. Customize Configuration Files

You'll need two custom configuration files for your SonarQube deployment:

  * **`values.yaml`**: Create or modify this file to customize your SonarQube Helm chart settings.
      * [sonarqube/values.yaml](./values.yaml)
  * **`ingress.yaml`**: Define the Ingress resource for SonarQube to expose it externally and enable SSL.
      * [sonarqube/ingress.yaml](./ingress.yaml)

### 2.3. Deploy SonarQube

Now, let's deploy SonarQube to your Kubernetes cluster. This involves creating a dedicated namespace, installing SonarQube via Helm, and applying the Ingress manifest.

```bash
# Create the namespace for SonarQube
kubectl create namespace sonar

# Install SonarQube using Helm, referencing your custom values file
helm install sonarqube bitnami/sonarqube \
  --namespace sonar \
  --values kubernetes/sonarqube/values.yaml

# Apply the custom Ingress manifest to expose SonarQube
kubectl apply -f kubernetes/sonarqube/ingress.yaml
```

-----

## 3. Validate Installation

After deployment, run these commands to verify that all SonarQube components are running correctly and accessible:

```bash
# Check the status of SonarQube pods
kubectl get pods -n sonar

# Check the SonarQube services
kubectl get svc -n sonar

# Verify the Ingress resource status
kubectl get ingress -n sonar

# Check the status of the SSL certificate issued by cert-manager
kubectl get certificate -n sonar

# View SonarQube application logs for any issues
kubectl logs -n sonar -l app.kubernetes.io/name=sonarqube

# Check PostgreSQL database logs (if deployed by the chart)
kubectl logs -n sonar -l app.kubernetes.io/name=postgresql
```

-----

## 4. Access SonarQube UI

Once the deployment is complete and the SSL certificate has been successfully issued by cert-manager:

1.  Open your web browser and navigate to the configured domain: `https://sonarqube.marouanedbibih.studio`

2.  Login with the default credentials:

      * **Username**: `admin`
      * **Password**: You'll need to retrieve the initial admin password from a Kubernetes secret. Use the command below:

    <!-- end list -->

    ```bash
    # Get the SonarQube admin password from the Kubernetes secret
    kubectl get secret sonarqube -n sonar -o jsonpath="{.data.sonarqube-password}" | base64 --decode
    ```

-----

## 5. Upgrade SonarQube

To upgrade your SonarQube deployment to a newer version of the Helm chart or SonarQube application:

```bash
# Update your Helm repositories to get the latest chart versions
helm repo update

# Upgrade the existing SonarQube Helm release, applying your custom values again
helm upgrade sonarqube bitnami/sonarqube \
  --namespace sonar \
  --values kubernetes/sonarqube/values.yaml
```

-----

## 6. Important Notes

Consider these points for production deployments and ongoing maintenance:

### Admin Password

  * The initial admin password is stored in a Kubernetes secret named `sonarqube`.
  * **Always change the default password immediately after your first login** for security.

### Persistent Storage

  * SonarQube and its PostgreSQL database rely on **Persistent Volumes** to store data.
  * Ensure your Kubernetes cluster has a **default `StorageClass`** configured to provision these volumes.
  * Implement **regular backups of your PostgreSQL data**.

### Database

  * By default, the Bitnami chart deploys an in-cluster **PostgreSQL database**.
  * For **production environments**, it's strongly recommended to use a **managed external database service** for better performance, scalability, and reliability.

### Monitoring

  * Enable metrics export by setting `metrics.enabled: true` in your `values.yaml` file.
  * If you're using Prometheus, configure a **Prometheus ServiceMonitor** to collect these metrics.

### Performance Tuning

  * Adjust the **JVM heap size** for SonarQube by modifying the `sonarqubeJvmOpts` parameter in your `values.yaml`.
  * Continuously **monitor resource usage** (CPU, memory) and adjust Kubernetes resource limits and requests accordingly.

### Plugins

  * You can install additional SonarQube plugins through the **SonarQube Marketplace** directly in the UI.
  * When persistence is enabled, these plugins will persist across pod restarts.

### Backup Strategy

  * **Regular database backups are critical** for disaster recovery.
  * Consider utilizing **volume snapshots** if your storage provider supports them for quick data recovery points.
  * Regularly **export your quality profiles and quality gates** from SonarQube, as these are crucial configurations.