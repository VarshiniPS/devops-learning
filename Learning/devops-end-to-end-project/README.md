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
                                   ▼
                           Docker Registry
                          (Docker Hub: v1, v2...)
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
              │  Service: ingress-nginx-controller       │
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
              │            selector: app=nodejs-app     │
              │                        │               │
              │          ┌─────────────┼─────────────┐ │
              │          ▼             ▼             ▼ │
              │  nodejs-deployment Pods (3 replicas)   │
              │       :3000          :3000        :3000│
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
│   ├── service.yaml             # ClusterIP + NodePort + LoadBalancer reference examples
│   ├── ingress.yaml             # nodejs-ingress → nodejs-service, path-based routing
│   └── ingress.md               # Ingress architecture notes + real incident writeup
│
├── docs/
│   ├── setup.md                 # Local Node.js setup and endpoint reference
│   └── docker.md                # Docker build, run, verify, and debug guide
│
├── .github/
│   └── workflows/
│       ├── ci.yml               # Test + build on every push
│       └── deploy.yml           # Push image + deploy on merge to main
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

### Phase 3 — Install Ingress Controller (one-time, Docker Desktop)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Wait ~30-60s, then confirm it's running
kubectl get pods -n ingress-nginx
# ingress-nginx-controller-xxxxx   1/1   Running
```

### Phase 4 — Deploy to Kubernetes

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

### Phase 5 — CI/CD via GitHub Actions

`.github/workflows/ci.yml` runs automatically on every push to `main` or
`develop`, and on every pull request targeting `main`.

```bash
git checkout -b develop
git push origin develop          # triggers CI: test + build

git checkout main
git merge develop
git push origin main             # triggers CI: test + build
```

**What the workflow does:**

| Job | Runs on | What it does |
|---|---|---|
| `test` | `ubuntu-latest` | Checks out code, installs deps with `npm ci`, runs the 5-test Jest suite, uploads coverage |
| `build` | `ubuntu-latest` | Needs `test` to pass first. Builds the Docker image from the root `Dockerfile`, tags it with the commit SHA, then runs it and curls `/health` as a smoke test |

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
docker build -f docker/Dockerfile -t myuser/node-app:v2 .   # versioned tag

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

# Push (to deploy a new version to the cluster)
docker push myuser/node-app:v2

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
kubectl set image deployment/nodejs-deployment <container-name>=myuser/node-app:v2
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

# Rebuild, push, and roll out the new image
docker build -f docker/Dockerfile -t myuser/node-app:v2 .
docker push myuser/node-app:v2
kubectl set image deployment/nodejs-deployment <container-name>=myuser/node-app:v2
kubectl rollout status deployment/nodejs-deployment
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