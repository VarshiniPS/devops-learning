# Docker Interview Notes

## What is Docker?

Docker is a containerization platform that packages an application along with its dependencies, libraries, and runtime into a container.

Containers provide consistency across environments and help eliminate the "works on my machine" problem.

---

# Docker Architecture

```text
Developer
    |
Docker CLI
    |
Docker Daemon (dockerd)
    |
+----------------------+
|      Docker Host     |
|                      |
|  Images              |
|  Containers          |
|  Networks            |
|  Volumes             |
+----------------------+
    |
Docker Registry
(Docker Hub / ECR)
```

---

## Docker Components

### Docker Client (CLI)

Used by users to interact with Docker.

Examples:

```bash
docker build
docker run
docker ps
docker pull
```

---

### Docker Daemon (dockerd)

The Docker service running on the host.

Responsible for:

* Building images
* Running containers
* Managing networks
* Managing volumes

---

### Docker Registry

Stores Docker images.

Examples:

* Docker Hub
* Amazon ECR
* Google Artifact Registry

---

## Docker Image vs Container

### Docker Image

An image is a read-only blueprint used to create containers.

Contains:

* Application code
* Dependencies
* Runtime
* Libraries
* Configuration

Example:

```text
nginx:latest
ubuntu:22.04
python:3.11
```

---

### Docker Container

A container is a running instance of an image.

Example:

```text
Image
 ↓
Container 1
Container 2
Container 3
```

Multiple containers can be created from the same image.

---

## Interview Answer

### Difference Between Image and Container

Image is a blueprint or template containing application code and dependencies.

Container is a running instance of that image.

Analogy:

```text
Image = Class Blueprint

Container = Object Created From Class
```

or

```text
Image = Cake Recipe

Container = Actual Cake
```

---

# Dockerfile

A Dockerfile is a text file containing instructions used to build a Docker image.

Example:

```dockerfile
FROM nginx

COPY index.html /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

Build image:

```bash
docker build -t my-nginx .
```

---

## Common Dockerfile Instructions

### FROM

Base image.

```dockerfile
FROM ubuntu:22.04
```

---

### COPY

Copies files.

```dockerfile
COPY app.py /app
```

---

### RUN

Executes commands during image build.

```dockerfile
RUN apt-get update
```

---

### EXPOSE

Documents the port used.

```dockerfile
EXPOSE 8080
```

---

### CMD

Default command executed when container starts.

```dockerfile
CMD ["python","app.py"]
```

---

# Docker Layers

Every Dockerfile instruction creates a layer.

Example:

```dockerfile
FROM ubuntu
RUN apt-get update
RUN apt-get install nginx
COPY app.py /app
```

Layers:

```text
Layer 1 -> Ubuntu
Layer 2 -> apt update
Layer 3 -> nginx install
Layer 4 -> app.py
```

Benefits:

* Faster builds
* Layer caching
* Efficient storage usage

---

# Docker Volumes

Containers are ephemeral.

If a container is deleted, data stored inside it may be lost.

Volumes provide persistent storage.

Example:

```bash
docker volume create my-volume
```

Mount volume:

```bash
docker run -v my-volume:/data nginx
```

---

## Why Volumes?

* Persist data
* Share data between containers
* Separate storage from container lifecycle

---

# Port Mapping

Maps host ports to container ports.

Example:

```bash
docker run -p 8080:80 nginx
```

Meaning:

```text
Host Port      : 8080
Container Port : 80
```

Access:

```text
http://server-ip:8080
```

---

# Docker Networking

Allows containers to communicate.

Common network types:

### Bridge Network

Default network.

```text
Container A
     |
Bridge Network
     |
Container B
```

---

### Host Network

Container shares host network stack.

---

### None Network

No network connectivity.

---

# Docker Registry

Registry stores Docker images.

Flow:

```text
Build Image
     ↓
Push To Registry
     ↓
Pull On Server
     ↓
Run Container
```

Examples:

* Docker Hub
* Amazon ECR
* Azure Container Registry

---

# Frequently Asked Interview Questions

## What is Docker?

Docker is a containerization platform that packages applications and dependencies into portable containers.

---

## What problem does Docker solve?

It eliminates environment inconsistencies and ensures applications run the same across development, testing, and production environments.

---

## Difference Between Virtual Machine and Container?

### Virtual Machine

* Includes full operating system
* Heavier
* Slower startup

### Container

* Shares host kernel
* Lightweight
* Faster startup

---

## Difference Between Image and Container?

Image is a blueprint.

Container is a running instance of that image.

---

## What is a Dockerfile?

A Dockerfile contains instructions used to build Docker images.

---

## What are Docker Layers?

Each Dockerfile instruction creates a layer.

Layers enable caching and faster image builds.

---

## Why Use Docker Volumes?

Volumes provide persistent storage independent of the container lifecycle.

---

## What is Port Mapping?

Port mapping exposes a container port to the host system.

Example:

```bash
docker run -p 8080:80 nginx
```

---

## What is Docker Hub?

Docker Hub is a public registry used to store and share Docker images.

---

# Quick Revision

```text
Docker Image
    ↓
Docker Container

Dockerfile
    ↓
Build Image

Image
    ↓
Push To Registry

Registry
    ↓
Pull Image

Image
    ↓
Run Container

Volume
    ↓
Persistent Storage

Port Mapping
    ↓
Host ↔ Container Communication
```
