# devops-end-to-end-project

A full DevOps pipeline built from scratch — a Node.js app containerised with
Docker, deployed to Kubernetes, routed through Ingress, and automated with
GitHub Actions toward AWS EKS.

Every file in this repo was written, tested, deployed, and debugged on a real
local cluster as part of a structured learning programme covering Docker,
Kubernetes, Helm, GitHub Actions, and AWS EKS.

---

## Project Overview

The app is a minimal Express server with four routes designed specifically
to map onto Kubernetes health-check semantics: `/health` for liveness,
`/ready` for readiness, `/info` for runtime debugging, and `/` as the
public-facing home route.

The full chain — verified working end-to-end on Docker Desktop Kubernetes —
looks like this:

```
curl → localhost:80 → Ingress Controller → nodejs-ingress rules
     → nodejs-service → Pod (3 replicas) → app.js route handler
```

This project intentionally documents real failures and fixes encountered
along the way (see **Troubleshooting** below) — not just the happy path.

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Runtime | Node.js 22 + Express | REST API with health/ready/info endpoints |
| Testing | Jest + Supertest | 5 passing tests covering every route |
| Container | Docker (multi-stage, alpine) | ~130MB image, non-root user |
| Orchestration | Kubernetes (Docker Desktop) | Self-healing, 3-replica deployment |
| Routing | Ingress (nginx controller) | Single entry point, path-based routing |
| CI/CD | GitHub Actions | Auto-test, build, push on every push |
| Registry | Amazon ECR | Private Docker image registry on AWS |
| Packaging | Helm | Versioned, templated K8s releases (planned) |
| Cloud target | AWS EKS | Managed Kubernetes control plane (planned) |

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
                         ┌─────────▼──────────┐
                         │    Amazon ECR       │
                         │  (private registry) │
                         │  715708572462.dkr   │
                         │  .ecr.us-east-1     │
                         │  .amazonaws.com     │
                         │  /my-app:latest     │
                         └─────────┬──────────┘
                                   │
                          kubectl set image
                                   │
                                   ▼
              ┌────────────────────────────────────────┐
              │      Kubernetes (Docker Desktop)        │
              │                                        │
              │  curl http://localhost                 │
              │     │                                  │
              │     ▼                                  │
              │  Ingress Controller (nginx)             │
              │  Service: ingress-nginx-controller      │
              │  LoadBalancer → localhost:80            │
              │     │                                  │
              │     ▼                                  │
              │  nodejs-ingress (rules)                 │
              │     ├── /        ──▶ nodejs-service     │
              │     ├── /health  ──▶ nodejs-service     │
              │     ├── /ready   ──▶ nodejs-service     │
              │     └── /info    ──▶ nodejs-service     │
              │                        │               │
              │                        ▼               │
              │               nodejs-service (NodePort)│
              │            selector: app=nodejs-app    │
              │                        │               │
              │          ┌─────────────┼─────────────┐ │
              │          ▼             ▼             ▼ │
              │  nodejs-deployment Pods (3 replicas)   │
              │       :3000          :3000        :3000│
              └────────────────────────────────────────┘
```

---

## Amazon ECR

Amazon ECR (Elastic Container Registry) is the private Docker image registry used
in this project. GitHub Actions authenticates with ECR, pushes the built image, and
EKS pulls from it on every deployment — replacing the Docker Hub step used locally.

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
| Auth required to pull | Yes (12h token) | No |
| Use case | Production workloads | Open source images |
| URL format | `<account>.dkr.ecr.<region>.amazonaws.com` | `public.ecr.aws/<alias>` |

### Pushing an Image to ECR

```bash
# 1. Authenticate Docker (token valid 12 hours)
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS --password-stdin \
  715708572462.dkr.ecr.us-east-1.amazonaws.com

# 2. Build image
docker build -f docker/Dockerfile -t varshinips/node-app .

# 3. Tag for ECR
docker tag varshinips/node-app:latest \
  715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

# 4. Push
docker push 715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

