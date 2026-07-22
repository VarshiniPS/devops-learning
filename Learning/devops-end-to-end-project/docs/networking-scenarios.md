# Networking Production Scenario

## Scenario: Users Cannot Access the Application, But Pods Are Running

**Context:** `kubectl get pods` shows every Pod as `Running` with `READY: 1/1`.
Yet users hitting the app externally get no response, a timeout, or a 503.

This is a deliberately tricky scenario because the most obvious check —
"are the Pods up?" — already passes. The problem is somewhere in the
**layers between the user and the Pod**, not the Pod itself.

---

## What Would You Check First

Work **inside-out**, same principle as the earlier 503 scenario: start at the
layer closest to the Pod, since it's fastest to check and most likely to be
the actual cause, then move outward.

**First check — does the Service actually have endpoints?**
```bash
kubectl get endpoints <service-name>
```
Since Pods are already confirmed `Running` and `1/1 Ready`, this is the very
next thing to verify — a healthy Pod doesn't guarantee the Service is
correctly pointing at it.

**Why this is the right starting point, not the Pod layer:** the scenario
already told us Pods are Running — re-checking Pod health first would be
redundant. The fastest useful next step is confirming the Service actually
sees those healthy Pods as valid targets.

---

## Service or Ingress? — How to Tell Which Layer Is Broken

Don't guess — use a quick test to split the problem in two:

```bash
# Test directly from inside the cluster, bypassing Ingress entirely
kubectl run test --image=busybox --rm -it -- wget -qO- http://<service-name>
```

| Result | What it tells you |
|---|---|
| ✅ Works internally | Service + Pods are fine → problem is in **Ingress**, the LoadBalancer, or something external (DNS, security groups) |
| ❌ Fails internally too | Problem is in the **Service** itself (selector mismatch, wrong port) — don't bother checking Ingress yet |

This single test is the fastest way to divide "is this a Kubernetes-internal
problem or an edge/external-routing problem" — always run it before spending
time reading Ingress YAML.

---

## How Would You Verify Endpoints

```bash
# Does the Service have any Pod IPs behind it at all?
kubectl get endpoints <service-name>

# Newer, more detailed version (used internally since k8s 1.19+)
kubectl get endpointslices

# Compare: does the Service's selector actually match the Pods' labels?
kubectl describe svc <service-name>
kubectl get pods --show-labels
```

**What you're looking for:**

- `kubectl get endpoints <service-name>` returning `<none>` → confirmed root
  cause: the Service has zero valid targets, regardless of how healthy the
  Pods are. This happens even when Pods are `Running` and `Ready` — Endpoints
  are populated purely based on **label matching**, not Pod health status
  alone (though an unready Pod is also excluded).

- Endpoints *do* show Pod IPs, but they look wrong or stale → check if
  there's an old/leftover ReplicaSet still holding Pods with different labels
  (`kubectl get replicasets`), a scenario covered in the "users see old
  version" troubleshooting entry.

- Endpoints show correct, current Pod IPs → the Service layer is fine, move
  to checking Ingress.

---

## kubectl Commands to Use, In Order

```bash
# 1. Confirm Pods are genuinely healthy (already given in this scenario, but verify)
kubectl get pods
kubectl get pods --show-labels

# 2. Check if the Service has any endpoints at all — the key diagnostic step
kubectl get endpoints <service-name>
kubectl get endpointslices

# 3. Compare Service selector against Pod labels directly
kubectl describe svc <service-name>

# 4. Test connectivity from inside the cluster (isolates internal vs external)
kubectl run test --image=busybox --rm -it -- wget -qO- http://<service-name>

# 5. If internal test works, move outward — check Ingress
kubectl describe ingress <ingress-name>
kubectl get ingress <ingress-name>
# look at ADDRESS field — is a real LB DNS name assigned, or still blank?

# 6. Check DNS resolution specifically, in case that's the break point
kubectl exec -it <any-pod> -- nslookup <service-name>

# 7. If this is EKS/cloud and Ingress looks correct, check the cloud load balancer
#    (target group health, security groups) — outside kubectl, in the AWS Console
```

---

## Full Diagnosis Flow (Summary)

```
Users can't access the app; Pods confirmed Running
   │
   ▼
kubectl get endpoints <service>     → empty? → Service selector/label mismatch (fix and stop here)
   │  (endpoints present)
   ▼
kubectl run test -- wget <service>  → fails? → back to Service config (wrong port? wrong selector?)
   │  (works internally)
   ▼
kubectl describe ingress <name>     → rules point to correct Service + port?
   │  (Ingress config correct)
   ▼
kubectl get ingress                 → ADDRESS populated? Ingress Controller actually running?
   │  (address exists)
   ▼
Check cloud load balancer health (AWS Console) → target group health, security groups
```

---

## Key Interview Takeaway

**"Pods are Running" only confirms the innermost layer is healthy — it says
nothing about whether the Service can actually route to them, or whether
Ingress/LoadBalancer can reach the Service.** The single fastest diagnostic
command in this exact scenario is `kubectl get endpoints <service-name>` —
because it's the one place where "Pod is healthy" and "Service is configured
correctly" actually get validated together. An empty result there is the most
common real-world cause of "everything looks fine but nothing works," and it
takes one command to check, before ever touching Ingress or cloud console.