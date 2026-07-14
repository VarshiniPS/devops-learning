# Kubernetes Health Checks

**Session:** 8:00 - 9:45 AM | Hands-On
**Goal:** Understand and implement Liveness, Readiness, and Startup probes

---

## What is a Liveness Probe?

A **Liveness Probe** answers the question: *"Is this container still alive, or is
it stuck/deadlocked?"*

If the liveness probe fails, Kubernetes assumes the container is broken beyond
recovery and **kills and restarts it**. This is how Kubernetes self-heals a Pod
that's technically still running as a process, but is unresponsive — for example,
an app stuck in an infinite loop or deadlocked on a resource, where the process
hasn't crashed but also isn't doing anything useful.

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 15
```

- `initialDelaySeconds` — wait this long after container start before the first check
- `periodSeconds` — how often to repeat the check
- If the check fails enough times (`failureThreshold`, default 3), the container is restarted

---

## What is a Readiness Probe?

A **Readiness Probe** answers a different question: *"Is this container ready to
receive traffic right now?"*

If the readiness probe fails, Kubernetes does **not** restart the container —
instead, it just **removes the Pod from the Service's endpoints**, so no traffic
gets routed to it until it passes again. This is for temporary states: the app is
warming up, reconnecting to a database, or briefly overloaded — situations where
killing the container would be the wrong response.

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 10
```

---

## Why Both Are Needed

They solve **different problems**, and using only one leaves a gap:

| | Liveness | Readiness |
|---|---|---|
| **Question asked** | Is it alive? | Is it ready for traffic? |
| **On failure** | Kubernetes **restarts** the container | Kubernetes **removes Pod from Service endpoints** (no restart) |
| **Use case** | Deadlocks, stuck processes | Slow startup, temporary unavailability (DB reconnect, cache warmup) |

**Without a liveness probe:** a deadlocked container just sits there forever,
still "Running" from Kubernetes' point of view, silently serving nothing or
erroring on every request — nobody restarts it for you.

**Without a readiness probe:** a Pod that's still starting up (e.g. loading a
large config, connecting to a database) gets traffic sent to it immediately once
the container process starts, even though the app inside isn't ready — causing
failed requests during every rollout or restart.

**Together:** readiness protects users from hitting a not-yet-ready Pod;
liveness protects the system from a Pod that's stuck and needs a hard reset.

---

## Startup Probe (Overview)

A **Startup Probe** exists for one specific problem: **slow-starting
applications that would get killed by the liveness probe before they even
finish booting.**

```yaml
startupProbe:
  httpGet:
    path: /health
    port: 3000
  failureThreshold: 30
  periodSeconds: 10
```

- While the startup probe is running, **liveness and readiness probes are
  disabled** — Kubernetes won't prematurely restart a container that's just
  slow to boot (e.g. an app doing heavy migrations or cache preloading on start)
- Once the startup probe succeeds once, liveness and readiness take over as normal
- `failureThreshold * periodSeconds` = max time allowed to start (30 × 10s = 300s / 5 min here)

**When to use it:** only if your app genuinely has a slow, variable startup time.
Most simple apps (like a basic Express server) don't need one — liveness and
readiness alone are sufficient.

---

## Practice: Adding Probes to deployment.yaml

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

### Apply and Observe

```bash
# Apply the updated deployment
kubectl apply -f deployment.yaml

# Watch Pods come up
kubectl get pods -w

# Check probe status in detail
kubectl describe pod <pod-name>
```

**What to look for in `describe pod` output:**

```
Liveness:   http-get http://:3000/health delay=10s timeout=1s period=15s #success=1 #failure=3
Readiness:  http-get http://:3000/ready delay=5s timeout=1s period=10s #success=1 #failure=3
```

And in the **Events** section, if a probe fails:
```
Warning  Unhealthy  kubelet  Readiness probe failed: HTTP probe failed with statuscode: 500
```

If everything is healthy, `kubectl get pods` shows `READY: 1/1` — this specifically
reflects the **readiness** probe passing, not just the container running.

---

## Quick Reference

| Probe | Fails → | Fixes | Typical use |
|---|---|---|---|
| **Liveness** | Container restarted | Deadlocks, stuck processes | Long-running apps that can hang |
| **Readiness** | Pod removed from Service endpoints | Temporary unavailability | Startup warmup, DB reconnects, overload |
| **Startup** | Restarts delayed until it succeeds | N/A — protects the other two from firing too early | Apps with slow/variable boot time |

---

## Key Concepts to Remember

- **`READY: 1/1` in `kubectl get pods`** reflects the readiness probe, not just "container is running"
- **Liveness failure = restart.** Readiness failure = **no traffic**, no restart.
- Startup probe **suspends** liveness/readiness until the app finishes booting — prevents premature restarts on slow-starting containers
- Always check `kubectl describe pod` Events for the exact probe failure reason (wrong path, wrong port, non-200 response, timeout)
- A Pod can be `Running` and still receive zero traffic — that's the readiness probe doing its job correctly, not a bug