# 5. Verify
aws ecr list-images --repository-name my-app --region us-east-1
```

---

## Amazon EKS Deployment

Amazon EKS (Elastic Kubernetes Service) is the managed Kubernetes control plane this
project deploys to. AWS manages the API server, etcd, and scheduler — you never see
or SSH into those servers. `kubectl` talks to the EKS API server the same way it talks
to any Kubernetes cluster; the difference is *how it authenticates*.

### How kubectl Connects to EKS

```
kubectl command
      │
      ▼
~/.kube/config (kubeconfig)
      │  cluster API endpoint + IAM-based auth
      ▼
AWS IAM Authenticator
      │  signs request using your AWS credentials
      ▼
EKS API Server (AWS-managed control plane)
      │
      ▼
Cluster responds (nodes, pods, etc.)
```

### Cluster Details

| Field | Value |
|---|---|
| **Cluster Name** | `my-cluster` |
| **Region** | `us-east-1` |
| **Kubernetes Version** | 1.36 |
| **Node Group** | `my-nodes` (Managed Node Group) |
| **Instance Type** | `t3.micro` (Free Tier eligible) |
| **Scaling Config** | min: 1, max: 2, desired: 2 |
| **Node IAM Role** | `EKS-psv` |

### Worker Nodes vs Managed Node Groups

| Concept | What it is |
|---|---|
| **Worker Node** | An EC2 instance that runs your Pods |
| **Managed Node Group** | AWS-managed group of EC2 worker nodes — handles provisioning and lifecycle |
| **EKS Auto Mode** | Fully automated compute — AWS picks instance types itself (disabled in this project; see Troubleshooting) |

This project uses a **Managed Node Group**, not Auto Mode — full control over instance
type was needed to stay within Free Tier eligibility.

### Connecting kubectl to the Cluster

```bash
# Point kubectl at the EKS cluster
aws eks update-kubeconfig --region us-east-1 --name my-cluster

# Verify connection
kubectl get nodes
```

Expected output:
```
NAME                                          STATUS   ROLES    AGE   VERSION
ip-192-168-11-22.us-east-1.compute.internal   Ready    <none>   10m   v1.36
ip-192-168-33-44.us-east-1.compute.internal   Ready    <none>   10m   v1.36
```

### Deploying the App to EKS

```bash
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml

# Verify
kubectl get pods
kubectl get svc
kubectl get ingress
```

> On real EKS (unlike Docker Desktop), `kubectl get ingress` shows a real **AWS ALB
> DNS name** under `ADDRESS` once the Ingress Controller provisions it — this is the
> actual public entry point for users.

### ECR → EKS Flow

```
Amazon ECR                          Amazon EKS
715708572462.dkr.ecr                       │
.us-east-1.amazonaws.com                    │
/my-app:latest                              │
      │                                     │
      │  image URI referenced in            │
      │  kubernetes/deployment.yaml          │
      ▼                                     ▼
   ┌─────────────────────────────────────────────┐
   │  kubectl apply -f deployment.yaml            │
   │        │                                     │
   │        ▼                                     │
   │  EKS schedules Pods onto worker nodes        │
   │        │                                     │
   │        ▼                                     │
   │  Worker node's IAM role (EKS-psv) pulls      │
   │  image from ECR using                        │
   │  AmazonEC2ContainerRegistryReadOnly policy   │
   │        │                                     │
   │        ▼                                     │
   │  Pod starts running node-app container       │
   └─────────────────────────────────────────────┘
```

**Key requirement:** the node IAM role (`EKS-psv`) must have
`AmazonEC2ContainerRegistryReadOnly` attached — without it, Pods fail with
`ImagePullBackOff` because worker nodes can't authenticate to ECR.

---

## CI/CD Pipeline Flow

Every `git push` to `main` triggers the full pipeline automatically:

```
Developer (local machine)
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
      ├── 2. npm ci + run Jest tests (5 tests)
      ├── 3. docker build -f docker/Dockerfile -t varshinips/node-app .
      ├── 4. Authenticate with ECR
      │       aws ecr get-login-password | docker login ...
      ├── 5. docker tag → ECR URI
      ├── 6. docker push → ECR
      └── 7. kubectl set image → rolling deploy to EKS
      │
      ▼
Amazon ECR
(715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest)
      │
      │  EKS pulls image on deployment
      ▼
