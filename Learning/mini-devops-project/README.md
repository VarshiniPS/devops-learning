# DevOps Mini Project

## Overview

Simple Node.js Express application created for DevOps practice.

## Tech Stack

* Node.js
* Express
* Docker
* Kubernetes (later)
* GitHub Actions (later)

## Run Locally

Install dependencies:

```bash
npm install
```

Start application:

```bash
node app.js
```

Access:

```text
http://localhost:3000
```

## Docker

Dockerfile created and ready for image build.

( Docker build will be completed in the next session )

## Progress

### Completed

* Terraform State Management
* Remote State (S3)
* DynamoDB Locking
* Kubernetes HPA
* Helm Basics
* AWS EKS Basics
* GitHub Actions
* Node.js Mini Project Setup
* Dockerfile Creation

### In Progress

* Docker Image Build
* Docker Hub Push
* Kubernetes Deployment

### Upcoming

* Kubernetes Deployment YAML
* GitHub Actions CI Pipeline
* EKS Deployment

## Docker Mini Project

### Topics Covered

* Docker Image vs Container
* Dockerfile Instructions
* Layer Caching
* Node.js Containerization
* Port Mapping
* Docker Build Process

### Dockerfile Instructions Practiced

* FROM
* WORKDIR
* COPY
* RUN
* EXPOSE
* CMD

### Commands Used

```bash
docker build -t node-app:v1 .

docker run -d -p 3000:3000 --name node-app node-app:v1

docker ps

docker logs node-app
```

### Key Learning

A Docker image is a read-only blueprint containing the application and its dependencies, while a container is a running instance of that image.

Docker layers improve build performance through caching, especially when package.json is copied before application code.

```
## Docker Mini Project - Node.js Application

### Objective

Dockerize a Node.js application and run it inside a container.

### Docker Concepts Practiced

* Docker Image vs Container
* Dockerfile
* Docker Layers
* Port Mapping
* Docker Build Process
* Container Lifecycle

### Dockerfile Used

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

### Commands Executed

```bash
docker build -t node-app .

docker images

docker run -d -p 3000:3000 --name node-app-container node-app

docker ps

docker logs node-app-container

docker stop node-app-container
```

### Key Learning

A Docker image is a read-only blueprint that contains the application and its dependencies.

A Docker container is a running instance of the Docker image.

Docker layers improve build performance through caching and layer reuse.


