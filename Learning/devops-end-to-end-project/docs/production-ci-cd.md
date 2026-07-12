# Production CI/CD Flow

## Complete Pipeline

```
Developer → GitHub → GitHub Actions → Docker Build → Amazon ECR → EKS → Service → Ingress → Users
```

Every arrow in this chain is now automated in `.github/workflows/ci.yml`
across four jobs: `test`, `build`, `push`, `deploy`.

---

## Job-by-Job Breakdown

### 1. test

Checks out code, installs deps with `npm ci`, runs the Jest suite (5 tests),
uploads coverage as an artifact. Nothing downstream runs if this fails.

### 2. build (needs: test)

Builds the Docker image from the project Dockerfile, loads it into the local
daemon (`load: true`), then smoke-tests it — runs the container and curls
`/health` before declaring success. This catches "builds fine but crashes on
start" bugs that a build-only check would miss.

### 3. push (needs: build, main/master only)

Authenticates to AWS via OIDC (`aws-actions/configure-aws-credentials`,
`role-to-assume` — no long-lived AWS keys stored as GitHub secrets), logs into
ECR, rebuilds using the GHA layer cache from the previous job (fast), and
pushes two tags: the commit SHA and `latest`.

**Why the commit SHA tag matters:** `latest` is a moving target — you can't
tell which code is actually running. The SHA tag is the traceable one; a
running Pod's image tag maps directly back to an exact commit.

### 4. deploy (needs: push, main/master only)

Points `kubectl` at the EKS cluster via `aws eks update-kubeconfig`, then
runs `kubectl set image` to roll the Deployment to the new SHA-tagged image.
This triggers a standard RollingUpdate — same mechanism as a manual
`kubectl apply` (see `docs/rolling-updates.md`).

`kubectl rollout status --timeout=300s` blocks the job until the rollout
finishes or fails — a stuck rollout becomes a **failed CI run**, not a silent
problem discovered later.

---

## Full Traffic Path (after deploy)

```
Users
  │  HTTPS request, Host header
  ▼
Ingress Controller (nginx)
  │  matches rule by path/host
  ▼
nodejs-service (ClusterIP/NodePort)
  │  label selector: app=nodejs-app
  ▼
Pod (one of 3 replicas, running the SHA-tagged image)
  │
  ▼
app.js route handler
```

---

## Security Note: OIDC over Static Keys

The `push` and `deploy` jobs use `role-to-assume` with GitHub's OIDC
provider, not static `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` secrets.
GitHub Actions exchanges a short-lived token for temporary AWS credentials
scoped to that specific workflow run. No long-lived AWS keys ever sit in
GitHub Secrets waiting to be leaked.

Requires a one-time AWS setup: an IAM role with a trust policy for
`token.actions.githubusercontent.com`, scoped to your specific repo.

---

## Branch Gating

`push` and `deploy` only run `if: github.ref == 'refs/heads/main' ||
github.ref == 'refs/heads/master'`. Feature branches and PRs run `test` and
`build` (catching bugs early) but never touch ECR or the live EKS cluster.

---

## What Changed From the Learning Version

| Before | Now |
|---|---|
| `build` job only, image never pushed anywhere | `push` job publishes to Amazon ECR |
| No deploy step — manual `kubectl apply` | `deploy` job runs `kubectl set image` automatically |
| Tags: commit SHA + `latest`, local only | Same tags, now pushed to the real ECR registry |
| No AWS auth in workflow | OIDC-based AWS auth added for both `push` and `deploy` |

---

## Key Takeaways

1. Four jobs, each gating the next: `test → build → push → deploy`. A failure
   anywhere stops the chain before it reaches production.
2. The build job's smoke test (`curl /health` on the running container) is
   the cheapest bug-catch in the whole pipeline — do this before any push.
3. Commit-SHA image tags are the traceable ones. `latest` is convenience,
   not a record of what's actually deployed.
4. OIDC role assumption avoids storing long-lived AWS credentials as GitHub
   secrets — the safer default for any cloud deploy from CI.
5. `push` and `deploy` are branch-gated — only `main`/`master` reaches ECR
   and EKS. Feature branches get tested and built, never deployed.
6. `kubectl rollout status --timeout` turns a stuck production rollout into
   a failed CI job instead of a silent, undetected problem.