Amazon EKS
      │
      ├── Deployment (3 replica Pods running node-app)
      ├── Service (nodejs-service → ClusterIP/NodePort)
      └── Ingress (path-based routing → ALB)
      │
      ▼
    Users
```

### GitHub Actions Jobs

| Job | Runs on | What it does |
|---|---|---|
| `test` | `ubuntu-latest` | Checks out code, runs `npm ci`, runs 5-test Jest suite, uploads coverage |
| `build` | `ubuntu-latest` | Needs `test` to pass. Builds image, tags with commit SHA, pushes to ECR, smoke-tests `/health` |

---

## Active Deployment Architecture

```
                        ┌──────────────────────────────────────────┐
                        │            Amazon EKS Cluster             │
                        │                                          │
   Internet             │   ┌──────────────────────────────────┐  │
      │                 │   │         Ingress (ALB)            │  │
      │  HTTP/HTTPS     │   │   nodejs-ingress                 │  │
      └────────────────►│   │   / → nodejs-service             │  │
                        │   │   /health → nodejs-service       │  │
                        │   │   /ready  → nodejs-service       │  │
                        │   │   /info   → nodejs-service       │  │
                        │   └──────────────┬───────────────────┘  │
                        │                  │                       │
                        │   ┌──────────────▼───────────────────┐  │
                        │   │    nodejs-service (NodePort)      │  │
                        │   │    selector: app=nodejs-app       │  │
                        │   └──────┬──────────┬────────┬────────┘  │
                        │          │          │        │           │
                        │   ┌──────▼──┐ ┌────▼────┐ ┌▼────────┐  │
                        │   │  Pod 1  │ │  Pod 2  │ │  Pod 3  │  │
                        │   │  :3000  │ │  :3000  │ │  :3000  │  │
                        │   │node-app │ │node-app │ │node-app │  │
                        │   └─────────┘ └─────────┘ └─────────┘  │
                        │                                          │
                        │   Worker Nodes (EC2)                     │
                        └──────────────────────────────────────────┘
                                          │
                                          │  pulls image on deploy
                                          ▼
                              ┌───────────────────────────┐
                              │        Amazon ECR          │
                              │  715708572462.dkr.ecr      │
                              │  .us-east-1.amazonaws.com  │
                              │  /my-app:latest            │
                              └───────────────────────────┘
```

### Traffic Flow (Request Lifecycle)

```
User Request (HTTP)
      │
      ▼
AWS ALB — provisioned by Ingress Controller
      │  matches path rules (/, /health, /ready, /info)
      ▼
nodejs-ingress rules
      │  routes to nodejs-service
      ▼
nodejs-service (NodePort)
      │  load balances across 3 Pod replicas
      ▼
Pod (node-app container on port 3000)
      │
      ▼
Response → User
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
│   ├── service.yaml             # ClusterIP + NodePort + LoadBalancer reference examples
│   ├── ingress.yaml             # nodejs-ingress → nodejs-service, path-based routing
│   └── ingress.md               # Ingress architecture notes + real incident writeup
│
├── docs/
│   ├── setup.md                 # Local Node.js setup and endpoint reference
│   ├── docker.md                # Docker build, run, verify, and debug guide
│   └── ecr-notes.md             # ECR concepts, private vs public, push walkthrough
│
├── .github/
│   └── workflows/
│       ├── ci.yml               # Test + build on every push
│       └── deploy.yml           # Push image to ECR + deploy on merge to main
│
├── Dockerfile                   # Root-level copy (docker build -t node-app .)
├── .dockerignore                # Excludes node_modules, coverage, .env, .git
└── README.md                    # This file
```

> **Note:** two Dockerfiles exist in this repo — one at root, one in `docker/`.
> Both work; always run `docker build` from the **project root** regardless
> of which you target. See Troubleshooting below for why this matters.

---

## Setup Instructions

### Prerequisites

| Tool | Version | Check |
|---|---|---|
| Node.js | 18+ | `node --version` |
| npm | 9+ | `npm --version` |
| Docker Desktop | latest, Kubernetes enabled | `docker --version` |
| kubectl | matching cluster version | `kubectl version --client` |
| AWS CLI | latest | `aws --version` |

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
# Build image — MUST run from project root
cd devops-end-to-end-project
docker build -f docker/Dockerfile -t node-app .

# Verify (~130MB with alpine base)
docker images node-app

# Run
docker run -d --name my-app -p 3000:3000 node-app

# Smoke test
curl http://localhost:3000/health
docker inspect --format='{{.State.Health.Status}}' my-app   # → healthy

# Cleanup
docker rm -f my-app
```

