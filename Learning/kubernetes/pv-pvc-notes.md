# Kubernetes Persistent Volumes (PV) & Persistent Volume Claims (PVC)

## Why Do We Need Persistent Storage?

Pods are temporary.

If a Pod is deleted or recreated, any data stored inside the Pod is lost.

Persistent storage ensures data survives Pod restarts and replacements.

---

## Persistent Volume (PV)

A Persistent Volume (PV) is a storage resource in Kubernetes that exists independently of Pods.

Characteristics:

- Persistent storage
- Survives Pod deletion
- Can be reused
- Managed by Kubernetes

Example:

Pod
↓
Persistent Volume
↓
Disk Storage

---

## Persistent Volume Claim (PVC)

A Persistent Volume Claim (PVC) is a request for storage made by an application.

Instead of directly using a PV, Pods use PVCs.

Characteristics:

- Requests storage
- Specifies storage size
- Binds to an available PV

Example:

PVC Request
↓
PV
↓
Storage

---

## Relationship Between PV and PVC

Flow:

Pod
↓
PVC
↓
PV
↓
Disk

The Pod uses the PVC, and the PVC is connected to a PV.

---

## PV vs PVC

| Persistent Volume (PV) | Persistent Volume Claim (PVC) |
|------------------------|-------------------------------|
| Actual storage resource | Request for storage |
| Created by admin | Created by user/application |
| Provides storage | Consumes storage |
| Exists independently | Binds to a PV |

---

## Real-World Analogy

PV = Storage Locker

PVC = Request Form For Locker

Pod = Person Using Locker

---

## Key Learning

Pods are temporary.

Persistent Volumes provide long-term storage.

Persistent Volume Claims request and consume Persistent Volumes.

Data stored in PVs survives Pod restarts and replacements.