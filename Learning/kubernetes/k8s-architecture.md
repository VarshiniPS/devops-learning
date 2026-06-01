# Kubernetes Architecture ☸️

## High-Level Architecture

kubectl
↓
API Server
↓
etcd
↓
Scheduler
↓
Worker Nodes
↓
kubelet
↓
Pods

---

## Control Plane

The Control Plane is the brain of Kubernetes.

It makes decisions and manages the cluster.

Components:

- API Server
- Scheduler
- etcd
- Controller Manager

---

## API Server

The entry point to Kubernetes.

All requests from kubectl and other components pass through the API Server.

Examples:

kubectl get pods

kubectl apply -f deployment.yaml

---

## Scheduler

Responsible for selecting the worker node where a Pod should run.

It considers available resources and cluster state.

---

## etcd

Distributed key-value database used by Kubernetes.

Stores:

- Deployments
- Services
- Secrets
- ConfigMaps
- Cluster state

---

## Controller Manager

Continuously compares actual state with desired state.

Example:

Desired:
3 Pods

Actual:
2 Pods

Controller creates a replacement Pod.

---

## Worker Nodes

Machines that run application workloads.

Worker nodes host Pods and containers.

---

## kubelet

Agent running on every worker node.

Receives instructions from the Control Plane and manages Pods.

---

## Complete Request Flow

kubectl apply -f deployment.yaml

↓

API Server

↓

etcd stores desired state

↓

Scheduler selects worker node

↓

kubelet receives instructions

↓

Pod created

↓

Application running

---

## Key Learning

Control Plane makes decisions.

Worker Nodes execute those decisions.