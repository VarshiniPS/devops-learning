# Kubernetes Persistent Volumes (PV) and Persistent Volume Claims (PVC)

## Why Do We Need Persistent Storage?

Pods are temporary resources in Kubernetes.

If a Pod is deleted, restarted, or recreated, any data stored inside the Pod's filesystem is lost.

Persistent storage ensures data survives Pod restarts and replacements.

---

## Persistent Volume (PV)

A Persistent Volume (PV) is a storage resource in Kubernetes that exists independently of Pods.

Characteristics:

* Persistent storage
* Independent of Pod lifecycle
* Can be reused by applications
* Managed by Kubernetes

Example:

```text
Pod
 ↓
PV
 ↓
Disk Storage
```

Even if the Pod is deleted, the PV continues to exist.

---

## Persistent Volume Claim (PVC)

A Persistent Volume Claim (PVC) is a request for storage made by an application.

Instead of directly using a PV, Pods consume storage through PVCs.

Characteristics:

* Requests storage
* Specifies required size
* Binds to a matching PV
* Used by Pods

Example:

```text
PVC Request
 ↓
PV
 ↓
Storage
```

---

## PV-PVC Binding Process

Kubernetes automatically binds a PVC to a suitable PV.

Example:

PVC requests:

* 10 GB storage

Available PV:

* 20 GB storage

Kubernetes binds the PVC to the PV.

Flow:

```text
Pod
 ↓
PVC
 ↓
PV
 ↓
Disk Storage
```

---

## Data Persistence Example

Initial State:

```text
Pod A
 ↓
PVC
 ↓
PV
 ↓
customer-data.txt
```

Pod A crashes:

```text
Pod A ❌
```

Kubernetes creates:

```text
Pod B
 ↓
PVC
 ↓
Same PV
 ↓
customer-data.txt ✅
```

The file remains available because the PV exists independently of the Pod lifecycle.

---

## PV vs PVC

| PV                        | PVC                         |
| ------------------------- | --------------------------- |
| Actual storage resource   | Request for storage         |
| Created by admin/platform | Created by user/application |
| Provides storage          | Consumes storage            |
| Independent resource      | Binds to a PV               |

---

## Real-World Analogy

PV = Bank Locker

PVC = Locker Request Form

Pod = Customer Using the Locker

Flow:

```text
Customer (Pod)
 ↓
Request Form (PVC)
 ↓
Locker (PV)
```

---

## Why Don't Pods Directly Use PVs?

Pods request storage through PVCs.

PVCs abstract storage provisioning from storage consumption.

Applications do not need to know:

* Which storage backend is used
* Which disk is allocated
* How storage is provisioned

Pods simply request storage through PVCs.

---

## Access Modes

### ReadWriteOnce (RWO)

Storage can be mounted as read-write by one node.

---

### ReadOnlyMany (ROX)

Multiple Pods can read the storage.

---

### ReadWriteMany (RWX)

Multiple Pods can read and write to the same storage.

---

## Interview Questions

### What problem do Persistent Volumes solve?

Persistent Volumes provide storage that survives Pod deletion and recreation.

---

### What is a Persistent Volume?

A Persistent Volume is a Kubernetes storage resource that exists independently of the Pod lifecycle.

---

### What is a Persistent Volume Claim?

A Persistent Volume Claim is a request for storage made by an application.

---

### Explain the PV-PVC flow.

```text
Pod
 ↓
PVC
 ↓
PV
 ↓
Disk Storage
```

---

### What is the difference between PV and PVC?

PV is the actual storage resource.

PVC is the request for storage.

---

### Why do Pods use PVC instead of directly using PV?

PVC separates storage consumption from storage provisioning and allows Kubernetes to automatically bind suitable storage resources.

---

## Key Learning

Pods are temporary.

Persistent Volumes provide long-term storage.

Persistent Volume Claims request and consume Persistent Volumes.

Data stored in PVs survives Pod restarts and Pod replacements.
