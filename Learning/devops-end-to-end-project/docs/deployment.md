# Kubernetes Deployment

## Objective

Deploy a Dockerized Node.js application into Kubernetes using a Deployment.

---

## Deployment Architecture

User
↓
Service
↓
Deployment
↓
ReplicaSet
↓
Pods
↓
Container

---

## Deployment YAML Components

### apiVersion

```yaml
apiVersion: apps/v1
```

Deployment API version.

---

### kind

```yaml
kind: Deployment
```

Creates a Deployment object.

---

### metadata

```yaml
metadata:
  name: nodejs-deployment
```

Unique Deployment name.

---

### replicas

```yaml
replicas: 3
```

Desired Pod count.

Benefits:

* High availability
* Fault tolerance
* Load distribution

---

### selector

```yaml
selector:
  matchLabels:
    app: nodejs-app
```

Used by Deployment to identify managed Pods.

---

### template

Defines Pod specification.

```yaml
template:
```

---

### container image

```yaml
image: <dockerhub-username>/node-app:v1
```

Docker image used by Pods.

---

### containerPort

```yaml
containerPort: 3000
```

Application listening port inside container.

---

### Resource Requests

```yaml
requests:
  cpu: 100m
  memory: 128Mi
```

Minimum resources required.

---

### Resource Limits

```yaml
limits:
  cpu: 500m
  memory: 512Mi
```

Maximum resources allowed.

---

## Commands

Apply Deployment:

```bash
kubectl apply -f deployment.yaml
```

List Deployments:

```bash
kubectl get deployments
```

List Pods:

```bash
kubectl get pods
```

Describe Deployment:

```bash
kubectl describe deployment nodejs-deployment
```

Delete Deployment:

```bash
kubectl delete -f deployment.yaml
```

---

## Interview Questions

### What is a Deployment?

Deployment manages Pods and provides:

* Self-healing
* Scaling
* Rolling updates
* Rollbacks

---

### What happens if a Pod crashes?

Deployment detects the failure and creates a replacement Pod.

---

### Why use replicas?

To provide high availability and fault tolerance.

---

### What is the difference between Pod and Deployment?

Pod:

* Runs containers

Deployment:

* Manages Pods
* Maintains desired state

---

### What is a ReplicaSet?

ReplicaSet ensures the required number of Pod replicas are running.

Deployment manages ReplicaSets.

---

## Learning Outcome

Successfully created and managed a Kubernetes Deployment with multiple replicas and understood Deployment architecture.
