# Resource Requests & Limits

**Session:** 8:00 - 9:45 AM | Hands-On
**Goal:** Understand and configure CPU/memory requests and limits

---

## What are Resource Requests?

A **Request** is what a container is **guaranteed to get**, and what the
**scheduler uses to decide which node to place the Pod on.**

When you set `resources.requests`, you're telling Kubernetes: *"this container
needs at least this much CPU/memory to run properly — don't schedule it on a
node that can't provide this."*

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
```

If no node has enough **unreserved** capacity to satisfy the request, the Pod
stays `Pending` — this is exactly the `FailedScheduling` scenario from
Tuesday's troubleshooting session.

---

## What are Resource Limits?

A **Limit** is the **maximum** a container is allowed to use, enforced at
runtime by the kubelet/container runtime.

```yaml
resources:
  limits:
    cpu: "500m"
    memory: "512Mi"
```

- **CPU limit exceeded** → the container is **throttled** (slowed down), not killed
- **Memory limit exceeded** → the container is **killed** (`OOMKilled`, exit code 137)

This asymmetry is important and commonly asked about: CPU is a *compressible*
resource (you can just get less of it, temporarily), memory is *not*
(you can't partially deny memory — the process either has it or it crashes).

---

## Why Both Are Important

| Without requests | Without limits |
|---|---|
| Scheduler has no idea how much a Pod actually needs — can overpack a node | A single Pod can consume all of a node's CPU/memory, starving every other Pod on it ("noisy neighbor") |
| Pods can be scheduled onto nodes that don't have enough real capacity, causing performance issues under load | No protection against memory leaks — a leaking app slowly kills the whole node instead of just itself |

**Together, they create a predictable, fair-sharing cluster:** requests ensure
proper scheduling/guaranteed capacity, limits prevent any one Pod from taking
down its neighbors.

---

## CPU Units (millicores)

CPU is measured in **cores**, and Kubernetes lets you specify fractional cores
using **millicores** (`m`):

| Value | Meaning |
|---|---|
| `1000m` | 1 full CPU core |
| `500m` | Half a CPU core |
| `100m` | 0.1 CPU core (10%) |
| `1` | Same as `1000m` — 1 full core |

**Typical values:**
- Small API service: `requests: 100m`, `limits: 500m`
- Heavier compute workload: `requests: 500m`, `limits: 2000m` (2 cores)

---

## Memory Units (Mi / Gi)

Memory is measured in bytes, but almost always expressed with binary suffixes:

| Unit | Meaning | Example |
|---|---|---|
| `Mi` | Mebibyte (2^20 bytes ≈ 1.048M) | `128Mi`, `512Mi` |
| `Gi` | Gibibyte (2^30 bytes ≈ 1.074B) | `1Gi`, `2Gi` |
| `M` / `G` | Decimal megabyte/gigabyte (less common, slightly smaller than Mi/Gi) | `128M`, `1G` |

**Always prefer `Mi`/`Gi`** (binary) over `M`/`G` (decimal) — it's the Kubernetes
convention and avoids ambiguity.

---

## Practice: Adding Requests & Limits to deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-deployment
  labels:
    app: nodejs-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nodejs-app
  template:
    metadata:
      labels:
        app: nodejs-app
    spec:
      containers:
        - name: nodejs-container
          image: varshinips/node-app:v2
          ports:
            - containerPort: 3000

          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"

          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 15

          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
```

### Apply and Verify

```bash
# Apply the updated deployment
kubectl apply -f deployment.yaml

# Watch Pods come up
kubectl get pods

# Check resources were actually applied
kubectl describe pod <pod-name>
```

**What to look for in `describe pod` output:**

```
Limits:
  cpu:     500m
  memory:  512Mi
Requests:
  cpu:        100m
  memory:     128Mi
```

**Check node-level allocation** (confirms the scheduler accounted for your request):

```bash
kubectl describe node <node-name>
```
Look for the **Allocated resources** section near the bottom — your Pod's
request should be counted against that node's total capacity.

**Check live usage against your configured limits** (requires Metrics Server):

```bash
kubectl top pods
```
This shows *actual* CPU/memory usage right now — compare it against your
`requests`/`limits` to see how much headroom exists.

---

## QoS Classes (What Requests/Limits Determine)

Kubernetes assigns each Pod a **Quality of Service class** based on how
requests/limits are set — this affects eviction priority under node pressure:

| QoS Class | Condition | Eviction priority |
|---|---|---|
| **Guaranteed** | `requests == limits` for every container | Evicted last |
| **Burstable** | `requests` set, but `< limits` (like our example above) | Evicted after BestEffort |
| **BestEffort** | No requests or limits set at all | Evicted first |

Our example (`requests: 100m/128Mi`, `limits: 500m/512Mi`) is **Burstable** —
the most common real-world setup, since it allows some headroom for traffic
spikes while still giving the scheduler a guaranteed baseline.

---

## Key Concepts to Remember

- **Requests** = what the scheduler guarantees and uses for placement decisions
- **Limits** = the hard ceiling enforced at runtime
- **CPU limit exceeded → throttled.** **Memory limit exceeded → OOMKilled (exit code 137).**
- Millicores (`m`): `1000m` = 1 core. Memory: prefer `Mi`/`Gi` (binary) over `M`/`G` (decimal)
- No requests/limits set = **BestEffort** QoS = first to be evicted under node pressure
- `kubectl describe pod` shows configured values; `kubectl top pods` shows actual live usage — compare both to right-size your settings