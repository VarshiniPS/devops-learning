# devops-end-to-end-project

A complete DevOps pipeline project — from local development to production on Kubernetes.
Covers every stage: code → GitHub → CI/CD → Docker → EKS.

---

## Project Flow

```
Developer (local)
      │
      │  git push
      ▼
GitHub Repository
      │
      │  triggers on: push
      ▼
GitHub Actions (CI/CD)
      │
      ├── 1. Run tests
      ├── 2. Build Docker image
      ├── 3. Push image → Docker Hub / ECR
      │
      │  kubectl apply / helm upgrade
      ▼
Kubernetes (EKS)
      │
      ├── Ingress → Service → Deployment → Pods
      └── Pods pull image and run the app
```

---

## Pipeline Stages

| Stage | Tool | What happens |
|---|---|---|
| **Code** | Local dev | Write and test code locally |
| **Push** | Git + GitHub | Push triggers the CI pipeline |
| **Test** | GitHub Actions | Lint, unit tests, integration tests |
| **Build** | Docker + GHA | Build container image, tag with commit SHA |
| **Publish** | Docker Hub / ECR | Push image to registry |
| **Deploy** | Helm + kubectl | Upgrade release on EKS cluster |
| **Run** | Kubernetes (EKS) | Pods serve traffic via ALB Ingress |

---

## Repository Structure

```
devops-end-to-end-project/
│
├── app/                        # Application source code
│   ├── src/                    # Source files
│   ├── tests/                  # Unit and integration tests
│   ├── package.json            # (or requirements.txt / go.mod)
│   └── Dockerfile              # App container definition
│
├── docker/                     # Docker configuration
│   ├── Dockerfile.prod         # Production-optimised image
│   ├── Dockerfile.dev          # Development image with hot reload
│   ├── docker-compose.yml      # Local multi-service setup
│   └── .dockerignore           # Files to exclude from build context
│
├── kubernetes/                 # Kubernetes manifests and Helm chart
│   ├── helm/                   # Helm chart (helm create output)
│   │   ├── Chart.yaml
│   │   ├── values.yaml         # Default values
│   │   ├── values-staging.yaml # Staging overrides
│   │   ├── values-prod.yaml    # Production overrides
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── ingress.yaml
│   │       └── _helpers.tpl
│   ├── namespace.yaml          # Namespace definition
│   └── configmap.yaml          # App configuration
│
├── docs/                       # Project documentation
│   ├── architecture.md         # System design and decisions
│   ├── setup.md                # Local setup guide
│   ├── runbook.md              # Production ops runbook
│   └── diagrams/               # Architecture diagrams
│
├── .github/
│   └── workflows/
│       ├── ci.yml              # Test and build on every push
│       └── deploy.yml          # Deploy to EKS on merge to main
│
├── .gitignore
└── README.md                   # This file
```

---

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed locally
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured
- [Helm](https://helm.sh/docs/intro/install/) v3+
- [AWS CLI](https://aws.amazon.com/cli/) configured (for EKS)
- [eksctl](https://eksctl.io/) (for cluster management)

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/devops-end-to-end-project.git
cd devops-end-to-end-project
```

### 2. Run locally with Docker

```bash
cd docker
docker compose up --build
# App available at http://localhost:3000
```

### 3. Deploy to Kubernetes (local)

```bash
# Install the Helm chart
helm upgrade --install my-app ./kubernetes/helm \
  -f kubernetes/helm/values.yaml \
  --namespace staging \
  --create-namespace

# Verify
kubectl get pods -n staging
kubectl get svc -n staging
```

### 4. CI/CD via GitHub Actions

Push to any branch → triggers the CI pipeline (test + build).
Merge to `main` → triggers the deploy pipeline (push image + deploy to EKS).

---

## Environments

| Environment | Branch | Namespace | Trigger |
|---|---|---|---|
| Staging | `develop` | `staging` | Push to develop |
| Production | `main` | `production` | Merge to main |

---

## CI/CD Pipeline Detail

```yaml
# .github/workflows/ci.yml fires on every push
on:
  push:
    branches: [main, develop]

jobs:
  test  →  build  →  push-image  →  deploy
```

### Job breakdown

**test** — checkout → install deps → run tests → upload results

**build** — checkout → docker build → tag with `${{ github.sha }}`

**push-image** — docker login → docker push to registry

**deploy** — configure AWS creds → helm upgrade --install on EKS

---

## Infrastructure Overview

```
                    ┌─────────────────────────────────┐
                    │           AWS (EKS)              │
                    │                                  │
Internet ──HTTPS──▶ │  ALB                             │
                    │   └── Ingress Controller         │
                    │         ├── /app → app-service   │
                    │         └── /api → api-service   │
                    │               └── Pods           │
                    │                                  │
                    │  Control plane: AWS managed      │
                    │  Workers: EC2 managed node group │
                    └─────────────────────────────────┘
```

---

## Key Decisions

**Why Docker?** Consistent environments — same image runs locally, in CI, and in production.

**Why GitHub Actions?** Built into GitHub — no separate CI server, workflow files live in the repo alongside the code.

**Why Helm?** Templated, versioned Kubernetes releases — one command to install, upgrade, or rollback the entire app.

**Why EKS?** AWS manages the control plane. We manage worker nodes and workloads. Production-grade Kubernetes without the ops burden.

---

## Study Notes

Notes created during learning sessions are in each folder:

| File | Topic |
|---|---|
| `kubernetes/service.md` | Services — ClusterIP, NodePort, LoadBalancer |
| `kubernetes/ingress-revision.md` | Ingress, controllers, routing rules |
| `kubernetes/eks-basics.md` | EKS architecture, shared responsibility, ALB flow |
| `kubernetes/helm-basics.md` | Helm charts, values, templates, releases |
| `cicd/github-actions.md` | Workflows, jobs, steps, runners, triggers |

---

## Useful Commands

```bash
# Docker
docker build -t my-app:latest .
docker run -p 3000:3000 my-app:latest
docker compose up --build

# Helm
helm upgrade --install my-app ./kubernetes/helm -f kubernetes/helm/values-prod.yaml
helm list -A
helm history my-app
helm rollback my-app 1

# Kubernetes
kubectl get pods -A
kubectl get svc -A
kubectl describe ingress -n production
kubectl logs -f deploy/my-app -n production
kubectl rollout status deploy/my-app -n production

# EKS
aws eks update-kubeconfig --name my-cluster --region ap-south-1
eksctl get nodegroup --cluster my-cluster
kubectl get nodes
```
