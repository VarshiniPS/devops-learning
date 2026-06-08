# Helm Basics

## What is Helm?

Helm is the package manager for Kubernetes.

It helps package, deploy, upgrade, and manage Kubernetes applications using reusable packages called Charts.

Think:

```text
APT → Linux Packages

NPM → JavaScript Packages

Helm → Kubernetes Packages
```

---

# Why Helm?

Without Helm:

```text
deployment.yaml
service.yaml
configmap.yaml
secret.yaml
ingress.yaml
hpa.yaml
```

Managing many YAML files becomes difficult.

Helm solves this by packaging everything into a Chart.

Benefits:

* Reusable deployments
* Easier upgrades
* Environment-specific configuration
* Reduced YAML duplication
* Simpler application management

---

# Helm Architecture

```text
Developer
      ↓
Helm CLI
      ↓
Chart
      ↓
Templates + values.yaml
      ↓
Rendered Kubernetes YAML
      ↓
Kubernetes API Server
      ↓
Cluster Resources
```

---

# Helm Installation Verification

Check installation:

```bash
helm version
```

Example output:

```text
version.BuildInfo{
Version:"v3.x.x"
}
```

---

# Create a Helm Chart

```bash
helm create my-app
```

Generated structure:

```text
my-app/
│
├── Chart.yaml
├── values.yaml
├── charts/
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── serviceaccount.yaml
│   └── tests/
│
└── .helmignore
```

---

# Important Files

## Chart.yaml

Chart metadata.

Example:

```yaml
apiVersion: v2
name: my-app
version: 0.1.0
```

Contains:

* Chart name
* Version
* Description
* Dependencies

---

## values.yaml

Configuration values.

Example:

```yaml
replicaCount: 2

image:
  repository: nginx
  tag: latest
```

Purpose:

```text
Store configurable settings
```

---

## templates/

Contains Kubernetes manifest templates.

Examples:

```text
deployment.yaml
service.yaml
ingress.yaml
```

Templates use values from:

```text
values.yaml
```

---

# Helm Template Example

Template:

```yaml
replicas: {{ .Values.replicaCount }}
```

values.yaml:

```yaml
replicaCount: 3
```

Rendered output:

```yaml
replicas: 3
```

---

# Why Templates?

Without Helm:

```text
dev-deployment.yaml
qa-deployment.yaml
prod-deployment.yaml
```

With Helm:

```text
One Template
+
Different values.yaml
```

Less duplication.

---

# Useful Helm Commands

Create chart:

```bash
helm create my-app
```

Validate chart:

```bash
helm lint my-app
```

Render templates locally:

```bash
helm template my-app
```

Install chart:

```bash
helm install my-release my-app
```

List releases:

```bash
helm list
```

Upgrade release:

```bash
helm upgrade my-release my-app
```

Uninstall release:

```bash
helm uninstall my-release
```

---

# Helm Release

When a chart is installed:

```bash
helm install my-release my-app
```

Helm creates:

```text
Release
```

A release is a running instance of a chart.

Think:

```text
Chart = Blueprint

Release = Running Instance
```

Similar to:

```text
Docker Image = Blueprint

Docker Container = Running Instance
```

---

# Interview Questions

## What is Helm?

Helm is the package manager for Kubernetes that packages and manages Kubernetes applications using Charts.

---

## What is a Helm Chart?

A Helm Chart is a collection of Kubernetes manifests, templates, and configuration values used to deploy an application.

---

## What is values.yaml?

values.yaml stores configurable parameters that are injected into templates.

---

## What are Templates?

Templates are reusable Kubernetes manifests that use values from values.yaml.

---

## What is a Helm Release?

A release is a deployed instance of a Helm Chart.

---

## Why Use Helm?

* Reusability
* Easier deployments
* Simpler upgrades
* Reduced YAML duplication
* Environment-specific configuration

---

# Quick Revision

```text
Helm
 ↓
Package Manager

Chart
 ↓
Package

values.yaml
 ↓
Configuration

Templates
 ↓
Reusable YAML

Release
 ↓
Running Instance
```
