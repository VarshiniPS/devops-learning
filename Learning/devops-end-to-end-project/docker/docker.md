# Docker Setup

## Why Docker?

Without Docker, "it works on my machine" is a real problem — different Node.js
versions, OS differences, and missing dependencies cause inconsistencies between
local, CI, and production. Docker packages the app and everything it needs into a
single image that runs identically everywhere.

> One sentence: Docker = your app + its runtime, frozen into a portable image.

---

## File Structure

```
devops-end-to-end-project/
├── docker/
│   └── Dockerfile          ← multi-stage image definition
├── .dockerignore            ← files excluded from build context
└── app/
    ├── app.js
    └── package.json
```

---

## Dockerfile Explained

The Dockerfile uses a **multi-stage build** — two `FROM` stages in one file.
This keeps the final image small by leaving build tools behind.

```dockerfile
# ── Stage 1: install dependencies ─────────────────────────
FROM node:22-alpine AS deps

WORKDIR /app
COPY app/package*.json ./
RUN npm ci --only=production    # production deps only, no devDependencies


# ── Stage 2: production image ──────────────────────────────
FROM node:22-alpine AS runner

# Non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only what's needed from stage 1
COPY --from=deps /app/node_modules ./node_modules
COPY app/app.js ./

RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

ENV NODE_ENV=production \
    PORT=3000 \
    APP_VERSION=1.0.0

CMD ["node", "app.js"]
```

### Key decisions

| Decision | Why |
|---|---|
| `node:22-alpine` | Alpine Linux — tiny base image (~50MB vs ~900MB for full Node) |
| Multi-stage build | Stage 1 installs deps; Stage 2 copies only what's needed — no npm in final image |
| `npm ci` not `npm install` | Reproducible installs — fails if `package-lock.json` is out of sync |
| `--only=production` | Excludes `jest`, `supertest` from the image — smaller and more secure |
| Non-root user | Security best practice — containers shouldn't run as root |
| `HEALTHCHECK` | Docker monitors `/health` every 30s — marks container unhealthy if it fails |
| `EXPOSE 3000` | Documents intent — doesn't actually publish the port |

---

## .dockerignore

Prevents unnecessary files from being sent to the Docker build context:

```
app/node_modules     ← never copy local node_modules — image installs its own
app/coverage         ← test coverage output
app/app.test.js      ← tests not needed in production image
**/.env              ← never bake secrets into images
.git                 ← git history not needed
```

Without `.dockerignore`, Docker sends `node_modules` (hundreds of MB) to the
build context on every build — making it slow and bloated.

---

## Build the Image

Run from the project root (where `.dockerignore` lives):

```bash
# Build and tag with version + latest
docker build -f docker/Dockerfile -t devops-node-app:1.0.0 -t devops-node-app:latest .
```

### What each flag does

