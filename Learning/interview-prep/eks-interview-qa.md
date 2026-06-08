# EKS Interview Questions & Answers

## Question 1: What is EKS?

### Answer

Amazon EKS (Elastic Kubernetes Service) is a managed Kubernetes service provided by AWS.

It allows organizations to run Kubernetes clusters without managing the Kubernetes Control Plane.

AWS manages:

* API Server
* Scheduler
* Controller Manager
* etcd
* Control Plane availability

Users manage:

* Worker Nodes
* Pods
* Applications

---

# Question 2: What is the Difference Between EKS and Kubernetes on EC2?

## Kubernetes on EC2

You install and manage Kubernetes yourself.

You manage:

* Control Plane
* etcd
* API Server
* Upgrades
* Backups
* Worker Nodes

Architecture:

```text id="mmsm5u"
You Manage Everything
```

---

## EKS

AWS manages:

* Control Plane
* etcd
* High Availability
* Control Plane Upgrades

You manage:

* Worker Nodes
* Applications
* Pods

Architecture:

```text id="p4o8x3"
AWS Manages Control Plane
You Manage Workloads
```

---

## Interview Answer

EKS is a managed Kubernetes service where AWS manages the Control Plane. In self-managed Kubernetes on EC2, the organization is responsible for managing the entire cluster including Control Plane components, upgrades, backups, and availability.

---

# Question 3: What Components Does AWS Manage in EKS?

AWS manages:

```text id="gzjlwm"
API Server
Scheduler
Controller Manager
etcd
Control Plane High Availability
Control Plane Upgrades
```

AWS responsibility:

```text id="m8km2k"
Control Plane
```

---

# Question 4: What Components Do You Manage in EKS?

You manage:

```text id="6q3w63"
Worker Nodes
Pods
Applications
Deployments
Services
Ingress
```

Customer responsibility:

```text id="3ebuhk"
Application Layer
```

---

# Question 5: What is a Worker Node?

A Worker Node is an EC2 instance that runs Kubernetes Pods.

Responsibilities:

* Run containers
* Provide CPU and memory
* Execute workloads
* Communicate with Control Plane

Components:

```text id="d1o1eo"
kubelet
kube-proxy
container runtime
```

---

# Question 6: What is a Node Group?

A Node Group is a collection of Worker Nodes managed together.

Benefits:

* Easier scaling
* Easier administration
* Common configuration

Types:

```text id="3wt2hy"
Managed Node Group
Self-Managed Node Group
```

---

# Question 7: What is the Difference Between Managed and Self-Managed Node Groups?

## Managed Node Group

AWS manages:

* Provisioning
* Updates
* Lifecycle

Most common choice.

---

## Self-Managed Node Group

You manage:

* EC2 instances
* Updates
* Scaling
* Patching

Provides more control but increases operational overhead.

---

# Question 8: What is ECS?

ECS (Elastic Container Service) is AWS's native container orchestration service.

It manages containers without requiring Kubernetes.

AWS-specific service.

---

# Question 9: Difference Between EKS and ECS?

## EKS

Uses:

```text id="mopm5e"
Kubernetes
```

Benefits:

* Kubernetes standard
* Portable across clouds
* Large ecosystem
* Helm support
* Kubernetes skills transferable

---

## ECS

Uses:

```text id="if3g7z"
AWS Native Scheduler
```

Benefits:

* Simpler
* Easier to learn
* Deep AWS integration
* Less operational complexity

---

# Interview Answer

EKS is a managed Kubernetes service that uses standard Kubernetes APIs and tooling. ECS is AWS's proprietary container orchestration platform. EKS provides portability and Kubernetes compatibility, while ECS is simpler and more tightly integrated with AWS.

---

# Question 10: When Would You Choose EKS?

Choose EKS when:

* Organization already uses Kubernetes
* Multi-cloud strategy exists
* Kubernetes ecosystem tools are required
* Helm is used
* Portability is important

---

# Question 11: When Would You Choose ECS?

Choose ECS when:

* AWS-only environment
* Simplicity is preferred
* Team has no Kubernetes experience
* Fast deployment is required

---

# Most Common Interview Scenario

### Scenario

Management asks:

"We already run Kubernetes on EC2. Why should we move to EKS?"

### Answer

EKS reduces operational overhead by allowing AWS to manage the Kubernetes Control Plane. This improves reliability, simplifies upgrades, provides built-in high availability, and allows engineers to focus on applications instead of cluster maintenance.

---

# Quick Revision

EKS:

```text id="fj5kzx"
Managed Kubernetes
```

ECS:

```text id="sv3szx"
AWS Container Service
```

AWS Manages:

```text id="7s1cdw"
Control Plane
```

You Manage:

```text id="jlwmnd"
Worker Nodes
Pods
Applications
```

Node Group:

```text id="v2vowm"
Collection of Worker Nodes
```
