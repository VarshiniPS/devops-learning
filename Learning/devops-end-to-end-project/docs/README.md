# devops-end-to-end-project

A full DevOps pipeline built from scratch — Node.js app containerised with Docker,
deployed to Kubernetes, automated with GitHub Actions, and running on AWS EKS.

Every file in this repo was written, tested, and documented as part of a structured
learning programme covering Docker, Kubernetes, Helm, GitHub Actions, and AWS EKS.

---

## Overview

| Layer | Technology | Purpose |
|---|---|---|
| App | Node.js + Express | REST API with health/ready/info endpoints |
| Container | Docker (multi-stage) | Portable, reproducible image |
| Orchestration | Kubernetes | Self-healing, scalable deployment |
| Routing | Ingress (nginx) | Single entry point, path/host routing |
| CI/CD | GitHub Actions | Auto-test, build, push, deploy on push |
| Cloud | AWS EKS | Managed Kubernetes — AWS runs the control plane |
| Packaging | Helm | Versioned, templated K8s releases |

---

## Architecture

```
  Developer
     │
     │  git push
     ▼
  GitHub ──── triggers ────▶ GitHub Actions
                                   │
                          ┌────────┴────────┐
                          │                 │
                        test             build
                          │                 │
                          └────────┬────────┘
                                   │
                              push image
                                   │
                                   ▼
                           Docker Registry
                         (Docker Hub / ECR)
                                   │
                            helm upgrade
                                   │
                                   ▼
              ┌────────────────────────────────────────┐
              │             AWS EKS Cluster             │
              │                                        │
              │  Internet                              │
              │     │ HTTPS                            │
              │     ▼                                  │
              │   ALB (AWS Load Balancer)              │
              │     │                                  │
              │     ▼                                  │
              │  Ingress Controller (nginx)            │
              │     │                                  │
              │     ├── /        ──▶ nodejs-service    │
              │     ├── /health  ──▶ nodejs-service    │
              │     └── /api     ──▶ nodejs-service    │
              │                        │               │
              │                        ▼               │
              │               ClusterIP Service        │
              │            (selector: app=nodejs-app)  │
              │                        │               │
              │          ┌─────────────┼─────────────┐ │
              │          ▼             ▼             ▼ │
              │        Pod 1         Pod 2         Pod 3│
              │       :3000          :3000         :3000│
              │                                        │
              │  Control plane: AWS managed            │
              │  Workers: EC2 managed node groups      │
              └────────────────────────────────────────┘
```

---

## Folder Structure

```
devops-end-to-end-project/
│
├── app/                         # Node.js application
│   ├── app.js                   # Express server — /, /health, /ready, /info
│   ├── app.test.js              # Jest + Supertest — 5 tests, all passing
│   ├── package.json             # Dependencies: express. Dev: jest, supertest
│   └── .gitignore               # Excludes node_modules, coverage, .env
│
├── docker/
│   └── Dockerfile               # Multi-stage build (deps → runner), non-root user
│
├── kubernetes/
│   ├── deployment.yaml          # 3 replicas, rolling update, liveness/readiness probes
│   ├── service.yaml             # ClusterIP + NodePort + LoadBalancer (all three types)
│   ├── ingress.yaml             # Path-based routing → nodejs-service, TLS-ready
│   └── ingress.md               # Ingress architectural notes
│
├── docs/
│   ├── setup.md                 # Local Node.js setup and endpoint reference
│   └── docker.md                # Docker build, run, verify, and debug guide
│
├── .github/
│   └── workflows/
│       ├── ci.yml               # Test + build on every push
│       └── deploy.yml           # Push image + deploy to EKS on merge to main
│
├── Dockerfile                   # Root-level (for docker build -t node-app .)
├── .dockerignore                # Excludes node_modules, coverage, .env, .git
└── README.md
```

---

## Deployment Steps

### Phase 1 — Run locally

```bash
git clone https://github.com/<your-username>/devops-end-to-end-project.git
cd devops-end-to-end-project/app
npm install
npm test                         # 5 tests should pass
npm start                        # server on http://localhost:3000
```

### Phase 2 — Containerise

```bash
# Build image (from project root)
docker build -t node-app .

# Verify
docker images node-app           # should show ~130MB

# Run
docker run -d --name my-app -p 3000:3000 node-app

# Smoke test
curl http://localhost:3000/health
docker inspect --format='{{.State.Health.Status}}' my-app   # → healthy

# Cleanup
docker rm -f my-app
```

### Phase 3 — Deploy to Kubernetes

