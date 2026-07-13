# Production Scenario: "Deployment completed, but users see the old version"

## The Scenario

`kubectl rollout status` reported success. CI/CD showed green. But users are
reporting they're still seeing the old version of the app. This is one of
the most common real-world Kubernetes incidents — and a favorite interview
question because it tests whether you understand every layer between a
Deployment and a user's browser, not just the happy path.

---

## Possible Causes

### 1. Pods aren't actually running the new image

- `imagePullPolicy: IfNotPresent` combined with reusing the same tag (`:latest`)
  means the node may serve its cached local image instead of pulling the new one
- The rollout technically "completed" against an unchanged Pod template — if
  the image tag in `deployment.yaml` was never actually updated, `kubectl apply`
  detects no diff and does nothing
- Multiple ReplicaSets exist and the old one wasn't fully scaled down

### 2. Service is routing to stale or wrong Pods

- Old Pods are stuck in `Terminating` and still receiving traffic briefly
- Service `selector` doesn't match the labels on the new Pods (rare after a
  rollout, but possible if labels changed between versions)
- Multiple Deployments share overlapping label selectors, and the Service is
  balancing across both old and new Deployments unintentionally

### 3. Client-side or infrastructure caching

- Browser cache serving a stale response (most common cause, most often missed)
- A CDN or reverse proxy in front of the Ingress caching responses
- Testing against a bookmarked IP or an old load balancer endpoint that no
  longer points at the current cluster

### 4. Wrong environment entirely

- Testing against staging while production was the one deployed (or vice versa)
- `kubectl` context pointing at a different cluster than the one CI/CD deployed to

---

## Investigation Steps

Work outward from the Pod, not inward from the browser — the Pod is ground
truth and every other layer sits between it and the user.

### Step 1 — Confirm what image is actually running

```bash
kubectl get deployment nodejs-deployment -o jsonpath="{.spec.template.spec.containers[0].image}"
```

If this doesn't show the expected new tag, the rollout never targeted the
right image — stop here, fix the Deployment spec, redeploy.

### Step 2 — Confirm every individual Pod matches, not just the spec

The Deployment spec can say one thing while individual Pods still run
something else if a rollout is stuck mid-way.

```bash
kubectl get pods -o wide
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
```

Every Pod should show the identical new image. If even one shows the old
tag, the rollout is incomplete — check `kubectl rollout status` again and
look for a stuck Pod.

### Step 3 — Check for leftover ReplicaSets

```bash
kubectl get replicasets
```

The old ReplicaSet should show `0/0/0` (desired/current/ready). If it still
shows replicas greater than zero, it hasn't been scaled down — traffic could
still be reaching it.

### Step 4 — Bypass Service and Ingress, ask a Pod directly

This is the fastest way to rule out every layer above the Pod in one step.

```bash
kubectl exec -it <pod-name> -- wget -qO- http://localhost:3000/info
```

If this returns the new version, the Pod layer is correct — the bug is in
Service or Ingress routing, or client-side caching. If it returns the old
version, the bug is at the Pod/image layer — go back to Steps 1–3.

### Step 5 — Check Service selector and endpoints

```bash
kubectl describe svc nodejs-service
```

Look at `Selector:` and `Endpoints:`. Every IP listed under Endpoints should
belong to a currently-running new-version Pod (cross-check against Step 2's
Pod list). If Endpoints includes an IP that no longer exists, the Service
hasn't refreshed — rare, but worth ruling out.

### Step 6 — Check the Ingress layer

```bash
kubectl describe ingress nodejs-ingress
```

Confirm the `Backends:` line shows the same healthy Pod IPs as Step 5.

### Step 7 — Rule out caching (client, CDN, browser)

```bash
curl -s -H "Cache-Control: no-cache" -H "Host: nodejs-app.example.com" http://<ADDRESS>/info
```

Compare against what a normal browser request returns. If `curl` shows the
new version but the browser doesn't, it's a client-side cache issue — hard
refresh, clear cache, or check for a CDN/reverse proxy in front of the cluster.

### Step 8 — Confirm you're pointed at the right cluster/environment

```bash
kubectl config current-context
kubectl get namespaces
```

Sanity check this is genuinely the environment CI/CD just deployed to, not
a leftover local or staging context.

---

## kubectl Commands Reference

```bash
# What image does the Deployment spec say?
kubectl get deployment <name> -o jsonpath="{.spec.template.spec.containers[0].image}"

# What image is every actual Pod running?
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

# Is the old ReplicaSet still scaled up?
kubectl get replicasets

# Ask a Pod directly, bypassing every routing layer
kubectl exec -it <pod-name> -- wget -qO- http://localhost:3000/info

# Is the Service pointing at the right Pods?
kubectl describe svc <service-name>

# Is the Ingress routing to healthy backends?
kubectl describe ingress <ingress-name>

# Full rollout status and history
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>

# Confirm cluster context
kubectl config current-context
```

---

## The Fast Path (if short on time in an interview or incident)

1. `kubectl exec` into any Pod, curl `/info` locally — ground truth in one command
2. If Pod is correct but user isn't seeing it → Service/Ingress/cache, not Kubernetes
3. If Pod is wrong → rollout didn't actually complete, or wrong image was deployed

---

## Key Takeaways

1. "Rollout completed successfully" only confirms the Deployment reached its
   desired replica count with passing readiness probes — it says nothing
   about whether the *content* users see actually changed.
2. Always verify from the Pod outward, not the browser inward — the Pod is
   the one source of ground truth every other layer routes through.
3. `imagePullPolicy: IfNotPresent` with a reused tag is a classic trap —
   always use a unique tag (commit SHA) per deploy, never rely on `:latest`.
4. Browser and CDN caching is the most overlooked cause precisely because it
   has nothing to do with Kubernetes at all — rule it out with a direct curl
   before assuming the cluster is broken.
5. Old ReplicaSets scaled to zero are supposed to still exist (for rollback) —
   the bug is only if they're scaled *above* zero after a completed rollout.