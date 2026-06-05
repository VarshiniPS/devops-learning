# Jenkins Interview Notes

# What is Jenkins?

Jenkins is an open-source automation server used to implement CI/CD pipelines.

Jenkins automates:

* Build
* Test
* Deploy

Benefits:

* Faster releases
* Reduced manual effort
* Consistent deployments
* Integration with many tools

---

# Why Jenkins?

Without Jenkins:

```text
Developer
    ↓
Manual Build
    ↓
Manual Testing
    ↓
Manual Deployment
```

Problems:

* Human errors
* Slow releases
* Inconsistent deployments

With Jenkins:

```text
Developer
    ↓
Git Push
    ↓
Jenkins
    ↓
Build
    ↓
Test
    ↓
Deploy
```

Everything becomes automated.

---

# Jenkins Architecture

## Master-Agent Architecture

```text
Jenkins Master
      |
      +---- Agent 1
      |
      +---- Agent 2
      |
      +---- Agent 3
```

---

# Jenkins Master

Responsibilities:

* Manage jobs
* Schedule builds
* Manage agents
* Store pipeline configurations
* Handle user access

Think:

```text
Brain of Jenkins
```

---

# Jenkins Agent

Responsibilities:

* Execute builds
* Run tests
* Deploy applications

Think:

```text
Worker Node
```

---

# Why Agents?

Without agents:

```text
All Builds
     ↓
Single Jenkins Server
```

Problems:

* Resource bottleneck
* Slow execution

With agents:

```text
Master
   |
   +---- Agent 1
   +---- Agent 2
   +---- Agent 3
```

Multiple jobs can run simultaneously.

---

# Jenkins Pipeline Flow

```text
Developer
    ↓
GitHub
    ↓
Webhook Trigger
    ↓
Jenkins
    ↓
Build
    ↓
Test
    ↓
Deploy
```

---

# Jenkinsfile

A Jenkinsfile defines the pipeline as code.

Benefits:

* Version controlled
* Repeatable
* Easy to maintain

Example:

```groovy
pipeline {
    agent any

    stages {

        stage('Build') {
            steps {
                echo 'Building Application'
            }
        }

        stage('Test') {
            steps {
                echo 'Running Tests'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying Application'
            }
        }

    }
}
```

---

# Pipeline Stages

## Build Stage

Purpose:

* Compile code
* Build artifacts
* Create Docker image

Examples:

```bash
mvn package
docker build
```

---

## Test Stage

Purpose:

* Validate application

Examples:

```bash
mvn test
pytest
npm test
```

---

## Deploy Stage

Purpose:

* Deploy application

Examples:

* EC2
* Kubernetes
* ECS
* On-Prem Servers

---

# Build Triggers

## 1. Manual Trigger

User clicks:

```text
Build Now
```

---

## 2. Poll SCM

Jenkins periodically checks Git repository.

Example:

```text
Every 5 Minutes
```

---

## 3. Webhook Trigger

GitHub notifies Jenkins immediately after a push.

Flow:

```text
Developer Pushes Code
        ↓
GitHub Webhook
        ↓
Jenkins Triggered
```

Most common method.

---

# Real World Jenkins Flow

Developer pushes code:

```bash
git push
```

Pipeline starts:

```text
GitHub
   ↓
Webhook
   ↓
Jenkins
   ↓
Build Docker Image
   ↓
Run Tests
   ↓
Push Image to Registry
   ↓
Deploy to Kubernetes
```

---

# Jenkins Plugins

Jenkins functionality is extended through plugins.

Examples:

* Git Plugin
* Docker Plugin
* Kubernetes Plugin
* AWS Plugin
* Slack Plugin

---

# Freestyle Job vs Pipeline

## Freestyle Job

Traditional Jenkins job.

Configured through UI.

---

## Pipeline Job

Defined in Jenkinsfile.

Stored in Git.

Preferred approach.

---

# Interview Questions

## What is Jenkins?

Jenkins is an automation server used to implement CI/CD pipelines.

---

## What is Jenkins Master?

The Master manages jobs, schedules builds, and controls agents.

---

## What is a Jenkins Agent?

An Agent executes builds, tests, and deployment tasks.

---

## Why Use Jenkins Agents?

Agents distribute workload and allow parallel execution of jobs.

---

## What is a Jenkinsfile?

A Jenkinsfile is a pipeline definition stored as code.

---

## What are Pipeline Stages?

Typical stages:

```text
Build
Test
Deploy
```

---

## What are Build Triggers?

Mechanisms that start Jenkins jobs.

Examples:

* Manual Trigger
* Poll SCM
* Webhook

---

## Difference Between Poll SCM and Webhook?

Poll SCM:

```text
Jenkins checks Git periodically
```

Webhook:

```text
GitHub notifies Jenkins immediately
```

Webhook is preferred.

---

# Quick Revision

```text
Jenkins
↓
CI/CD Automation

Master
↓
Controls Jobs

Agent
↓
Executes Jobs

Jenkinsfile
↓
Pipeline as Code

Stages
↓
Build
Test
Deploy

Trigger
↓
Webhook

Developer
↓
GitHub
↓
Jenkins
↓
Build
↓
Test
↓
Deploy
```
