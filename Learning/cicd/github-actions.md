# GitHub Actions

## What GitHub Actions Is

GitHub Actions is an automation engine built directly into GitHub. When something
happens in your repository — a push, a PR, a release, a scheduled time — it runs
a YAML-defined workflow on a machine called a runner.

> One sentence: GitHub Actions = event happens in repo → YAML workflow runs on a VM.

No separate CI server to maintain. No Jenkins to configure. The workflow file lives
in `.github/workflows/` alongside your code.

---

## The Five Core Concepts

### 1. Trigger (on:)

What causes the workflow to fire. Defined at the top of every workflow file.

```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'       # every Monday at 6am UTC
  workflow_dispatch:            # manual trigger from GitHub UI
  release:
    types: [published]
```

| Trigger | When it fires |
|---|---|
| `push` | Any commit pushed to matching branches |
| `pull_request` | PR opened, updated, or merged |
| `schedule` | Cron-based (nightly builds, weekly scans) |
| `workflow_dispatch` | Manually from GitHub UI or API |
| `release` | When a GitHub Release is published |

### 2. Workflow

The full automation definition — a single `.yml` file in `.github/workflows/`.
A repo can have multiple workflow files for different purposes (CI, CD, security scans).

```
.github/
  workflows/
    ci.yml          ← runs on every push
    deploy.yml      ← runs on release
    security.yml    ← runs on schedule
```

A workflow contains: a name, one or more triggers, and one or more jobs.

### 3. Jobs

A job is a set of steps that runs on a single runner. Jobs in the same workflow
run in parallel by default. Use `needs:` to sequence them.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps: [...]

  test:
    runs-on: ubuntu-latest
    needs: [build]            # waits for build to complete first
    steps: [...]

  deploy:
    runs-on: ubuntu-latest
    needs: [build, test]      # waits for both
    if: github.ref == 'refs/heads/main'
    steps: [...]
```

Key properties:
- `runs-on` — which runner to use
- `needs` — job dependencies (creates a DAG)
- `if` — conditional execution
- `environment` — deployment environment with protection rules

### 4. Steps

Steps are the individual tasks inside a job. They run sequentially on the same runner,
sharing the same file system. A step is either:

- `uses:` — runs a pre-built Action from the marketplace
- `run:` — runs shell commands directly

```yaml
steps:
  - name: Checkout code
    uses: actions/checkout@v4         # pre-built action

  - name: Install dependencies
    run: npm ci                       # shell command

  - name: Run tests
    run: |                            # multi-line shell
      npm test
      echo "Tests done"

  - name: Deploy
    env:
      TOKEN: ${{ secrets.API_TOKEN }} # inject secret as env var
    run: ./deploy.sh
```

### 5. Runners

The machine that executes your job. Two types:

| Type | Description | Cost |
|---|---|---|
| GitHub-hosted | Fresh VM per job, managed by GitHub | Free (limited) / metered |
| Self-hosted | Your own machine registered with GitHub | You pay for the infra |

GitHub-hosted runner labels:
- `ubuntu-latest` — Linux (most common)
- `windows-latest` — Windows
- `macos-latest` — macOS (most expensive)

Each job gets a brand-new VM — nothing persists between jobs unless you use artifacts.

---

## Full Workflow YAML (annotated)

```yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    name: Build
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: dist/

  test:
    name: Test
    runs-on: ubuntu-latest
    needs: [build]                    # runs after build

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: build-output
          path: dist/
      - run: npm test

  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    needs: [build, test]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    steps:
      - uses: actions/checkout@v4
      - name: Deploy to staging
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
        run: ./scripts/deploy.sh
```

---

## Push Trigger Flow

```
git push to main
      ↓
