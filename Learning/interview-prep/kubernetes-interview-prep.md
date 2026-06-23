# Kubernetes Interview Notes

## 1. Pod vs Deployment

### Pod

* Smallest deployable unit in Kubernetes
* Contains one or more containers
* Containers share network and storage

### Deployment

* Manages Pods
* Provides:

  * Self-healing
  * Scaling
  * Rolling updates
  * Replica management

### Difference

| Pod                                    | Deployment       |
| -------------------------------------- | ---------------- |
| Runs containers                        | Manages Pods     |
| No self-healing                        | Self-healing     |
| No scaling                             | Supports scaling |
| Not recommended directly in production | Production-ready |

---

## 2. StatefulSet

Used for stateful applications requiring:

* Stable Pod names
* Persistent storage
* Ordered deployment
* Ordered termination

Examples:

* MySQL
* PostgreSQL
* MongoDB

Example Pod Names:

```text
mysql-0
mysql-1
mysql-2
```

### Deployment vs StatefulSet

Deployment:

* Stateless applications
* Pod names change

StatefulSet:

* Stateful applications
* Stable identities

---

## 3. Service Types

### ClusterIP

* Default service type
* Internal cluster communication only

### NodePort

* Exposes application externally
* Access using:

```text
<NodeIP>:<NodePort>
```

### LoadBalancer

* Creates cloud load balancer
* Used in production

### Quick Summary

```text

ClusterIP -> Internal
NodePort -> External Testing
LoadBalancer -> Production
```

---

## 4. Ingress

Provides HTTP/HTTPS routing into the cluster.

Flow:

User
↓
Ingress
↓
Service
↓
Pods

Features:

* Host-based routing
* Path-based routing
* SSL termination
* Single entry point

Example:

```text
/app1 -> Service A
/app2 -> Service B
```

---

## 5. ConfigMaps

Stores non-sensitive configuration data.

Examples:

* URLs
* Application configuration
* Feature flags
* Environment variables

Benefits:

* Separate config from application code
* Easier updates

---

## 6. Secrets

Stores sensitive information.

Examples:

* Passwords
* API Keys
* Tokens
* Certificates

### ConfigMap vs Secret

ConfigMap:

* Non-sensitive

Secret:

* Sensitive

---

## 7. Horizontal Pod Autoscaler (HPA)

Automatically scales Pods based on:

* CPU utilization
* Memory utilization

Flow:

Metrics Server
↓
CPU/Memory Metrics
↓
HPA
↓
Scale Pods

### Scaling Boundaries

```text
minReplicas
currentReplicas
maxReplicas
```

HPA always respects boundaries.

---

## 8. Persistent Volume (PV) vs Persistent Volume Claim (PVC)

### Persistent Volume (PV)

Actual storage resource.

Examples:

* AWS EBS
* Azure Disk
* NFS

### Persistent Volume Claim (PVC)

Request for storage by a Pod.

### Flow

Pod
↓
PVC
↓
PV
↓
Storage

### Easy Analogy

```text
PV  = House
PVC = Rental Agreement
Pod = Tenant
```

---

# Top Interview Questions

### What happens if a Pod crashes?

Deployment creates a replacement Pod automatically.

### Why do we need Services?

Pod IPs change. Services provide stable networking and load balancing.

### Why use Deployment instead of Pod?

Deployment provides self-healing, scaling, and rolling updates.

### Why use StatefulSet?

For databases and applications requiring stable identities and storage.

### Difference between ClusterIP and NodePort?

ClusterIP:

* Internal access

NodePort:

* External access

### Difference between ConfigMap and Secret?

ConfigMap:

* Non-sensitive configuration

Secret:

* Sensitive data

### How does HPA work?

Uses Metrics Server CPU/Memory metrics to scale Pods automatically.

### Difference between PV and PVC?

PV:

* Actual storage

PVC:

* Storage request
