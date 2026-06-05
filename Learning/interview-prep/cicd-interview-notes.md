# CI/CD Interview Notes

# What is CI/CD?

CI/CD stands for:

```text
CI = Continuous Integration
CD = Continuous Delivery / Continuous Deployment
```

CI/CD is a software delivery practice that automates building, testing, and deploying applications.

Benefits:

* Faster releases
* Reduced manual effort
* Consistent deployments
* Early bug detection
* Improved software quality

---

# Continuous Integration (CI)

Continuous Integration is the practice of frequently merging code changes into a shared repository.

Whenever developers push code:

```text
Git Push
    ↓
Build
    ↓
Test
    ↓
Feedback
```

Goal:

* Detect issues early
* Avoid integration problems
* Ensure code quality

---

# Continuous Delivery (CD)

Continuous Delivery ensures software is always ready for deployment.

Pipeline:

```text
Build
    ↓
Test
    ↓
Package
    ↓
Ready for Production
```

Deployment to production may require manual approval.

---

# Continuous Deployment

Continuous Deployment automatically deploys every successful change to production.

```text
Build
    ↓
Test
    ↓
Deploy
    ↓
Production
```

No manual approval required.

---

# CI/CD Pipeline Stages

## Stage 1: Source

Developer writes code.

```text
Developer
    ↓
Git Repository
```

Examples:

* GitHub
* GitLab
* Bitbucket

---

## Stage 2: Build

Application is compiled or packaged.

Examples:

```text
Java → JAR
Node.js → Build Artifacts
Docker → Docker Image
```

Goal:

Verify application can be built successfully.

---

## Stage 3: Test

Automated tests run.

Examples:

* Unit Tests
* Integration Tests
* Security Tests

Goal:

Verify code quality.

---

## Stage 4: Deploy

Application is deployed.

Examples:

* EC2
* Kubernetes
* ECS
* Virtual Machines

Goal:

Deliver application to users.

---

# Typical CI/CD Flow

```text
Developer
    ↓
Git Push
    ↓
CI/CD Tool
(Jenkins/GitHub Actions/GitLab CI)
    ↓
Build
    ↓
Test
    ↓
Create Artifact
    ↓
Deploy
    ↓
Production
```

---

# Real-World Example

Developer updates application code.

```text
git push
```

Pipeline automatically:

```text
Build Docker Image
    ↓
Run Tests
    ↓
Push Image to Registry
    ↓
Deploy to Kubernetes
```

No manual deployment required.

---

# Problems with Manual Deployment

Traditional Process:

```text
Developer
    ↓
Copy Files
    ↓
SSH Into Server
    ↓
Install Dependencies
    ↓
Restart Application
```

Problems:

* Human errors
* Inconsistent deployments
* Slow releases
* Downtime risks
* Difficult rollbacks

---

# Why CI/CD?

Without CI/CD:

```text
Manual Work
Manual Testing
Manual Deployment
```

With CI/CD:

```text
Automated Build
Automated Test
Automated Deploy
```

Benefits:

* Faster delivery
* Higher reliability
* Better consistency
* Reduced errors

---

# Popular CI/CD Tools

Examples:

* Jenkins
* GitHub Actions
* GitLab CI/CD
* Azure DevOps
* AWS CodePipeline

---

# CI vs CD

| CI                     | CD                             |
| ---------------------- | ------------------------------ |
| Continuous Integration | Continuous Delivery/Deployment |
| Build and Test         | Release and Deploy             |
| Focus on Code Quality  | Focus on Software Delivery     |

---

# Interview Questions

## What is CI/CD?

CI/CD is a software delivery practice that automates application building, testing, and deployment.

---

## What is Continuous Integration?

Continuous Integration is the practice of frequently integrating code changes into a shared repository and automatically validating them through builds and tests.

---

## What is Continuous Delivery?

Continuous Delivery ensures software is always in a deployable state and may require manual approval before production deployment.

---

## What is Continuous Deployment?

Continuous Deployment automatically deploys validated changes to production without manual approval.

---

## What are the stages of a CI/CD pipeline?

```text
Source
Build
Test
Deploy
```

---

## Why is CI/CD important?

CI/CD reduces manual effort, improves consistency, increases release speed, and detects issues early.

---

## What problems do manual deployments cause?

* Human errors
* Inconsistent environments
* Slow deployments
* Downtime risks
* Difficult rollback processes

---

# Quick Revision

```text
CI
↓
Build + Test

CD
↓
Deploy

Pipeline
↓
Source
Build
Test
Deploy

Manual Deployment
↓
Slow
Error-Prone

CI/CD
↓
Automated
Reliable
Fast
```