GitHub detects on: push event
reads .github/workflows/*.yml
      ↓
Jobs queued
(parallel unless needs: defined)
      ↓
Runner VM provisioned (fresh)
Repo checked out automatically
Steps execute sequentially
      ↓
Pass → green check on commit
Fail → red X + email notification
```

---

## Key Syntax Reference

### Contexts and expressions

```yaml
${{ github.ref }}            # branch/tag ref: refs/heads/main
${{ github.event_name }}     # push, pull_request, etc.
${{ github.sha }}            # commit SHA
${{ github.actor }}          # user who triggered the workflow
${{ secrets.MY_SECRET }}     # secret from repo settings
${{ env.MY_VAR }}            # environment variable
${{ steps.my-step.outputs.result }}  # output from a previous step
```

### Conditionals

```yaml
if: github.ref == 'refs/heads/main'
if: github.event_name == 'push'
if: failure()               # only run if a previous step failed
if: always()                # run regardless of pass/fail
if: success()               # only run if all previous steps passed
```

### Environment variables

```yaml
env:                          # workflow-level (all jobs)
  NODE_ENV: production

jobs:
  build:
    env:                      # job-level (all steps in this job)
      APP_VERSION: '1.0'
    steps:
      - name: Deploy
        env:                  # step-level (this step only)
          TOKEN: ${{ secrets.TOKEN }}
        run: ./deploy.sh
```

### Matrix builds (run same job across multiple configs)

```yaml
strategy:
  matrix:
    node-version: [18, 20, 22]
    os: [ubuntu-latest, windows-latest]

runs-on: ${{ matrix.os }}
steps:
  - uses: actions/setup-node@v4
    with:
      node-version: ${{ matrix.node-version }}
```

Runs 3 × 2 = 6 jobs in parallel.

### Artifacts (pass data between jobs)

```yaml
# Upload (in build job)
- uses: actions/upload-artifact@v4
  with:
    name: dist-files
    path: dist/
    retention-days: 7

# Download (in test or deploy job)
- uses: actions/download-artifact@v4
  with:
    name: dist-files
    path: dist/
```

### Caching (speed up repeated installs)

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'              # caches ~/.npm between runs
```

Or manually:

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
```

---

## Essential Marketplace Actions

| Action | Purpose |
|---|---|
| `actions/checkout@v4` | Check out repo code — always the first step |
| `actions/setup-node@v4` | Install Node.js |
| `actions/setup-python@v5` | Install Python |
| `actions/setup-java@v4` | Install Java |
| `actions/upload-artifact@v4` | Save files for later jobs or download |
| `actions/download-artifact@v4` | Retrieve uploaded artifacts |
| `actions/cache@v4` | Cache dependencies between runs |
| `docker/login-action@v3` | Log into Docker Hub or ECR |
| `docker/build-push-action@v5` | Build and push Docker image |
| `aws-actions/configure-aws-credentials@v4` | Set up AWS CLI credentials |

---

## Common Gotchas

| Problem | Symptom | Fix |
|---|---|---|
| Workflow not triggering | No run appears | Check branch name matches `branches:` exactly |
| Jobs run in wrong order | Test runs before build | Add `needs: [build]` to test job |
| Secret not found | Empty env var | Add secret in repo Settings → Secrets and variables |
| Artifact not found | download-artifact fails | Upload and download `name:` must match exactly |
| Cache miss every run | Slow installs | Check `key:` includes the lock file hash |
| `npm install` vs `npm ci` | Inconsistent installs | Always use `npm ci` in CI — it's faster and stricter |
| File permissions fail | `./script.sh` permission denied | Add `chmod +x scripts/*.sh` step before running |
| Workflow YAML syntax error | Workflow doesn't appear | Validate with `actionlint` locally or check the Actions tab error |

---

## Workflow File Location

```
your-repo/
  .github/
    workflows/
      ci.yml          ← created and committed like any other file
      deploy.yml
  src/
  package.json
```

GitHub detects and runs any `.yml` file in `.github/workflows/` automatically.
No registration or setup needed beyond creating the file.

---

## Key Takeaways

1. Trigger (`on:`) → Workflow (`.yml`) → Jobs (parallel) → Steps (sequential) → Runner (fresh VM).
2. Jobs run in parallel by default. `needs:` makes them sequential.
3. Steps share the same runner and file system. Jobs do not — use artifacts to pass files.
4. GitHub-hosted runners are fresh VMs every time — nothing persists between jobs.
5. Use `secrets.` for credentials — never hardcode tokens in YAML.
6. `npm ci` not `npm install` in CI — faster, reproducible, fails if lock file is out of sync.
7. Always pin action versions (`@v4`) — avoid `@main` or `@latest` in production workflows.
