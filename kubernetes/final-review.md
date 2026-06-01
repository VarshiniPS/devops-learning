# Kubernetes Final Review ☸️

## Biggest Learnings

### 1. Kubernetes Maintains Desired State

Kubernetes continuously ensures the desired number of Pods are running using Deployments and ReplicaSets.

### 2. Self-Healing

If a Pod crashes or is deleted, Kubernetes automatically recreates it.

### 3. Rolling Updates

Applications can be updated gradually without downtime using rolling updates.

### 4. Services

Services expose applications and route traffic to healthy Pods instead of users directly accessing Pods.

### 5. Declarative Approach

YAML files define infrastructure and application state declaratively.

### 6. Debugging

kubectl logs, describe, and exec are critical troubleshooting tools.

---

## Most Confusing Concepts Initially

* Difference between Deployment, ReplicaSet, and Pod
* YAML indentation and structure
* Service networking and NodePort behavior
* Namespaces and resource isolation

---

## Current Understanding

### Kubernetes

* Understand Pods, Deployments, ReplicaSets, Services, Namespaces, ConfigMaps, Rolling Updates, and Self-Healing.
* Comfortable with basic kubectl commands and YAML files.

### Debugging

* Can inspect Pods using logs and describe.
* Can enter containers using kubectl exec.

### Architecture

* Understand complete flow:
  Developer → GitHub → Jenkins → Docker → Kubernetes → Users

---

## Confidence Rating

| Topic                      | Confidence |
| -------------------------- | ---------- |
| Kubernetes Basics          | 8/10       |
| Deployments & Services     | 8/10       |
| YAML                       | 7/10       |
| Debugging                  | 7/10       |
| Architecture Understanding | 8/10       |
| kubectl Commands           | 8/10       |

---

## Biggest Realization

Docker runs containers.

Kubernetes manages containers at scale automatically using orchestration, scaling, self-healing, and networking.
