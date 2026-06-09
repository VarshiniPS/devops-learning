# GitHub Actions

## What is GitHub Actions?

GitHub Actions is GitHub's CI/CD platform that automates software workflows such as:

* Build
* Test
* Deploy

It allows automation directly from GitHub repositories.

---

# Why GitHub Actions?

Benefits:

* Built into GitHub
* No separate CI server required
* Easy automation
* Event-driven workflows
* Large marketplace of reusable actions

---

# GitHub Actions Architecture

```text
Developer
    ↓
git push
    ↓
GitHub Repository
    ↓
Workflow Trigger
    ↓
GitHub Actions Runner
    ↓
Build / Test / Deploy
```

---

# Key Components

## Workflow

A workflow is an automated process.

Stored in:

```text
.github/workflows/
```

Example:

```text
ci.yml
```

---

## Event Trigger

Defines when workflow starts.

Examples:

```yaml
on:
  push:
```

```yaml
on:
  pull_request:
```

```yaml
on:
  workflow_dispatch:
```

---

## Job

A workflow contains one or more jobs.

Example:

```yaml
jobs:
  build:
```

A job runs on a runner.

---

## Step

Each job contains steps.

Example:

```yaml
steps:
```

Examples:

```yaml
- run: echo "Hello"
```

```yaml
- uses: actions/checkout@v4
```

---

## Runner

A runner executes jobs.

Examples:

```yaml
runs-on: ubuntu-latest
```

```yaml
runs-on: windows-latest
```

```yaml
runs-on: self-hosted
```

---

# Workflow Example

```yaml
name: CI Pipeline

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - run: echo "Build Started"
```

---

# Common Triggers

## Push

```yaml
on:
  push:
```

Triggered when code is pushed.

---

## Pull Request

```yaml
on:
  pull_request:
```

Triggered when PR is created or updated.

---

## Manual Trigger

```yaml
on:
  workflow_dispatch:
```

Triggered manually.

---

# Common Use Cases

* Build Applications
* Run Unit Tests
* Run Security Scans
* Build Docker Images
* Push Docker Images
* Deploy to Kubernetes
* Deploy to AWS
* Terraform Automation

---

# GitHub Actions vs Jenkins

## GitHub Actions

Advantages:

* Built into GitHub
* Easy setup
* Less maintenance
* Cloud-hosted runners

---

## Jenkins

Advantages:

* More customization
* Large plugin ecosystem
* Better for complex enterprise pipelines

---

# Interview Questions

## What is GitHub Actions?

GitHub Actions is GitHub's built-in CI/CD platform used to automate build, test, and deployment workflows.

---

## What is a Workflow?

A workflow is an automated process defined in YAML files inside `.github/workflows`.

---

## What is a Job?

A job is a collection of steps executed on a runner.

---

## What is a Step?

A step is an individual task within a job.

---

## What is a Runner?

A runner is the machine that executes workflow jobs.

---

## What Triggers a Workflow?

Common triggers:

* push
* pull_request
* workflow_dispatch

---

## Difference Between Job and Step?

Job:

```text
Container of Tasks
```

Step:

```text
Individual Task
```

---

## GitHub Actions vs Jenkins?

GitHub Actions is built directly into GitHub and requires less maintenance, while Jenkins offers more customization and plugin support.

---

# Quick Revision

Workflow:

```text
Pipeline
```

Job:

```text
Group of Steps
```

Step:

```text
Single Task
```

Runner:

```text
Executes Jobs
```

Trigger:

```text
Starts Workflow
```