```bash
# Apply manifests in order
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml

# Verify deployment
kubectl get deployments
kubectl get pods
kubectl get svc
kubectl get ingress

# Watch pods come up
kubectl get pods -w

# Audit a specific resource
kubectl describe deployment devops-node-app
kubectl describe svc nodejs-service
kubectl describe ingress nodejs-ingress

# Test via Ingress (replace ADDRESS with kubectl get ingress output)
curl -H "Host: nodejs-app.example.com" http://<ADDRESS>/health
```

### Phase 4 — CI/CD via GitHub Actions

```bash
# Push to develop → runs CI (test + build)
git checkout -b develop
git push origin develop

# Merge to main → runs deploy (push image + helm upgrade on EKS)
git checkout main
git merge develop
git push origin main
```

### Phase 5 — EKS (AWS)

```bash
# Connect kubectl to EKS cluster
aws eks update-kubeconfig --name my-cluster --region ap-south-1

# Verify nodes
kubectl get nodes

# Deploy via Helm
helm upgrade --install nodejs-app ./kubernetes/helm \
  -f kubernetes/helm/values-prod.yaml \
  --namespace production \
  --create-namespace

# Verify
kubectl get pods -n production
kubectl get ingress -n production
```

---

## Docker Commands

```bash
# Build
docker build -t node-app .
docker build -t node-app:1.0.0 -t node-app:latest .

# Inspect
docker images node-app
docker history node-app          # see layer sizes

# Run
docker run -d --name my-app -p 3000:3000 node-app
docker run -d --name my-app -p 3000:3000 -e NODE_ENV=production node-app

# Debug
docker ps                        # running containers
docker ps -a                     # all containers including stopped
docker logs my-app
docker logs -f my-app            # follow live
docker exec -it my-app sh        # shell into container
docker inspect my-app            # full container metadata
docker inspect --format='{{.State.Health.Status}}' my-app

# Cleanup
docker rm -f my-app              # stop + remove container
docker rmi node-app              # remove image
docker system prune              # remove all unused resources
```

---

## Kubernetes Commands

```bash
# Apply
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml
kubectl apply -f kubernetes/            # apply entire folder

# Get (quick status)
kubectl get deployments
kubectl get pods
kubectl get pods -o wide             # includes node and IP
kubectl get pods -w                  # watch live
kubectl get svc
kubectl get ingress
kubectl get endpoints                # shows Pod IPs behind each Service
kubectl get all                      # everything in default namespace

# Describe (deep audit)
kubectl describe deployment devops-node-app
kubectl describe pod <pod-name>
kubectl describe svc nodejs-service
kubectl describe ingress nodejs-ingress

# Logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>           # follow live
kubectl logs deploy/devops-node-app  # logs from deployment (any pod)

# Debug
kubectl exec -it <pod-name> -- sh    # shell into pod
kubectl port-forward svc/nodejs-service 8080:80  # local access without Ingress

# Rollout
kubectl rollout status deploy/devops-node-app
kubectl rollout history deploy/devops-node-app
kubectl rollout undo deploy/devops-node-app      # rollback

# Scale
kubectl scale deploy/devops-node-app --replicas=5

# Delete
kubectl delete -f kubernetes/deployment.yaml
kubectl delete deploy devops-node-app
```

---

## Environments

| Environment | Branch | Namespace | Trigger |
|---|---|---|---|
| Local | — | default | manual |
| Staging | `develop` | `staging` | push to develop |
| Production | `main` | `production` | merge to main |

---

## App Endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/` | GET | Home — returns version and environment |
| `/health` | GET | Liveness probe — K8s restarts Pod if this fails |
| `/ready` | GET | Readiness probe — K8s stops traffic if this fails |
| `/info` | GET | App metadata — node version, PID, memory |

---

## Key Design Decisions

**Multi-stage Dockerfile** — stage 1 installs dependencies, stage 2 copies only
`node_modules` and `app.js`. No npm in the final image. Result: ~130MB vs ~900MB.

**Non-root container user** — containers run as `appuser`, not root. A container
escape gives an attacker an unprivileged shell, not root on the host.

**Three probe types** — `livenessProbe` restarts stuck Pods. `readinessProbe`
removes unready Pods from Service endpoints. `startupProbe` gives slow-starting
apps up to 5 minutes before liveness kicks in.

**ClusterIP as Ingress backend** — Ingress routes to the ClusterIP Service, not
directly to Pods. The Service handles load balancing across Pod replicas.

**Rolling update strategy** — `maxUnavailable: 1` and `maxSurge: 1` means at
most one Pod is down and one extra Pod is up during a deployment. Zero-downtime
updates by default.

**GitHub Actions `--install` flag** — `helm upgrade --install` is idempotent.
It installs if the release doesn't exist, upgrades if it does. Safe to run on
every push without checking state first.
