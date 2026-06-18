# Node.js Deployment in Kubernetes

## Objective

Deploy a Dockerized Node.js application using Kubernetes Deployment.

---

## Deployment YAML

### Key Components

### Deployment

Manages Pods and ensures desired replica count.

### Replicas

```yaml
replicas: 3
```

Ensures three Pod instances are running.

### Selector

```yaml
selector:
  matchLabels:
    app: nodejs-app
```

Used to identify Pods managed by Deployment.

### Container Image

```yaml
image: node-app:latest
```

Docker image used by Pods.

### Container Port

```yaml
containerPort: 3000
```

Application port inside container.

---

## Commands Used

Create deployment:

```bash
kubectl apply -f deployment.yaml
```

Verify deployment:

```bash
kubectl get deployments
```

Verify pods:

```bash
kubectl get pods
```

Describe pod:

```bash
kubectl describe pod <pod-name>
```

View logs:

```bash
kubectl logs <pod-name>
```

Delete deployment:

```bash
kubectl delete -f deployment.yaml
```

---

## Interview Questions

### What is a Deployment?

A Deployment manages Pods and ensures the desired number of replicas are running.

### Why use replicas?

Replicas provide high availability and fault tolerance.

### What happens if a Pod crashes?

The Deployment automatically creates a new Pod to maintain the desired replica count.

### Difference Between Pod and Deployment?

Pod:

* Smallest deployable Kubernetes unit

Deployment:

* Manages Pods and replica count
* Supports rolling updates and self-healing

---

## Learning Outcome

Successfully deployed a Dockerized Node.js application using Kubernetes Deployment and verified Pods using kubectl commands.
