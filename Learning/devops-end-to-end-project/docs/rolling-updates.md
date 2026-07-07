# Kubernetes Rolling Updates

## Why Rolling Updates Are Needed

Without a rolling update strategy, deploying a new version means one of two
bad options: take the app offline while swapping containers (unacceptable
for live traffic), or manually manage old and new versions side by side
yourself. Kubernetes automates the safe middle ground — Pods are replaced
gradually, with traffic never fully interrupted.

This is how real companies deploy dozens of times a day without users
noticing: not by being fast, but by never dropping below serving capacity
during the swap.

---

## Deployment Strategy

Our `deployment.yaml` uses:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```

With 3 replicas:

| Setting | Meaning | Effect |
|---|---|---|
| `maxUnavailable: 1` | At most 1 Pod can be down during the update | At least 2 Pods always serving traffic |
| `maxSurge: 1` | At most 1 extra Pod beyond desired count | Capacity never drops below normal during rollout |

**The sequence, step by step:**

1. Kubernetes creates 1 new Pod (v2) — total is now 4 Pods (3 old + 1 new)
2. New Pod's readiness probe must pass before it receives traffic
3. Once ready, 1 old Pod (v1) is terminated — back to 3 Pods (2 old + 1 new)
4. Repeat: create next new Pod, wait for ready, terminate next old Pod
5. Continue until all 3 Pods are on the new version

At every point in this sequence, at least 2 Pods are serving traffic —
zero-downtime by construction, not by luck.

### Alternative strategies

| Strategy | Behavior | When to use |
|---|---|---|
| `RollingUpdate` (ours) | Gradual swap, zero downtime | Default choice for stateless apps |
| `Recreate` | Kill all old Pods first, then start new ones | When old and new versions can't run side by side (e.g. incompatible DB schema) |
| Blue-Green (not native K8s) | Two full environments, instant traffic switch | Instant rollback, but doubles infrastructure cost during the switch |
| Canary (not native K8s) | Send a small % of traffic to new version first | Gradual confidence-building before full rollout, needs a service mesh or Ingress weight support |

---

## Rollback

Kubernetes never deletes an old ReplicaSet when you deploy a new version —
it scales the old one to 0 and keeps it around. This is *why* rollback is
instant: `rollout undo` just scales the previous ReplicaSet back up and the
current one down.

```bash
kubectl get replicasets
# NAME                            DESIRED   CURRENT   READY   AGE
# nodejs-deployment-5cc44c6cc4    0         0         0       2d   ← old, kept
# nodejs-deployment-7f9d8b5a2c    3         3         3       5m   ← current
```

---

## Hands-On: Full Sequence

### Step 1 — Build and push a new image version

```bash
docker build -f docker/Dockerfile -t varshinips/node-app:v3 .
docker push varshinips/node-app:v3
```

### Step 2 — Update deployment.yaml and apply

Change the `image:` line in `kubernetes/deployment.yaml` to the new tag,
then:

```bash
kubectl apply -f kubernetes/deployment.yaml
```

### Step 3 — Watch the rollout live

```bash
kubectl rollout status deployment/nodejs-deployment
```

```
Waiting for deployment "nodejs-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nodejs-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
deployment "nodejs-deployment" successfully rolled out
```

### Step 4 — Check rollout history

```bash
kubectl rollout history deployment/nodejs-deployment
```

```
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>
```

`CHANGE-CAUSE` shows `<none>` unless you annotate the change. Do this going
forward so history is actually useful:

```bash
kubectl apply -f kubernetes/deployment.yaml --record
# or, cleaner in modern kubectl:
kubectl annotate deployment/nodejs-deployment \
  kubernetes.io/change-cause="bump to v3, fix logging bug"
```

### Step 5 — Roll back

```bash
# Revert to the immediately previous revision
kubectl rollout undo deployment/nodejs-deployment

# Or roll back to a specific revision
kubectl rollout undo deployment/nodejs-deployment --to-revision=1
```

### Step 6 — Confirm the rollback

```bash
kubectl get deployment nodejs-deployment -o jsonpath="{.spec.template.spec.containers[0].image}"
kubectl rollout status deployment/nodejs-deployment
```

---

## What to Watch During a Rollout

```bash
# Watch Pods transition live — old Pods terminating, new ones starting
kubectl get pods -w
```

Healthy rollout output looks like:
```
NAME                                  READY   STATUS              AGE
nodejs-deployment-xxxxx-v1a           1/1     Running             5d
nodejs-deployment-xxxxx-v1b           1/1     Running             5d
nodejs-deployment-xxxxx-v1c           1/1     Terminating         5d
nodejs-deployment-xxxxx-v2a           0/1     ContainerCreating   2s
nodejs-deployment-xxxxx-v2a           1/1     Running             8s
```

If a new Pod never reaches `1/1 Running`, the rollout stalls automatically —
Kubernetes won't terminate more old Pods than `maxUnavailable` allows, so a
broken new version can't take down the whole app. This is the built-in
safety net: a bad rollout degrades gracefully instead of failing all at once.

---

## Common Gotchas

| Problem | Symptom | Fix |
|---|---|---|
| Rollout stuck | `kubectl rollout status` hangs indefinitely | New Pod is failing readiness — check `kubectl describe pod <new-pod>` |
| `CHANGE-CAUSE` always `<none>` | History unhelpful for debugging | Annotate every deploy with `kubernetes.io/change-cause` |
| Rollback doesn't seem to change anything | Image still shows old tag | Confirm with `kubectl get deployment -o jsonpath=...` — may have rolled back further than expected |
| Too many Pods during rollout | Resource pressure, evictions | Lower `maxSurge` if cluster has tight resource limits |
| App breaks mid-rollout, no automatic stop | Bad version serving some traffic | Kubernetes doesn't auto-rollback on app-level errors — only Pod-not-ready. Use readiness probes that actually check business logic, not just "process is up" |

---

## Key Takeaways

1. Rolling updates replace Pods gradually — `maxUnavailable` and `maxSurge`
   together guarantee capacity never drops during a deploy.
2. Readiness probes are the real safety mechanism — a new Pod doesn't get
   traffic, and an old Pod doesn't get killed, until the new one proves itself.
3. Rollback is instant because the old ReplicaSet was never deleted, just
   scaled to zero.
4. `kubectl rollout status` blocks until the rollout finishes or fails —
   useful in CI pipelines to know a deploy actually succeeded before moving on.
5. Always annotate deploys with a change-cause — `<none>` in rollout history
   is useless during an incident.
6. A bad application-level bug won't trigger an automatic rollback unless
   your readiness probe is strict enough to catch it — a probe that only
   checks "is the process running" won't stop a logically broken deploy.
