# Docker & Kubernetes Interview Questions

## 1. How does Docker build work?

Docker build reads instructions from a Dockerfile and creates a Docker image layer by layer.

Typical flow:

1. FROM pulls the base image
2. WORKDIR sets working directory
3. COPY copies files into image
4. RUN executes commands during image build
5. EXPOSE documents application port
6. CMD defines default command when container starts

Command:

```bash
docker build -t node-app:v1 .
```

Result:

* Docker image is created
* Image can be used to start containers

---

## 2. Image vs Container

### Docker Image

* Read-only blueprint
* Contains application code
* Contains dependencies
* Contains runtime

Example:

```text
node-app:v1
```

### Docker Container

* Running instance of an image
* Has its own process
* Has its own filesystem

Example:

```bash
docker run node-app:v1
```

### Difference

Image:

* Blueprint

Container:

* Running application

---

## 3. What problem does Docker solve?

Docker solves:

* Works on my machine problem
* Dependency conflicts
* Environment inconsistencies

Benefits:

* Consistent environments
* Faster deployments
* Isolation
* Better CI/CD integration
* Efficient resource usage

---

## 4. What is a Pod?

A Pod is the smallest deployable unit in Kubernetes.

A Pod:

* Contains one or more containers
* Shares network
* Shares storage

Example:

```text
Pod
 └── Node.js Container
```

---

## 5. Why do we need Deployments?

Pods alone do not provide:

* Self-healing
* Scaling
* Rolling updates

Deployments provide:

* Desired state management
* Replica management
* Self-healing
* Rolling updates
* Rollbacks

---

## 6. What are Replicas?

Replicas define how many Pod instances should be running.

Example:

```yaml
replicas: 3
```

Desired result:

```text
Pod-1
Pod-2
Pod-3
```

Benefits:

* High availability
* Fault tolerance
* Load distribution

---

## 7. What happens if a Pod crashes?

Flow:

1. Pod crashes
2. Replica count decreases
3. Deployment detects mismatch
4. ReplicaSet creates replacement Pod
5. Desired state restored

Example:

Desired:

```text
3 Pods
```

Current after crash:

```text
2 Pods
```

Deployment creates:

```text
New Pod
```

Result:

```text
3 Pods running
```

---

## 8. What is Self-Healing?

Self-healing means Kubernetes automatically restores failed workloads.

Examples:

* Pod crashes
* Node failure
* Container failure

Kubernetes automatically creates replacement Pods.

---

## 9. Pod vs Deployment

### Pod

* Runs containers
* Smallest deployable unit
* No self-healing

### Deployment

* Manages Pods
* Self-healing
* Scaling
* Rolling updates

---

## 10. Common Interview Questions

### What is Docker?

Docker is a containerization platform that packages applications and dependencies into containers.

---

### What is a Docker Image?

A read-only blueprint containing application code, runtime, and dependencies.

---

### What is a Docker Container?

A running instance of a Docker image.

---

### What happens during docker build?

Docker executes Dockerfile instructions and creates image layers.

---

### What is a Pod?

The smallest deployable unit in Kubernetes.

---

### Why use Deployments?

To provide self-healing, scaling, and rolling updates.

---

### What happens when a Pod crashes?

Deployment creates a replacement Pod through a ReplicaSet.

---

### What are replicas?

Desired number of Pod instances that should be running.