| Flag | Meaning |
|---|---|
| `-f docker/Dockerfile` | Path to the Dockerfile (since it's not in root) |
| `-t devops-node-app:1.0.0` | Tag the image with a version |
| `-t devops-node-app:latest` | Also tag as latest |
| `.` | Build context — the current directory |

### Expected output

```
[+] Building 45.2s
 => [deps 1/3] FROM node:22-alpine
 => [deps 2/3] COPY app/package*.json ./
 => [deps 3/3] RUN npm ci --only=production
 => [runner 1/5] RUN addgroup -S appgroup ...
 => [runner 2/5] COPY --from=deps /app/node_modules ./node_modules
 => [runner 3/5] COPY app/app.js ./
 => [runner 4/5] RUN chown -R appuser:appgroup /app
 => exporting to image
 => naming to devops-node-app:1.0.0
```

Second build is much faster — Docker caches layers. `npm ci` only re-runs
if `package.json` or `package-lock.json` changes.

### Check image size

```bash
docker images devops-node-app
# REPOSITORY        TAG      IMAGE ID       SIZE
# devops-node-app   1.0.0    a1b2c3d4e5f6   130MB
# devops-node-app   latest   a1b2c3d4e5f6   130MB
```

---

## Run the Container

```bash
docker run -d \
  --name my-app \
  -p 3000:3000 \
  devops-node-app:latest
```

| Flag | Meaning |
|---|---|
| `-d` | Detached mode — runs in background |
| `--name my-app` | Give the container a name (easier than using the ID) |
| `-p 3000:3000` | Map host port 3000 → container port 3000 |

### Run with environment variable overrides

```bash
docker run -d \
  --name my-app \
  -p 3000:3000 \
  -e NODE_ENV=staging \
  -e APP_VERSION=1.0.0 \
  devops-node-app:latest
```

---

## Verify the Application

### Check the container is running

```bash
docker ps
# CONTAINER ID   IMAGE                   STATUS          PORTS
# a1b2c3d4e5f6   devops-node-app:latest  Up 10 seconds   0.0.0.0:3000->3000/tcp
```

### Test all endpoints

```bash
# Home
curl http://localhost:3000/
# {"message":"Hello from the DevOps Node.js app!","version":"1.0.0","environment":"production"}

# Health (liveness probe)
curl http://localhost:3000/health
# {"status":"ok","uptime":12.3,"timestamp":"2024-01-15T10:00:00.000Z"}

# Ready (readiness probe)
curl http://localhost:3000/ready
# {"status":"ready","timestamp":"2024-01-15T10:00:00.000Z"}

# Info
curl http://localhost:3000/info
# {"name":"devops-node-app","version":"1.0.0","environment":"production","node":"v22.x.x",...}

# 404
curl http://localhost:3000/missing
# {"error":"Route not found","path":"/missing"}
```

### Check container logs

```bash
docker logs my-app
# Server running on port 3000
# Environment: production
# Version:     1.0.0

# Follow logs in real time
docker logs -f my-app
```

### Check Docker healthcheck status

```bash
docker inspect --format='{{.State.Health.Status}}' my-app
# healthy        ← good
# starting       ← wait 10s (start-period)
# unhealthy      ← /health endpoint is failing
```

### Exec into the container for debugging

```bash
docker exec -it my-app sh
# /app $ node --version
# /app $ ls
# /app $ exit
```

---

## Common Docker Commands

```bash
# Build
docker build -f docker/Dockerfile -t devops-node-app:latest .

# Run (detached)
docker run -d --name my-app -p 3000:3000 devops-node-app:latest

# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View logs
docker logs my-app
docker logs -f my-app           # follow (live)

# Stop and remove
docker stop my-app
docker rm my-app

# Stop + remove in one command
docker rm -f my-app

# Remove image
docker rmi devops-node-app:latest

# Shell into running container
docker exec -it my-app sh

# Inspect container details
docker inspect my-app

# Check image layers (see what's in the image)
docker history devops-node-app:latest

# Clean up stopped containers, unused images
docker system prune
```

---

## Image Tagging Strategy

In CI, tag images with the Git commit SHA so every image is traceable:

```bash
# In GitHub Actions:
IMAGE_TAG=${{ github.sha }}
docker build -t devops-node-app:$IMAGE_TAG -t devops-node-app:latest .
docker push devops-node-app:$IMAGE_TAG
docker push devops-node-app:latest
```

| Tag | When to use |
|---|---|
| `latest` | Most recent build on main branch |
| `1.0.0` | Semantic version for releases |
| `a1b2c3d` | Git commit SHA — used in CI, fully traceable |

---

## Common Gotchas

| Problem | Symptom | Fix |
|---|---|---|
| Build context too large | `docker build` is slow | Check `.dockerignore` — exclude `node_modules` |
| Port already in use | `bind: address already in use` | `docker rm -f my-app` or use different host port `-p 8080:3000` |
| Container exits immediately | `docker ps` shows Exited | Check `docker logs my-app` — likely an app error |
| `COPY` fails | `no such file` during build | Check paths — Dockerfile `COPY app/app.js` expects to run from project root |
| Healthcheck unhealthy | `unhealthy` status | Check `/health` returns 200 — `docker exec -it my-app wget -qO- localhost:3000/health` |
| Changes not reflected | Old code running | You must `docker build` again — running containers don't pick up file changes |
| `open Dockerfile: no such file` | Build fails even though a Dockerfile exists | You're not in the project root, or the Dockerfile lives in `docker/` not root — see below |
| Wrong directory when building | `COPY app/app.js` fails, or wrong Dockerfile picked up silently | Always run `docker build` from the **project root**, never from inside `app/` or `docker/` |

### Two Dockerfile locations — which to use

This project keeps a Dockerfile in two places for flexibility:

```
devops-end-to-end-project/
├── Dockerfile              ← build with: docker build -t node-app .
└── docker/
    └── Dockerfile          ← build with: docker build -f docker/Dockerfile -t node-app .
```

**Always run the build command from the project root**, regardless of which
Dockerfile you target. If you `cd` into `app/` or `docker/` first, `COPY app/app.js`
will fail with `no such file or directory` because the build context no longer
contains an `app/` folder relative to where you are.

```powershell
# Correct — from project root
cd devops-end-to-end-project
docker build -f docker/Dockerfile -t node-app .

# Wrong — from inside docker/ or app/
cd devops-end-to-end-project/docker
docker build -t node-app .          # fails: no such file or directory
```

### Stale image running old code

If you've edited `app.js` but the running container still shows old behaviour
(e.g. plain text instead of JSON, missing routes), the image was never rebuilt.
Editing source files locally never updates a container already running from
an older image.

```powershell
# Rebuild with a new tag
docker build -f docker/Dockerfile -t myuser/node-app:v2 .

# Push so Kubernetes can pull it
docker push myuser/node-app:v2

# Roll the Deployment to the new image
kubectl set image deployment/nodejs-deployment <container-name>=myuser/node-app:v2
kubectl rollout status deployment/nodejs-deployment
```

Verify which image a running Deployment actually uses before debugging app code:

```bash
kubectl get deployment nodejs-deployment -o jsonpath="{.spec.template.spec.containers[0].image}"
```

---

## What's Next

With a working Docker image:

1. **Push to a registry** — Docker Hub or AWS ECR
2. **GitHub Actions CI** — auto-build and push on every push to main
3. **Helm chart** — reference the image in `deployment.yaml`
4. **EKS deploy** — Helm pulls the image from the registry onto worker nodes

The `/health` and `/ready` endpoints built into `app.js` map directly to
Kubernetes liveness and readiness probes in the Helm chart:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
readinessProbe:
  httpGet:
    path: /ready
    port: 3000
```