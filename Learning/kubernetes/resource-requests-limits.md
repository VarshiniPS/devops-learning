# Kubernetes Resource Requests and Limits

## Why Do We Need Requests and Limits?

Requests and Limits prevent a single Pod from consuming excessive CPU or memory and affecting other Pods on the node.

Benefits:

* Prevent noisy neighbor problems
* Prevent resource starvation
* Improve scheduling decisions
* Protect node stability

---

# Resource Request

A Request is the minimum guaranteed CPU or memory a container receives.

Example:

```yaml
requests:
  cpu: "250m"
  memory: "256Mi"
```

Meaning:

* Kubernetes Scheduler uses Requests for scheduling.
* The container is guaranteed these resources.

---

# Resource Limit

A Limit is the maximum CPU or memory a container can consume.

Example:

```yaml
limits:
  cpu: "500m"
  memory: "512Mi"
```

Meaning:

* Container can use resources up to this value.
* Kubernetes enforces the limit.

---

# Requests vs Limits

| Request                      | Limit                             |
| ---------------------------- | --------------------------------- |
| Minimum guaranteed resources | Maximum allowed resources         |
| Used by Scheduler            | Used by Kubernetes enforcement    |
| Determines Pod placement     | Prevents resource overconsumption |

---

# Example

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "256Mi"

  limits:
    cpu: "500m"
    memory: "512Mi"
```

Meaning:

* Guaranteed CPU = 250m

* Maximum CPU = 500m

* Guaranteed Memory = 256Mi

* Maximum Memory = 512Mi

---

# CPU Limit Exceeded

Example:

```text
CPU Request = 250m
CPU Limit = 500m

Application Uses = 800m
```

Result:

```text
CPU Throttling
```

The Pod continues running.

The container is not killed.

---

# Memory Limit Exceeded

Example:

```text
Memory Request = 256Mi
Memory Limit = 512Mi

Application Uses = 700Mi
```

Result:

```text
OOMKilled
```

The container may be terminated.

---

# Why Scheduler Uses Requests Instead of Limits

Example:

```text
Node Capacity = 4 CPU

Pod:
Request = 2 CPU
Limit = 8 CPU
```

Scheduler uses Requests because they represent guaranteed resources.

If Scheduler used Limits, many Pods would never be scheduled even though the resources may never actually be consumed.

---

# Interview Questions

## What is a Resource Request?

A Resource Request is the minimum guaranteed CPU or memory assigned to a container and used by the Scheduler for Pod placement.

---

## What is a Resource Limit?

A Resource Limit is the maximum CPU or memory a container is allowed to consume.

---

## What happens when CPU Limit is exceeded?

Kubernetes throttles CPU usage.

The Pod continues running.

---

## What happens when Memory Limit is exceeded?

The container may be terminated with OOMKilled.

---

## Why does Kubernetes Scheduler use Requests?

Because Requests represent guaranteed resources required by the Pod.

---

## Difference Between Requests and Limits?

Request = Scheduling

Limit = Enforcement

---

# Quick Revision

```text
Request
↓
Guaranteed Resources

Limit
↓
Maximum Allowed Resources

CPU Limit Exceeded
↓
Throttled

Memory Limit Exceeded
↓
OOMKilled

Scheduler
↓
Uses Requests

Kubernetes
↓
Enforces Limits
```
