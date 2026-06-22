# Local Setup Guide

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Node.js | v18+ | https://nodejs.org |
| npm | v9+ | Bundled with Node.js |
| Git | any | https://git-scm.com |

Check your versions:

```bash
node --version    # v22.x.x
npm --version     # 10.x.x
git --version     # git version 2.x.x
```

---

## Project Structure

```
devops-end-to-end-project/
└── app/
    ├── app.js          ← Express server (main entry point)
    ├── app.test.js     ← Jest tests for all routes
    ├── package.json    ← dependencies and npm scripts
    └── .gitignore      ← excludes node_modules, coverage, .env
```

---

## Step 1 — Clone and install

```bash
git clone https://github.com/<your-username>/devops-end-to-end-project.git
cd devops-end-to-end-project/app
npm install
```

`npm install` reads `package.json` and installs:
- `express` — web framework (production dependency)
- `jest` + `supertest` — testing (dev dependencies only)

---

## Step 2 — Run the app locally

```bash
npm start
# Server running on port 3000
# Environment: development
# Version:     1.0.0
```

The server starts on port 3000 by default. Override with an environment variable:

```bash
PORT=8080 npm start
```

For development with auto-restart on file changes (Node.js v18+):

```bash
npm run dev
```

---

## Step 3 — Test the endpoints

With the server running, open a new terminal and curl each route:

### GET / — home

```bash
curl http://localhost:3000/
```

```json
{
  "message": "Hello from the DevOps Node.js app!",
  "version": "1.0.0",
  "environment": "development"
}
```

### GET /health — liveness probe

Used by Kubernetes to check if the container is alive.

```bash
curl http://localhost:3000/health
```

```json
{
  "status": "ok",
  "uptime": 12.34,
  "timestamp": "2024-01-15T10:00:00.000Z"
}
```

### GET /ready — readiness probe

Used by Kubernetes to decide whether to send traffic to the Pod.

```bash
curl http://localhost:3000/ready
```

```json
{
  "status": "ready",
  "timestamp": "2024-01-15T10:00:00.000Z"
}
```

### GET /info — app metadata

```bash
curl http://localhost:3000/info
```

```json
{
  "name": "devops-node-app",
  "version": "1.0.0",
  "environment": "development",
  "node": "v22.x.x",
  "pid": 12345,
  "memory": { "rss": 30000000, "heapTotal": 10000000, "heapUsed": 8000000 }
}
```

### 404 — unknown route

```bash
curl http://localhost:3000/does-not-exist
```

```json
{
  "error": "Route not found",
  "path": "/does-not-exist"
}
```

---

## Step 4 — Run tests

```bash
npm test
```

Expected output:

```
PASS ./app.test.js
  GET /
    ✓ returns 200 with a welcome message
  GET /health
    ✓ returns 200 with status ok
  GET /ready
    ✓ returns 200 with status ready
  GET /info
    ✓ returns 200 with app metadata
  GET /unknown-route
    ✓ returns 404 for unknown routes

Tests: 5 passed, 5 total
```

Coverage report is generated in `coverage/` after each run.
Open `coverage/lcov-report/index.html` in a browser to view line-by-line coverage.

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `3000` | Port the server listens on |
| `NODE_ENV` | `development` | Runtime environment |
| `APP_VERSION` | `1.0.0` | Version shown in `/` and `/info` |

Set multiple at once with a `.env` file (not committed to Git):

```bash
# app/.env
PORT=3000
NODE_ENV=development
APP_VERSION=1.0.0
```

Load it when starting:

```bash
node -e "require('fs').readFileSync('.env','utf8').split('\n').forEach(l=>{const[k,v]=l.split('=');if(k)process.env[k]=v})" && node app.js
# or just export manually:
export PORT=3000 NODE_ENV=production APP_VERSION=2.0.0
npm start
```

---

## npm Scripts Reference

| Command | What it does |
|---|---|
| `npm start` | Start the server (`node app.js`) |
| `npm run dev` | Start with auto-restart on file change |
| `npm test` | Run Jest tests with coverage |
| `npm run test:watch` | Run tests in watch mode (re-runs on save) |

---

## Why These Routes?

| Route | Purpose in Kubernetes |
|---|---|
| `/` | Application entry point |
| `/health` | **Liveness probe** — if this fails, K8s restarts the Pod |
| `/ready` | **Readiness probe** — if this fails, K8s stops sending traffic |
| `/info` | Debugging — check which version/env is running in a Pod |

These routes are referenced in the Helm chart's `deployment.yaml`:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 15

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 10
```

---

## What's Next

Once the app runs and tests pass locally:

1. **Dockerise** — wrap in a container (`docker/Dockerfile`)
2. **CI Pipeline** — GitHub Actions runs `npm test` on every push
3. **Build and push** — Docker image tagged with commit SHA, pushed to registry
4. **Deploy** — Helm chart installs the image onto EKS

See `docs/architecture.md` for the full pipeline overview.