### Phase 3 — Push to Amazon ECR

```bash
# Authenticate Docker with ECR
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS --password-stdin \
  715708572462.dkr.ecr.us-east-1.amazonaws.com

# Tag image for ECR
docker tag varshinips/node-app:latest \
  715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

# Push
docker push 715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

### Phase 4 — Install Ingress Controller (one-time, Docker Desktop)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Wait ~30-60s, then confirm it's running
kubectl get pods -n ingress-nginx
# ingress-nginx-controller-xxxxx   1/1   Running
```

### Phase 5 — Deploy to Kubernetes

```bash
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml

# Verify
kubectl get deployments
kubectl get pods
kubectl get svc
kubectl get ingress

# On Docker Desktop, ADDRESS may show an internal bridge IP (e.g. 172.18.0.5)
# — use http://localhost directly, Docker Desktop auto-maps port 80
curl -H "Host: nodejs-app.example.com" http://localhost/health
curl -H "Host: nodejs-app.example.com" http://localhost/
curl -H "Host: nodejs-app.example.com" http://localhost/ready
```

### Phase 6 — CI/CD via GitHub Actions

`.github/workflows/ci.yml` runs automatically on every push to `main` or
`develop`, and on every pull request targeting `main`.

```bash
git checkout -b develop
git push origin develop          # triggers CI: test + build

git checkout main
git merge develop
git push origin main             # triggers CI: test + build + push to ECR
```

**What the workflow does:**

| Job | Runs on | What it does |
|---|---|---|
| `test` | `ubuntu-latest` | Checks out code, installs deps with `npm ci`, runs the 5-test Jest suite, uploads coverage |
| `build` | `ubuntu-latest` | Needs `test` to pass first. Builds the Docker image from the root `Dockerfile`, tags it with the commit SHA, pushes to ECR, then runs it and curls `/health` as a smoke test |

**Key concepts:**

- **Checkout** — every job starts on an empty VM. `actions/checkout@v4` clones
  the repo onto it; without this step, no code exists on the runner.
- **Push trigger** — `on: push: branches: [main, develop]` scopes which
  branches fire the workflow. Feature branches won't trigger this unless
  explicitly listed.
- **`needs: [test]`** — makes `build` wait for `test` to succeed. Jobs run in
  parallel by default; `needs` creates a dependency.
- **`working-directory: ./app`** — since `package.json` lives in `app/`, not
  the repo root, every npm step needs this to run in the right folder.
- **Smoke test** — the build job doesn't just build the image, it runs it and
  curls `/health` before declaring success. Catches the kind of "builds fine
  but doesn't actually start" bug that a build-only check would miss.

View runs at: `https://github.com/<your-username>/devops-end-to-end-project/actions`

---

## Docker Commands

```bash
# Build (always from project root)
docker build -f docker/Dockerfile -t node-app .
docker build -f docker/Dockerfile -t varshinips/node-app:v2 .   # versioned tag

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
docker inspect --format='{{.State.Health.Status}}' my-app

# Push to ECR
docker tag varshinips/node-app:latest \
  715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
docker push 715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

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
kubectl get pods --show-labels       # verify selector matching
kubectl get all                      # everything in default namespace

# Describe (deep audit)
kubectl describe deployment nodejs-deployment
kubectl describe pod <pod-name>
kubectl describe svc nodejs-service
kubectl describe ingress nodejs-ingress

# Check which image is actually running
kubectl get deployment nodejs-deployment -o jsonpath="{.spec.template.spec.containers[0].image}"

# Logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>           # follow live
kubectl logs <pod-name> --previous   # logs from before last restart (crash debugging)

# Debug
kubectl exec -it <pod-name> -- sh                 # shell into pod
kubectl port-forward svc/nodejs-service 8080:80   # local access bypassing Ingress

# Update image (rolling deploy)
kubectl set image deployment/nodejs-deployment <container-name>=715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:v2
kubectl rollout status deployment/nodejs-deployment

# Rollout
kubectl rollout history deploy/nodejs-deployment
kubectl rollout undo deploy/nodejs-deployment      # rollback

# Scale
kubectl scale deploy/nodejs-deployment --replicas=5

# Delete
kubectl delete -f kubernetes/deployment.yaml
kubectl delete deploy nodejs-deployment
```

