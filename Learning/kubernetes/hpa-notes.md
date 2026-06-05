# Kubernetes Horizontal Pod Autoscaler (HPA)

# What is HPA?

HPA (Horizontal Pod Autoscaler) automatically increases or decreases the number of Pod replicas based on resource utilization metrics such as CPU or Memory.

Goal:

* Handle increasing traffic automatically
* Reduce resource waste during low traffic
* Improve application availability

---

# Why Do We Need HPA?

Without HPA:

```text
Traffic Increases
      ↓
CPU Usage Increases
      ↓
Application Slows Down
      ↓
Users Experience Delays
```

With HPA:

```text
Traffic Increases
      ↓
CPU Usage Increases
      ↓
HPA Detects High Usage
      ↓
Creates More Pods
      ↓
Traffic Distributed
```

---

# Horizontal vs Vertical Scaling

## Horizontal Scaling

Adds more Pods.

```text
2 Pods
  ↓
5 Pods
```

Handled by HPA.

---

## Vertical Scaling

Adds more CPU or Memory to existing Pods.

```text
1 CPU
  ↓
4 CPU
```

Handled by Vertical Pod Autoscaler (VPA).

---

# How HPA Works

```text
Users
   ↓
Application Traffic
   ↓
Pods
   ↓
CPU Usage Increases
   ↓
Metrics Server
   ↓
HPA
   ↓
Scale Deployment
```

---

# HPA Components

## Deployment

HPA scales Deployments, StatefulSets, or ReplicaSets.

Example:

```yaml
replicas: 2
```

---

## Metrics Server

Provides CPU and Memory metrics.

Required for HPA.

Verify:

```bash
kubectl top pod
kubectl top node
```

If these commands work, Metrics Server is running.

---

## HPA Controller

Continuously checks utilization metrics and adjusts replica count.

---

# CPU-Based Scaling Example

Deployment:

```text
Replicas = 2
```

HPA:

```yaml
targetCPUUtilizationPercentage: 70
```

Current CPU:

```text
85%
```

Result:

```text
Scale Up
2 Pods → 3 Pods → 4 Pods
```

---

# Scale Down Example

Current CPU:

```text
20%
```

Target CPU:

```text
70%
```

Result:

```text
Scale Down
5 Pods → 4 Pods → 3 Pods
```

---

# HPA YAML Example

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

---

# Important Fields

## scaleTargetRef

Target workload.

Example:

```yaml
scaleTargetRef:
  kind: Deployment
  name: nginx-deployment
```

---

## minReplicas

Minimum number of Pods.

Example:

```yaml
minReplicas: 2
```

Even if traffic becomes zero:

```text
Pods Never Go Below 2
```

---

## maxReplicas

Maximum number of Pods.

Example:

```yaml
maxReplicas: 10
```

Even during heavy traffic:

```text
Pods Never Exceed 10
```

---

# Replication Boundaries

HPA always respects:

```text
minReplicas
     ↓
Current Replicas
     ↓
maxReplicas
```

Example:

```text
minReplicas = 2
maxReplicas = 10
```

Possible:

```text
2
3
4
5
...
10
```

Not possible:

```text
1
11
12
```

---

# Scaling Behavior

## Scale Up

Triggered when utilization exceeds target.

Example:

```text
Target CPU = 70%
Actual CPU = 90%
```

Result:

```text
Add More Pods
```

---

## Scale Down

Triggered when utilization remains below target.

Example:

```text
Target CPU = 70%
Actual CPU = 20%
```

Result:

```text
Remove Excess Pods
```

---

# HPA vs ReplicaSet

ReplicaSet:

```text
Maintains Fixed Number Of Pods
```

Example:

```yaml
replicas: 3
```

Always:

```text
3 Pods
```

---

HPA:

```text
Maintains Dynamic Number Of Pods
```

Example:

```text
2 Pods
↓
6 Pods
↓
3 Pods
```

Depending on load.

---

# Real World Example

E-commerce website:

Normal Traffic:

```text
CPU = 30%
Replicas = 2
```

Sale Starts:

```text
CPU = 90%
```

HPA:

```text
2 Pods
↓
4 Pods
↓
8 Pods
```

Traffic handled automatically.

---

# Interview Questions

## What is HPA?

Horizontal Pod Autoscaler automatically scales Pods up or down based on metrics such as CPU or Memory utilization.

---

## What is Horizontal Scaling?

Adding more Pod replicas.

---

## What Metrics Does HPA Use?

Commonly:

* CPU
* Memory
* Custom Metrics

---

## What is Metrics Server?

Metrics Server collects resource utilization metrics used by HPA.

---

## What Happens When CPU Usage Exceeds Target?

HPA creates additional Pod replicas.

---

## What Happens When CPU Usage Drops?

HPA removes excess replicas while respecting minReplicas.

---

## Difference Between HPA and ReplicaSet?

ReplicaSet maintains a fixed number of Pods.

HPA dynamically adjusts the number of Pods.

---

## Difference Between HPA and VPA?

HPA:

```text
More Pods
```

VPA:

```text
More CPU/Memory
```

---

# Quick Revision

```text
HPA
↓
Horizontal Pod Autoscaler

CPU High
↓
Scale Up

CPU Low
↓
Scale Down

Metrics Server
↓
Provides Metrics

minReplicas
↓
Lower Boundary

maxReplicas
↓
Upper Boundary

HPA
↓
More Pods

VPA
↓
More CPU/Memory
```
