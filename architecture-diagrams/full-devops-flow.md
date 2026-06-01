# Full DevOps Flow 🚀

## End-to-End Architecture

Developer
↓
GitHub
↓
Jenkins Pipeline
↓
Docker Build
↓
Docker Registry
↓
Kubernetes Deployment
↓
Pods
↓
Service
↓
Users

---

## Step-by-Step Explanation

### Developer

Writes code and pushes changes to GitHub.

### GitHub

Stores source code and maintains version history.

### Jenkins

Automates CI/CD process:

* Pull code
* Build application
* Run tests
* Build Docker image
* Trigger deployment

### Docker

Packages application and dependencies into a portable container image.

### Docker Registry

Stores Docker images for deployment.

### Kubernetes Deployment

Manages desired state and application rollout.

### Pods

Run the actual application containers.

### Service

Provides stable networking and routes traffic to Pods.

### Users

Access the application through the Kubernetes Service.

---

## Key Responsibilities

GitHub → Source Code Management

Jenkins → Automation / CI-CD

Docker → Containerization

Kubernetes → Orchestration

Service → Networking

Pods → Running Application

---

## Biggest Learning

Docker runs containers.

Kubernetes manages containers at scale using:

* Deployments
* ReplicaSets
* Services
* Self-healing
* Rolling updates
* Scaling