---

## Troubleshooting

Real issues hit and resolved while building this project — kept here as a
debugging reference for future incidents.

### Ingress `ADDRESS` stays blank

**Symptom:** `kubectl get ingress` shows no value under `ADDRESS`, even after
many minutes.

**Cause:** No Ingress Controller is installed in the cluster — the Ingress
resource exists but nothing is enforcing its rules.

**Fix:**
```bash
kubectl get pods -n ingress-nginx
# if empty or missing, install:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
```

---

### `docker build` fails with `COPY app/app.js`: no such file or directory

**Symptom:** Build fails immediately on a `COPY` step.

**Cause:** You're not running `docker build` from the project root — you're
inside `app/` or `docker/`, so the relative path `app/app.js` doesn't resolve.

**Fix:** Always `cd` to the project root before building:
```bash
cd devops-end-to-end-project
docker build -f docker/Dockerfile -t node-app .
```

---

### `open Dockerfile: no such file or directory` despite a Dockerfile existing

**Symptom:** Plain `docker build -t node-app .` fails even though `dir Dockerfile`
shows a file.

**Cause:** This project keeps Dockerfiles in two locations — root and `docker/`.
If the root one is missing, empty, or shadowed (e.g. by a OneDrive sync
placeholder), `docker build .` with no `-f` flag fails.

**Fix:** Point explicitly at the known-good copy:
```bash
docker build -f docker/Dockerfile -t node-app .
```

---

### Container responds, but with the wrong content (e.g. plain text instead of JSON)

**Symptom:** `curl /health` returns something like `DevOps Mini Project Running`
instead of `{"status":"ok",...}`.

**Cause:** The running container is using an **older image** than your current
`app.js`. Editing source files locally never updates an already-running
container — you must rebuild and redeploy.

**Fix:**
```bash
# Confirm what's actually running
kubectl get deployment nodejs-deployment -o jsonpath="{.spec.template.spec.containers[0].image}"

# Rebuild, push to ECR, and roll out the new image
docker build -f docker/Dockerfile -t varshinips/node-app:v2 .
docker tag varshinips/node-app:v2 \
  715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:v2
docker push 715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:v2
kubectl set image deployment/nodejs-deployment <container-name>=715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:v2
kubectl rollout status deployment/nodejs-deployment
```

---

### ECR authentication error: `no basic auth credentials`

**Symptom:** `docker push` to ECR fails with auth error.

**Cause:** The ECR login token has expired (valid 12 hours) or you haven't
authenticated this session.

**Fix:**
```bash
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS --password-stdin \
  715708572462.dkr.ecr.us-east-1.amazonaws.com
```

---

### Every route returns the same response, but `kubectl describe ingress` shows healthy Backends

**Symptom:** `/health`, `/`, and `/api` all return the same body — the home
page response — even though Backends list correct Pod IPs for every path.

**Cause:** The `nginx.ingress.kubernetes.io/rewrite-target: /` annotation
rewrites **every matched path to `/`** before forwarding to the Service.
This is correct for single-page apps, but silently breaks multi-route APIs.

**Fix:** Remove the annotation entirely if your app has more than one
meaningful route:
```yaml
# Remove this line from ingress.yaml annotations:
nginx.ingress.kubernetes.io/rewrite-target: /
```
Then `kubectl apply -f kubernetes/ingress.yaml` and retest.

---

### Port already in use when running `docker run`

**Symptom:** `bind: Only one usage of each socket address ... permitted`

**Cause:** Either a previous container is already bound to that port, or
something else on the host occupies it.

