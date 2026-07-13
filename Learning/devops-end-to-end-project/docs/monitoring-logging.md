# Monitoring & Logging

## Why Monitoring Is Important

Without monitoring, the first person to notice an outage is a user — not you.
Monitoring turns silent failures into alerts, and turns "the app is down"
from a surprise into something you catch before it becomes an incident.

Three separate questions monitoring answers:
1. **Is it healthy right now?** — health checks, continuous
2. **How much load is it under?** — metrics, aggregated over time
3. **What exactly went wrong?** — logs, the specific detail

---

## Metrics vs Logs

| | Metrics | Logs |
|---|---|---|
| Answers | How much? How fast? | What exactly happened? |
| Format | Numbers over time | Text, structured or unstructured |
| Cost to store | Cheap (aggregated) | Expensive at scale (raw text) |
| Good for | Dashboards, alerting thresholds | Root-causing a specific failure |
| Example | CPU 85%, 200 req/s, p99 latency 400ms | `TypeError: Cannot read property 'id' of undefined at line 42` |
| Tooling | Prometheus, CloudWatch, Metrics Server | ELK stack, CloudWatch Logs, `kubectl logs` |

**The workflow in practice:** an alert fires because a metric crossed a
threshold (error rate > 5%). That tells you *something* is wrong but not
*what*. You then go to logs from the same time window to find the actual
error and root cause. Metrics tell you *when* to look; logs tell you
*what* to look at.

---

## Kubernetes Events

Events are different from both metrics and logs — they're the control
plane's own record of what it did to a resource. Not application output;
infrastructure narration.

```bash
kubectl get events
```

```
LAST SEEN   TYPE      REASON              OBJECT                          MESSAGE
2m          Normal    Scheduled           pod/nodejs-deployment-xxx       Successfully assigned...
2m          Normal    Pulled              pod/nodejs-deployment-xxx       Container image pulled
2m          Normal    Started             pod/nodejs-deployment-xxx       Started container
1m          Warning   Unhealthy           pod/nodejs-deployment-yyy       Readiness probe failed
1m          Warning   BackOff             pod/nodejs-deployment-yyy       Back-off restarting container
```

Events are the first place to check for **infrastructure-level** problems —
`FailedScheduling`, `ImagePullBackOff`, `Unhealthy` — because these happen
*before* or *around* the container, not inside it. A Pod that never starts
never gets the chance to write an application log — Events are the only
record of what went wrong.

Events also expire (default ~1 hour in most clusters) — check them
immediately during an incident, don't come back to them later.

---

## Health Checks

Continuous, automated monitoring — Kubernetes itself polls your app on a
timer and acts on the result without a human in the loop.

| Probe | Question it asks | Action on failure |
|---|---|---|
| `livenessProbe` | Is the process still working? | Restart the container |
| `readinessProbe` | Can it handle traffic right now? | Remove from Service endpoints |
| `startupProbe` | Has it finished starting up? | Delays liveness checks until true |

Our `deployment.yaml` wires these to `app.js`'s `/health` and `/ready`
routes — see `docs/setup.md` for the full endpoint reference.

---

## Hands-On: Commands

### kubectl logs — see what a Pod's container printed

```bash
kubectl logs <pod-name>
```

```
Server running on port 3000
Environment: production
Version:     1.0.0
```

If a Pod has crashed and restarted, `kubectl logs` shows the **current**
container's logs by default — to see what the previous (crashed) attempt
printed before it died:

```bash
kubectl logs <pod-name> --previous
```

### kubectl logs -f — follow logs live

```bash
kubectl logs -f <pod-name>
```

Streams new log lines as they're written — useful while reproducing an
issue or watching a rollout happen in real time. `Ctrl+C` to stop following.

```bash
# Follow logs from any Pod in the Deployment, not a specific Pod name
kubectl logs -f deploy/nodejs-deployment
```

### kubectl describe pod — full picture: config, state, and events

```bash
kubectl describe pod <pod-name>
```

The most valuable section is at the bottom:

```
Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Normal   Scheduled  2m    default-scheduler   Successfully assigned...
  Normal   Pulled     2m    kubelet             Container image pulled
  Normal   Started    2m    kubelet             Started container
```

This is where you see readiness/liveness probe failures, image pull errors,
resource limit issues — all in one place, in chronological order.

### kubectl get events — cluster-wide event stream

```bash
kubectl get events
```

```bash
# Sort by time, most recent last (easier to read during an incident)
kubectl get events --sort-by=.metadata.creationTimestamp

# Watch events live
kubectl get events -w

# Filter to a specific Pod
kubectl get events --field-selector involvedObject.name=<pod-name>
```

### kubectl top pods — live resource usage (requires Metrics Server)

```bash
kubectl top pods
```

```
NAME                                  CPU(cores)   MEMORY(bytes)
nodejs-deployment-xxxxx-aaaaa         12m          45Mi
nodejs-deployment-xxxxx-bbbbb         10m          43Mi
nodejs-deployment-xxxxx-ccccc         11m          44Mi
```

If this returns an error like `error: Metrics API not available`, the
Metrics Server isn't installed:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# On Docker Desktop / minikube, may also need to allow insecure TLS:
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

Once installed, `kubectl top pods` and `kubectl top nodes` become available
cluster-wide.

---

## Debugging Workflow: Which Command First?

```
Pod not behaving right
  │
  ├─ Is the Pod even running?        → kubectl get pods
  ├─ What did the control plane do?  → kubectl describe pod (Events section)
  ├─ What did the app itself log?    → kubectl logs <pod>
  ├─ Is it resource-starved?         → kubectl top pods
  └─ What happened cluster-wide?     → kubectl get events --sort-by=.metadata.creationTimestamp
```

Start with `describe pod` before `logs` — Events often reveal the problem
never reached the application layer at all (crash before logging, failed
scheduling, image pull failure), which saves you from hunting through empty
or misleading application logs.

---

## Key Takeaways

1. Metrics tell you **when** to look (thresholds, alerts). Logs tell you
   **what** to look at (specific errors). Both are necessary, neither
   replaces the other.
2. Events are the control plane's own narration — check them first for
   anything that looks infrastructure-related, since a Pod that never starts
   never gets to write an application log.
3. `kubectl describe pod` before `kubectl logs` — the Events section at the
   bottom often reveals the real problem faster than reading through app logs.
4. `kubectl logs --previous` is essential for crashed containers — default
   `logs` only shows the current (post-restart) container's output.
5. `kubectl top pods` requires Metrics Server — it's not built into
   Kubernetes by default and needs a one-time install.
6. Health checks are monitoring running continuously and automatically —
   they're what makes self-healing possible without a human watching a
   dashboard 24/7.