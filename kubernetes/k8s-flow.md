# CI/CD to Kubernetes Flow 🚀

## Complete Architecture Flow

Developer
↓
GitHub Repository
↓
Jenkins CI/CD Pipeline
↓
Docker Image Build
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

## Flow Explanation

### Developer

Developer writes application code and pushes it to GitHub.

### GitHub

GitHub stores source code and version history.

### Jenkins

Jenkins automatically triggers CI/CD pipelines when new code is pushed.

### Docker

Docker packages the application and dependencies into portable container images.

### Docker Registry

Docker images are stored in registries such as Docker Hub or AWS ECR.

### Kubernetes Deployment

Kubernetes Deployment manages application deployment and desired Pod count.

### Pods

Pods run the actual application containers.

### Service

Service exposes the application and routes traffic to healthy Pods.

### Users

Users access the application through Kubernetes Service.

---

## Important Concepts

* Docker handles containerization.
* Kubernetes handles orchestration.
* Jenkins handles automation.
* GitHub handles source code management.
* CI/CD automates software delivery.
