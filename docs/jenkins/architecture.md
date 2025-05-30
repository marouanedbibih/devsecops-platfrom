# Jenkins on Kubernetes with Dynamic Agents

## Overview

In this project, Jenkins is deployed on a Kubernetes cluster using Helm to support a dynamic and scalable DevSecOps CI/CD pipeline. This setup enables Jenkins to provision agent pods on-demand, optimizing resource usage and improving isolation and security.

## Architecture

The architecture consists of the following key components:

* **Jenkins Controller Pod**

  * Runs two containers:

    * Web UI (port `8080`)
    * JNLP agent connector (port `50000`)
* **Dynamic Agent Pods**

  * Automatically created during pipeline execution
  * Each pod contains required tools (e.g., Python, Maven)
* **Persistent Volume**

  * Stores Jenkins home and job data
* **ServiceAccount and RBAC**

  * Grants Jenkins permission to manage pods within its namespace

## Configuration Steps

### 1. Deploy Jenkins using Helm

Use the Bitnami Helm chart and set appropriate values for persistence, resources, and agent configuration.
Check this [Jenkins Installation Guide](./installation.md) for more details.

### 2. Enable Kubernetes Cloud in Jenkins UI

Go to **Manage Jenkins → Configure Clouds** and add a new Kubernetes cloud with the following values:

* **Kubernetes URL**: `https://kubernetes.default`
* **Jenkins URL**: `http://jenkins.jenkins.svc.cluster.local:8080`
* **Jenkins tunnel**: `jenkins-agent.jenkins.svc.cluster.local:50000`

### 3. Configure Inbound TCP Port

* Set Jenkins inbound TCP port to **50000**.

### 4. Define ServiceAccount and RBAC

Create a ServiceAccount and bind it to the necessary ClusterRole to allow Jenkins to create pods in its namespace.

## Diagram

Below is a conceptual diagram of the architecture:
[Jenkins on Kubernetes Architecture](architecture.mmd)

## Benefits

* **Scalability**: Automatically creates agents per pipeline execution
* **Security**: Isolated pods per build using Kubernetes RBAC
* **Efficiency**: Optimized resource usage
* **Flexibility**: Supports custom container images and tools

## References

* [Bitnami Jenkins Helm Chart](https://artifacthub.io/packages/helm/bitnami/jenkins)
* [Kubernetes Plugin for Jenkins](https://plugins.jenkins.io/kubernetes/)
