# AWS EKS Basics

## What is EKS?

EKS (Elastic Kubernetes Service) is a managed Kubernetes service provided by AWS.

AWS manages the Kubernetes Control Plane while customers manage the Worker Nodes.

Purpose:

* Run Kubernetes on AWS
* Reduce Kubernetes administration effort
* Improve reliability and availability
* Simplify cluster management

---

# EKS Architecture

```text
Users
   ↓
Application Load Balancer (ALB)
   ↓
EKS Cluster
   ↓
Worker Nodes
   ↓
Pods
```

---

# Control Plane

The Control Plane is the brain of Kubernetes.

Responsibilities:

* API Server
* Scheduler
* Controller Manager
* etcd

Functions:

* Receives kubectl requests
* Schedules Pods
* Maintains cluster state
* Monitors resources

In EKS:

```text
AWS manages the Control Plane
```

You do not manage:

* etcd
* API Server
* Control Plane upgrades
* High availability of Control Plane

---

# Worker Nodes

Worker Nodes are EC2 instances that run application workloads.

Responsibilities:

* Run Pods
* Execute containers
* Provide CPU and memory
* Communicate with Control Plane

Components:

```text
kubelet
kube-proxy
Container Runtime
```

Example:

```text
Node-1
 ├── Pod-A
 ├── Pod-B

Node-2
 ├── Pod-C
 ├── Pod-D
```

---

# Node Groups

Node Groups are collections of worker nodes managed together.

Purpose:

* Simplify node management
* Scale nodes
* Apply common configuration

Types:

## Managed Node Group

AWS manages:

* Node provisioning
* Updates
* Lifecycle management

Most commonly used.

---

## Self-Managed Node Group

You manage:

* EC2 instances
* Scaling
* Patching
* Updates

More operational effort.

---

# EKS vs Self-Managed Kubernetes

## EKS

AWS manages:

```text
Control Plane
etcd
High Availability
Control Plane Upgrades
```

You manage:

```text
Worker Nodes
Pods
Applications
```

Advantages:

* Less operational overhead
* High availability
* Easier upgrades
* AWS integration

---

## Self-Managed Kubernetes

You manage everything:

```text
Control Plane
etcd
Worker Nodes
Networking
Upgrades
Backups
```

Advantages:

* Full control
* Cloud-independent

Disadvantages:

* More complexity
* More maintenance

---

# Traffic Flow in EKS

```text
User Request
      ↓
Application Load Balancer
      ↓
Kubernetes Service
      ↓
Pod
```

Example:

```text
Internet User
      ↓
ALB
      ↓
Service
      ↓
Pod-1
Pod-2
Pod-3
```

---

# Why Use ALB?

Application Load Balancer:

* Distributes traffic
* Provides high availability
* Supports path-based routing
* Supports host-based routing
* Integrates with Kubernetes Ingress

---

# EKS Interview Questions

## What is EKS?

EKS is AWS's managed Kubernetes service where AWS manages the Control Plane and customers manage worker nodes and applications.

---

## What is the Control Plane?

The Control Plane manages the Kubernetes cluster and consists of API Server, Scheduler, Controller Manager, and etcd.

---

## What does AWS manage in EKS?

AWS manages:

* API Server
* etcd
* Scheduler
* Control Plane availability
* Control Plane upgrades

---

## What are Worker Nodes?

Worker Nodes are EC2 instances that run Pods and application workloads.

---

## What is a Node Group?

A Node Group is a collection of worker nodes managed together for easier scaling and administration.

---

## Difference Between Managed and Self-Managed Node Groups?

Managed:

```text
AWS manages nodes
```

Self-Managed:

```text
You manage nodes
```

---

## EKS vs Self-Managed Kubernetes?

EKS reduces operational overhead because AWS manages the Control Plane.

Self-managed Kubernetes provides more control but requires more maintenance.

---

# Quick Revision

EKS:

```text
Managed Kubernetes Service
```

Control Plane:

```text
Cluster Brain
```

Worker Node:

```text
Runs Pods
```

Node Group:

```text
Collection of Worker Nodes
```

ALB:

```text
Routes External Traffic
```

AWS Manages:

```text
Control Plane
```

You Manage:

```text
Worker Nodes
Applications
Pods
```
