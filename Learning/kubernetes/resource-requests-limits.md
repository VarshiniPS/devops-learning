# Kubernetes Resource Requests and Limits

## Why Do We Need Requests and Limits?

Kubernetes runs multiple Pods on worker nodes.

If resource usage is not controlled, a single Pod can consume excessive CPU or memory and impact other applications running on the same node.

Resource Requests and Limits help ensure fair resource allocation and improve cluster stability.

---

## Resource Requests

A Request defines the minimum amount of CPU and memory that Kubernetes guarantees to a container.

The Kubernetes Scheduler uses Requests to determine where a Pod can be scheduled.

### Example

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "256Mi"
```

Meaning:

```text
CPU    : 0.25 CPU Core
Memory : 256 MiB
```

The Scheduler will place the Pod only on a node that has at least these resources available.

---

## Resource Limits

A Limit defines the maximum amount of CPU and memory a container can consume.

The container cannot exceed the configured limit.

### Example

```yaml
resources:
  limits:
    cpu: "500m"
    memory: "512Mi"
```

Meaning:

```text
CPU    : Maximum 0.5 CPU Core
Memory : Maximum 512 MiB
```

---

## Requests vs Limits

| Requests                            | Limits                                  |
| ----------------------------------- | --------------------------------------- |
| Minimum guaranteed resources        | Maximum allowed resources               |
| Used by Scheduler for Pod placement | Enforced during runtime                 |
| Helps reserve resources             | Prevents excessive resource consumption |

### Simple Analogy

```text
Request = Reserved Seat
Limit = Maximum Capacity
```

Example:

```text
Request CPU = 250m
Limit CPU = 500m
```

The Pod is guaranteed 250m CPU but can use up to 500m CPU.

---

## CPU Limit Behavior

If a container exceeds its CPU limit:

```text
CPU Limit = 500m
Usage = 800m
```

Kubernetes throttles the CPU usage.

The container continues running but cannot consume more than the configured limit.

---

## Memory Limit Behavior

If a container exceeds its memory limit:

```text
Memory Limit = 512Mi
Usage = 700Mi
```

The container may be terminated by Kubernetes.

Common status:

```text
OOMKilled
```

OOM = Out Of Memory

---

## Complete Example

```yaml
apiVersion: v1
kind: Pod

metadata:
  name: nginx-pod

spec:
  containers:
  - name: nginx
    image: nginx

    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"

      limits:
        cpu: "500m"
        memory: "512Mi"
```

---

## Why Requests and Limits Are Important

### Prevent Resource Starvation

Ensures one application does not consume all node resources.

### Better Scheduling

Scheduler can place Pods on suitable nodes.

### Improved Stability

Protects the node from resource exhaustion.

### Fair Resource Allocation

Multiple applications can coexist without affecting each other.

---

## Common Interview Questions

### What is a Resource Request?

A Resource Request is the minimum amount of CPU and memory guaranteed to a container.

---

### What is a Resource Limit?

A Resource Limit is the maximum amount of CPU and memory a container can consume.

---

### Why are Requests important?

The Kubernetes Scheduler uses Requests to decide Pod placement.

---

### What happens when a CPU limit is exceeded?

CPU usage is throttled, but the container usually continues running.

---

### What happens when a Memory limit is exceeded?

The container may be terminated and enter an OOMKilled state.

---

### Difference between Requests and Limits?

```text
Request = Guaranteed Resource

Limit = Maximum Allowed Resource
```

---

## Key Takeaways

* Requests reserve resources for a Pod.
* Limits restrict how much a Pod can consume.
* Scheduler uses Requests during scheduling.
* CPU overuse leads to throttling.
* Memory overuse can result in OOMKilled.
* Requests and Limits improve cluster reliability and stability.