**Fix:**
```bash
docker rm -f my-app && docker run -d --name my-app -p 3000:3000 node-app
# or use a different host port
docker run -d --name my-app -p 3001:3000 node-app
```

---

### Service shows `Endpoints: <none>`

**Symptom:** `kubectl describe svc nodejs-service` shows no endpoints, traffic
returns 503.

**Cause:** The Service `selector` doesn't match the Pod's `labels`.

**Fix:**
```bash
kubectl get pods --show-labels
kubectl describe svc nodejs-service     # compare Selector: line against labels above
```

---

### Pod stuck in `CrashLoopBackOff`

**Fix:**
```bash
kubectl logs <pod-name>              # current crash reason
kubectl logs <pod-name> --previous   # if it crashed before logging anything useful
kubectl describe pod <pod-name>      # check Events section at the bottom
```

---

### `kubectl get nodes` -> "the server has asked for the client to provide credentials"

**Symptom:** `aws eks update-kubeconfig` succeeds, but `kubectl get nodes` fails with
an auth error, not a connectivity error.

**Cause:** Your IAM user/role isn't mapped in the cluster's Access Entries (or the
older `aws-auth` ConfigMap on legacy clusters). EKS clusters maintain their own
internal list of which AWS identities are allowed in -- being able to reach AWS
doesn't mean you're authorized inside this specific cluster.

**Fix:**
```bash
# Confirm which identity you're using
aws sts get-caller-identity

# Grant that identity access
aws eks create-access-entry \
  --cluster-name my-cluster \
  --principal-arn arn:aws:iam::<account-id>:user/<your-user> \
  --region us-east-1

aws eks associate-access-policy \
  --cluster-name my-cluster \
  --principal-arn arn:aws:iam::<account-id>:user/<your-user> \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region us-east-1
```

---

### `kubectl get nodes` -> "No resources found"

**Symptom:** No auth error, but zero nodes returned.

**Cause:** The cluster's control plane is up, but no Managed Node Group exists yet,
or its nodes failed to launch/join.

**Fix:** Check if a node group exists and what state it's in:
```bash
aws eks list-nodegroups --cluster-name my-cluster --region us-east-1
aws eks describe-nodegroup --cluster-name my-cluster --nodegroup-name <name> --region us-east-1
```

---

### Node group launch fails: "The specified instance type is not eligible for Free Tier"

**Symptom:** `describe-nodegroup` shows `"health": {"issues": []}` and stays stuck
in `CREATING` indefinitely, or the ASG shows `DesiredCapacity` higher than actual
`Instances`.

**Cause:** The account is Free Tier-restricted, and the chosen instance type
(`t3.medium`, and on some accounts even `t2.micro`) isn't Free Tier eligible. AWS
blocks the EC2 launch outright -- a failure the node group's own health check
doesn't always surface immediately.

