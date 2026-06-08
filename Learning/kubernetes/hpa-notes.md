# Kubernetes Horizontal Pod Autoscaler (HPA)

## What is HPA?

Horizontal Pod Autoscaler (HPA) automatically increases or decreases the number of Pod replicas based on resource utilization metrics such as CPU or memory.

Purpose:

* Handle traffic spikes automatically
* Reduce resource wastage
* Improve application availability
* Scale applications dynamically

---

# How HPA Works

Flow:

```text
Application Traffic
        ↓
CPU / Memory Usage Changes
        ↓
Metrics Server
        ↓
HPA Controller
        ↓
Deployment
        ↓
Scale Up / Scale Down
```

---

# Metrics Server

Metrics Server collects:

* Pod CPU usage
* Pod Memory usage
* Node CPU usage
* Node Memory usage

HPA depends on Metrics Server.

Without Metrics Server:

```text
HPA cannot make scaling decisions
```

---

# Replication Boundaries

HPA always operates within:

```text
minReplicas
      ↓
currentReplicas
      ↓
maxReplicas
```

Example:

```yaml
minReplicas: 2
maxReplicas: 10
```

Possible replica counts:

```text
2 → 3 → 4 → 5 → ... → 10
```

Not possible:

```text
1
11
12
```

---

# Example HPA Configuration

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler

metadata:
  name: nginx-hpa

spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment

  minReplicas: 2
  maxReplicas: 10

  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

Meaning:

* Maintain CPU around 70%
* Minimum Pods = 2
* Maximum Pods = 10

---

# Apply HPA

```bash
kubectl apply -f hpa.yaml
```

---

# Verify HPA

List HPA:

```bash
kubectl get hpa
```

Example output:

```text
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS
nginx-hpa   Deployment/nginx-deployment   45%/70%   2         10        2
```

---

# Describe HPA

```bash
kubectl describe hpa nginx-hpa
```

Useful information:

* Current replicas
* Desired replicas
* CPU utilization
* Scaling events
* Min/Max replicas

---

# Useful Commands

Check HPA:

```bash
kubectl get hpa
```

Detailed HPA information:

```bash
kubectl describe hpa nginx-hpa
```

Check Deployment replicas:

```bash
kubectl get deployment
```

Check Pods:

```bash
kubectl get pods
```

Check Metrics Server metrics:

```bash
kubectl top pods
```

Check Node metrics:

```bash
kubectl top nodes
```

---

# Deployment vs HPA

Deployment only:

```yaml
replicas: 3
```

Behavior:

```text
Always 3 Pods
```

HPA:

```text
Traffic Low  → Scale Down
Traffic High → Scale Up
```

---

# Interview Questions

## What is HPA?

HPA automatically scales Pods up or down based on metrics such as CPU or memory utilization.

---

## What is the role of Metrics Server?

Metrics Server collects CPU and memory metrics used by HPA to make scaling decisions.

---

## What are minReplicas and maxReplicas?

minReplicas:

```text
Lower scaling boundary
```

maxReplicas:

```text
Upper scaling boundary
```

HPA always respects these limits.

---

## What happens if CPU reaches 95% but maxReplicas is already reached?

HPA cannot scale further because it must respect maxReplicas.

---

## Why can't Deployment replace HPA?

Deployment maintains a fixed number of Pods.

HPA dynamically adjusts Pod count based on resource utilization.

---

## Difference Between Deployment and HPA

Deployment:

```text
Fixed Replicas
```

HPA:

```text
Dynamic Replicas
```

---

# Quick Revision

Metrics Server:

```text
Provides Metrics
```

HPA:

```text
Makes Scaling Decisions
```

Deployment:

```text
Maintains Desired Replicas
```

HPA:

```text
Changes Desired Replicas
```
