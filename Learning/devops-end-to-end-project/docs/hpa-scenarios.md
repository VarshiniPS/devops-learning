# HPA Production Scenario

## Scenario: CPU Usage Suddenly Reaches 90%

**Context:** Your app is deployed on Kubernetes with 3 replicas. Traffic spikes
and average CPU utilization across Pods hits 90%.

---

## What Happens If HPA Is Configured

Assume an HPA is set with a target of 50% CPU utilization:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nodejs-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nodejs-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

**Sequence of events:**

1. Metrics Server reports current average CPU utilization: 90%
2. HPA polls this (every ~15s by default) and compares it against the target (50%)
3. HPA calculates desired replicas:
   ```
   desiredReplicas = ceil(currentReplicas × (currentUtilization / targetUtilization))
   desiredReplicas = ceil(3 × (90 / 50)) = ceil(5.4) = 6
   ```
4. HPA updates the Deployment's `replicas` field from 3 → 6
5. New Pods are scheduled and started — if the cluster doesn't have enough
   node capacity, these new Pods may sit `Pending` until Cluster Autoscaler
   (if configured) adds more nodes
6. As new Pods come online and start sharing the load, average CPU utilization
   drops back toward the 50% target
7. If traffic later drops, HPA scales back down — but not immediately; there's
   a default stabilization window (5 minutes) to avoid flapping up and down
   on temporary spikes

**Outcome:** The app absorbs the traffic spike automatically. Users see no
degradation (or a brief one, only until new Pods become Ready). No manual
intervention required.

---

## What Happens If HPA Is NOT Configured

Without HPA, the replica count stays fixed at 3 no matter what the load is.

**Sequence of events:**

1. CPU utilization hits 90% and **stays there** — nothing reacts to it
2. Each of the 3 Pods is now handling significantly more load than intended
3. If a **CPU limit** is set on the containers, they get **throttled** — requests
   start taking longer to process, response times climb
4. If requests keep queuing faster than they can be processed, this cascades:
   - `readinessProbe` may start failing under the load (slow health check responses)
   - A failing readiness probe pulls the Pod out of Service endpoints entirely,
     making the problem *worse* by concentrating remaining traffic onto fewer Pods
5. In the worst case, this leads to timeouts, 503 errors reaching users (same
   failure mode covered in `docs/interview-scenarios.md`), or Pods getting
   OOMKilled if memory pressure builds alongside CPU pressure
6. The only fix is **manual intervention** — someone has to notice the problem
   and run `kubectl scale` by hand

**Outcome:** Degraded performance or outright failures under load, entirely
dependent on a human noticing and reacting in time. No automatic recovery.

---

## kubectl Commands to Use

### Detecting the spike

```bash
# Check current CPU usage per Pod (requires Metrics Server)
kubectl top pods

# Check node-level CPU usage — is the whole node under pressure?
kubectl top nodes
```

### If HPA is configured — checking its status

```bash
# See current vs target utilization, and current/desired replica count
kubectl get hpa

# Example output:
# NAME         REFERENCE                      TARGETS   MINPODS   MAXPODS   REPLICAS
# nodejs-hpa   Deployment/nodejs-deployment   90%/50%   3         10        6

# Full detail, including recent scaling events
kubectl describe hpa nodejs-hpa
```

### If HPA is NOT configured — manual response

```bash
# Manually scale up to absorb the spike
kubectl scale deployment nodejs-deployment --replicas=6

# Watch new Pods come online
kubectl get pods -w

# Confirm CPU utilization drops back down after scaling
kubectl top pods
```

### Investigating whether the spike caused knock-on failures

```bash
# Check for probe failures / restarts caused by the load
kubectl get pods
kubectl describe pod <pod-name>       # check Events for "Unhealthy" readiness failures

# Check Service endpoints — did any Pods get pulled from rotation?
kubectl get endpoints <service-name>

# Check for OOMKilled containers if memory pressure also spiked
kubectl describe pod <pod-name>       # Last State: Terminated, Reason: OOMKilled
```

### Creating an HPA if one doesn't exist yet

```bash
# Quick imperative creation (or use a YAML manifest like the one above)
kubectl autoscale deployment nodejs-deployment --cpu-percent=50 --min=3 --max=10

kubectl get hpa
```

---

## Side-by-Side Summary

| | HPA Configured | HPA Not Configured |
|---|---|---|
| **Detection** | Automatic (Metrics Server → HPA loop) | Manual — someone has to notice |
| **Response time** | Seconds to minutes | Depends entirely on human response time |
| **Action taken** | Replicas scale 3 → 6 automatically | None — stays at 3 |
| **Risk** | Brief lag while new Pods start (still handled gracefully via readiness probes) | Throttling, probe failures, cascading 503s, possible OOMKills |
| **Recovery from traffic drop** | Automatic scale-down after stabilization window | Manual scale-down needed, or wasted capacity if scaled manually and left there |

---

## Key Interview Takeaway

The core value of HPA isn't just "more Pods when busy" — it's **removing the
human reaction-time bottleneck** from a failure mode that can otherwise cascade:
high CPU → throttling → slow responses → failing readiness probes → fewer
healthy Pods → *even more* load on the remaining ones. HPA breaks that
feedback loop automatically, before it has a chance to spiral, whereas without
it the system has no defense until someone manually intervenes.