**Fix:** Check the ASG's actual scaling activity log for the real reason, and confirm
which instance types are Free Tier eligible **for your specific account** (this list
has changed over time -- `t2.micro` isn't the only or even the current default):
```bash
# Find the ASG name
aws eks describe-nodegroup --cluster-name my-cluster --nodegroup-name my-nodes \
  --region us-east-1 --query "nodegroup.resources.autoScalingGroups"

# Check why launches failed
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <asg-name> --region us-east-1 --max-items 5

# Confirm Free Tier eligible types for this account
aws ec2 describe-instance-types \
  --filters "Name=free-tier-eligible,Values=true" \
  --region us-east-1 --query "InstanceTypes[].InstanceType" --output text
```
Then delete and recreate the node group with an eligible type (e.g. `t3.micro`):
```bash
aws eks delete-nodegroup --cluster-name my-cluster --nodegroup-name my-nodes --region us-east-1
aws eks wait nodegroup-deleted --cluster-name my-cluster --nodegroup-name my-nodes --region us-east-1

aws eks create-nodegroup --cluster-name my-cluster --nodegroup-name my-nodes \
  --region us-east-1 --node-role arn:aws:iam::<account-id>:role/<node-role> \
  --subnets <subnet-1> <subnet-2> \
  --scaling-config minSize=1,maxSize=2,desiredSize=2 \
  --instance-types t3.micro
```

---

### Node group status: "Create failed -- Instances failed to join the kubernetes cluster"

**Symptom:** EC2 instances launch successfully (visible in the EC2 console), but the
node group still reports `Create failed`, and `kubectl get nodes` never shows them.

**Cause:** The node's IAM role is missing one or more of the three policies a
Managed Node Group actually needs to register with the cluster. This commonly
happens when the role was originally set up for **EKS Auto Mode** (which uses a
different policy set: `AmazonEKSComputePolicy`, `AmazonEKSNetworkingPolicy`,
`AmazonEKSBlockStoragePolicy`, etc.) rather than for traditional worker nodes.

**Fix:** Attach the three policies traditional worker nodes require:
```bash
aws iam attach-role-policy --role-name <node-role> \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam attach-role-policy --role-name <node-role> \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam attach-role-policy --role-name <node-role> \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```
Then delete and recreate the node group (existing failed instances won't self-heal
by attaching policies after the fact):
```bash
aws eks delete-nodegroup --cluster-name my-cluster --nodegroup-name my-nodes --region us-east-1
aws eks wait nodegroup-deleted --cluster-name my-cluster --nodegroup-name my-nodes --region us-east-1
aws eks create-nodegroup --cluster-name my-cluster --nodegroup-name my-nodes --region us-east-1 \
  --node-role arn:aws:iam::<account-id>:role/<node-role> \
  --subnets <subnet-1> <subnet-2> \
  --scaling-config minSize=1,maxSize=2,desiredSize=2 \
  --instance-types t3.micro
```

---

### EKS Auto Mode launching its own nodes unexpectedly

**Symptom:** EC2 `RunInstances` failures appear in CloudTrail with
`"invokedBy": "eks.amazonaws.com"`, for instance types you never requested
(e.g. `c6a.large`), separate from your own `create-nodegroup` calls.

**Cause:** **EKS Auto Mode** is enabled on the cluster and is independently trying
to provision its own `system` and `general-purpose` node pools, choosing instance
types automatically -- which can hit the same Free Tier restrictions.

**Fix:** Confirm Auto Mode is on, then disable it if you're managing nodes manually:
```bash
# Confirm
aws eks describe-cluster --name my-cluster --region us-east-1 --query "cluster.computeConfig"

# Disable (compute, storage, and load balancing configs must be updated together)
aws eks update-cluster-config --name my-cluster --region us-east-1 \
  --compute-config enabled=false \
  --kubernetes-network-config elasticLoadBalancing={enabled=false} \
  --storage-config blockStorage={enabled=false}

# Check progress
aws eks describe-update --name my-cluster --region us-east-1 --update-id <update-id>
```


---

## Screenshots

_Add screenshots here to visually document the working deployment:_

- `kubectl get nodes` showing both worker nodes `Ready`
- `kubectl get pods` showing 3/3 Pods `Running`
- `kubectl get svc` and `kubectl get ingress` output
- EKS Console -- Node groups tab showing `my-nodes` Active
- ECR Console -- repository showing pushed image tags

> Suggested path: `docs/screenshots/` -- reference them here with
> `![Nodes Ready](docs/screenshots/nodes-ready.png)` once captured.

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

**No `rewrite-target` annotation** — learned the hard way. This annotation
rewrites every Ingress path to `/`, which is wrong for any app with more than
one meaningful route. Omit it unless building a single-page app.

**ClusterIP/NodePort as Ingress backend** — Ingress routes to the Service,
never directly to Pods. The Service handles load balancing across replicas.

**Rolling update strategy** — `maxUnavailable: 1` and `maxSurge: 1` means at
most one Pod is down and one extra Pod is up during a deployment. Zero-downtime
updates by default.

**Always build from project root** — both Dockerfiles use paths like
`COPY app/app.js`, which only resolve correctly when the build context is the
repository root, regardless of which `-f` target is used.

**Amazon ECR over Docker Hub for AWS workloads** — ECR is IAM-native, meaning
no separate credentials to manage when running on EKS. Image pulls from ECR to
EKS worker nodes stay within the AWS network — faster and no egress costs.