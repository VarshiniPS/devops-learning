# node-app

A containerised Node.js application deployed on Amazon EKS via a fully automated CI/CD pipeline.

---

## Table of Contents

- [Project Overview](#project-overview)
- [CI/CD Pipeline Flow](#cicd-pipeline-flow)
- [Amazon ECR](#amazon-ecr)
- [Deployment Architecture](#deployment-architecture)
- [Kubernetes Resources](#kubernetes-resources)
- [Local Development](#local-development)
- [Commands Reference](#commands-reference)

---

## Project Overview

| Item | Detail |
|---|---|
| **App** | Node.js |
| **Docker Image** | `varshinips/node-app` |
| **ECR Repository** | `715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app` |
| **Cluster** | Amazon EKS |
| **Region** | `us-east-1` |
| **CI/CD** | GitHub Actions |

---

## CI/CD Pipeline Flow

Every `git push` to `main` triggers the full pipeline automatically:

```
Developer (local)
      │
      │  git push origin main
      ▼
   GitHub
      │
      │  triggers .github/workflows/deploy.yml
      ▼
GitHub Actions
      │
      ├── 1. Checkout code
      ├── 2. Run tests
      ├── 3. docker build -t node-app .
      ├── 4. Authenticate with ECR
      │       aws ecr get-login-password | docker login ...
      ├── 5. docker tag node-app → ECR URI
      ├── 6. docker push → ECR
      └── 7. kubectl apply -f k8s/
      │
      ▼
Amazon ECR
      │
      │  EKS pulls image on deployment
      ▼
Amazon EKS
      │
      ├── Deployment (Pods running node-app)
      ├── Service (ClusterIP / LoadBalancer)
      └── Ingress (HTTP routing → ALB)
      │
      ▼
    Users
```

---

## Amazon ECR

### What is ECR?

Amazon ECR (Elastic Container Registry) is AWS's managed Docker image registry. It stores and versions the Docker images built by GitHub Actions and supplies them to EKS at deploy time.

### Repository Details

| Field | Value |
|---|---|
| **Type** | Private |
| **Repository Name** | `my-app` |
| **Registry URI** | `715708572462.dkr.ecr.us-east-1.amazonaws.com` |
| **Full Image URI** | `715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest` |
| **Region** | `us-east-1` |
| **Scan on Push** | Enabled |

### Private vs Public

| | Private (this project) | Public |
|---|---|---|
| Access | IAM-controlled | Anyone |
| Auth required to pull | Yes | No |
| Use case | Production workloads | Open source images |
| URL format | `<account>.dkr.ecr.<region>.amazonaws.com` | `public.ecr.aws/<alias>` |

### Pushing an Image to ECR

```bash
# 1. Authenticate Docker
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS --password-stdin \
  715708572462.dkr.ecr.us-east-1.amazonaws.com

# 2. Build image
docker build -t varshinips/node-app .

# 3. Tag for ECR
docker tag varshinips/node-app:latest \
  715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

# 4. Push
docker push 715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

---

## Deployment Architecture

### Active Deployment Layout

```
                        ┌─────────────────────────────────────┐
                        │          Amazon EKS Cluster          │
                        │                                      │
   Internet             │   ┌──────────────────────────────┐  │
      │                 │   │        Ingress (ALB)         │  │
      │  HTTPS          │   │  host: app.varshinips.dev    │  │
      └────────────────►│   └──────────────┬───────────────┘  │
                        │                  │                   │
                        │   ┌──────────────▼───────────────┐  │
                        │   │     Service (LoadBalancer)    │  │
                        │   │        port: 80               │  │
                        │   └──────────────┬───────────────┘  │
                        │                  │                   │
                        │   ┌──────────────▼───────────────┐  │
                        │   │         Deployment            │  │
                        │   │   replicas: 2                 │  │
                        │   │   image: ECR/my-app:latest    │  │
                        │   │                               │  │
                        │   │  ┌─────────┐  ┌─────────┐   │  │
                        │   │  │  Pod 1  │  │  Pod 2  │   │  │
                        │   │  │ :8080   │  │ :8080   │   │  │
                        │   │  └─────────┘  └─────────┘   │  │
                        │   └──────────────────────────────┘  │
                        │                                      │
                        │   Worker Nodes (EC2)                 │
                        └─────────────────────────────────────┘
                                          │
                                          │ pulls image
                                          ▼
                              ┌───────────────────────┐
                              │      Amazon ECR        │
                              │  715708572462.dkr.ecr  │
                              │  .us-east-1.amazonaws  │
                              │  .com/my-app:latest    │
                              └───────────────────────┘
```

### Traffic Flow (Request Lifecycle)

```
User Request
    │
    ▼
AWS ALB (provisioned by Ingress Controller)
    │  matches host/path rules
    ▼
Kubernetes Service
    │  load balances across Pod replicas
    ▼
Pod (node-app container on port 8080)
    │
    ▼
Response → User
```

---

## Kubernetes Resources

| Resource | File | Purpose |
|---|---|---|
| `Deployment` | `k8s/deployment.yaml` | Manages Pod replicas, rolling updates |
| `Service` | `k8s/service.yaml` | Stable endpoint, load balancing |
| `Ingress` | `k8s/ingress.yaml` | HTTP routing, TLS termination |

### Key Deployment Config

```yaml
spec:
  replicas: 2
  template:
    spec:
      containers:
        - name: node-app
          image: 715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
          ports:
            - containerPort: 8080
```

---

## Local Development

```bash
# Run locally with Docker
docker run -p 3000:8080 varshinips/node-app

# Or directly with Node
npm install
npm start
```

---

## Commands Reference

```bash
# ── ECR ──────────────────────────────────────────────────────────
# Authenticate Docker
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS --password-stdin \
  715708572462.dkr.ecr.us-east-1.amazonaws.com

# List images in ECR
aws ecr list-images --repository-name my-app --region us-east-1

# ── Docker ────────────────────────────────────────────────────────
docker build -t varshinips/node-app .
docker tag varshinips/node-app:latest \
  715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
docker push 715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

# ── Kubernetes ────────────────────────────────────────────────────
kubectl apply -f k8s/
kubectl get pods
kubectl get svc
kubectl get ingress
kubectl describe deployment node-app
kubectl rollout status deployment/node-app
kubectl rollout undo deployment/node-app   # rollback if needed
```

---

## Docs

- [`docs/ecr-notes.md`](docs/ecr-notes.md) — ECR concepts, private vs public, push walkthrough
- [`docs/service.md`](docs/service.md) — Kubernetes Service types (ClusterIP, NodePort, LoadBalancer)
- [`kubernetes/service.yaml`](kubernetes/service.yaml) — Service manifest