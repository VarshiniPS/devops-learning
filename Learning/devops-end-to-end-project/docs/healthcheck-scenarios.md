# Production Scenario: "Pod is Running, but the Service is not sending traffic to it"

## The Scenario

`kubectl get pods` shows the Pod as `Running`. But requests to the Service
never reach it — the Pod is effectively invisible to traffic. This is the
practical, real-world version of the "Running vs Ready" distinction: the
container process started successfully, but something is preventing the
Service from including it as a valid destination.

---

## Possible Causes

### 1. Readiness probe is failing

The most common cause. `Running` only confirms the process started —
`Ready` is a separate, independent check. If the readiness probe never
passes, Kubernetes deliberately withholds traffic from the Pod, even though
it's alive and shows `Running`.

### 2. Service selector doesn't match the Pod's labels

The Service finds Pods purely by label matching. If the Pod's labels were
changed (a typo, a template update, a manual edit) and no longer match the
Service's `selector`, the Service has no way to find it — regardless of
health.

### 3. Endpoints object is stale or empty

Endpoints are what actually get updated when a Pod becomes Ready. If the
Endpoints controller hasn't reconciled yet (rare, but possible under load
or API server pressure), the Service's routing table can lag behind the
Pod's actual state.

### 4. Pod is in the wrong namespace

The Service and the Pod must be in the same namespace unless using a
fully-qualified cross-namespace DNS name. A Pod deployed to the wrong
namespace by mistake will never be found by a same-namespace Service.

### 5. containerPort / targetPort mismatch

If the Service's `targetPort` doesn't match the actual port the container
listens on, the Pod may show as an Endpoint but every request will fail to
connect — which looks like "no traffic reaching it" from the user's side,
even though Kubernetes considers it wired correctly.

---

## How to Troubleshoot

Work from the same principle as any Kubernetes investigation: check what
Kubernetes itself believes is true (Pod state, Endpoints) before assuming
the network is broken.

### Step 1 — Confirm the Pod is actually Ready, not just Running

```bash
kubectl get pods
```

```
NAME                                  READY   STATUS    RESTARTS   AGE
nodejs-deployment-xxxxx-aaaaa         0/1     Running   0          4m
```

`READY` shows `0/1` — this is the tell. `Running` and `Ready` are reported
separately for exactly this reason.

### Step 2 — Check why readiness is failing

```bash
kubectl describe pod <pod-name>
```

Look at the **Events** section and the **Conditions** section:

```
Conditions:
  Type              Status
  Ready             False
  ContainersReady   False

Events:
  Type     Reason     Age   From     Message
  ----     ------     ----  ----     -------
  Warning  Unhealthy  30s   kubelet  Readiness probe failed: HTTP probe failed with statuscode: 503
```

This tells you exactly what the probe is checking and why it's failing —
wrong path, app not fully initialized, dependency not yet connected.

### Step 3 — Confirm the Service selector matches the Pod's labels

```bash
kubectl get pods --show-labels
kubectl describe svc nodejs-service
```

Compare the `Selector:` line in the Service output against the actual
labels on the Pod. They must match exactly.

### Step 4 — Check the Endpoints object directly

This is the single fastest way to see the ground truth of what the Service
actually considers routable right now.

```bash
kubectl get endpoints nodejs-service
```

```
NAME             ENDPOINTS                                   AGE
nodejs-service   10.244.0.6:3000,10.244.0.7:3000              4d
```

Cross-check these IPs against actual Pod IPs:

```bash
kubectl get pods -o wide
```

If a Pod's IP is missing from Endpoints, that Pod isn't receiving traffic
— whether because it's not Ready, or because the selector never matched it
in the first place.

### Step 5 — Verify port configuration

```bash
kubectl get svc nodejs-service -o yaml
```

Confirm `targetPort` matches the actual `containerPort` the app listens on
(3000, in our `app.js`). A Pod can appear in Endpoints and still receive
zero working requests if this is misconfigured.

### Step 6 — Test the Pod directly, bypassing the Service entirely

```bash
kubectl exec -it <pod-name> -- wget -qO- http://localhost:3000/ready
```

If this succeeds, the app itself is healthy and the problem is entirely in
Service/label/Endpoints wiring, not the application.

---

## kubectl Commands Reference

```bash
# Is it Running AND Ready, or just Running?
kubectl get pods

# Why is readiness failing — Events and Conditions
kubectl describe pod <pod-name>

# Do Pod labels match the Service selector?
kubectl get pods --show-labels
kubectl describe svc <service-name>

# Ground truth — which Pod IPs does the Service actually route to?
kubectl get endpoints <service-name>

# Cross-check against real Pod IPs
kubectl get pods -o wide

# Confirm port wiring
kubectl get svc <service-name> -o yaml

# Bypass the Service, test the Pod directly
kubectl exec -it <pod-name> -- wget -qO- http://localhost:3000/ready
```

---

## The Fast Path

```bash
kubectl get endpoints <service-name>
```

One command, one answer. If the Pod's IP is listed — it's receiving
traffic, and the user's problem is elsewhere (client-side, DNS, Ingress).
If it's missing — cross-check readiness (`describe pod`) and labels
(`--show-labels` vs `describe svc`) to find out why.

---

## Key Takeaways

1. `Running` and `Ready` are separate, independently-tracked states — a Pod
   can be fully alive and still correctly excluded from traffic.
2. `kubectl get endpoints` is the ground truth for "is this Pod actually
   reachable through the Service right now" — check it before anything else.
3. Services route purely by label matching — a label typo or template drift
   silently breaks routing with no error message anywhere.
4. A Pod appearing in Endpoints doesn't guarantee working requests —
   `targetPort` must also match the container's actual listening port.
5. `kubectl exec` directly into the Pod isolates whether the problem is the
   application itself or the Service/label/Endpoints layer around it.