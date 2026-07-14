# Production Scenario: "App is slow, but Pods are Running"

## The Scenario

Users report slow response times. `kubectl get pods` shows every Pod
`Running` and `1/1 Ready`. Nothing is crashing, nothing is restarting — yet
something is clearly wrong. "Running" only means the container process is
alive; it says nothing about whether it's performing well.

---

## What to Check First

Work in order of cost — cheapest, fastest checks first:

1. **Resource usage** — is a Pod or node near its CPU/memory limit?
2. **Application-level latency** — is the app itself slow, independent of
   Kubernetes?
3. **Network path** — is the delay happening in Ingress, Service, or DNS
   rather than inside the Pod at all?
4. **Downstream dependencies** — is the app waiting on a slow database,
   external API, or another service it calls?

---

## Commands to Use

### Step 1 — Check resource usage

```bash
kubectl top pods
kubectl top nodes
```

```
NAME                                  CPU(cores)   MEMORY(bytes)
nodejs-deployment-xxxxx-aaaaa         240m         250Mi
nodejs-deployment-xxxxx-bbbbb         238m         248Mi
nodejs-deployment-xxxxx-ccccc         241m         251Mi
```

Compare against the `resources.limits` set in `deployment.yaml` (our app: 250m
CPU, 256Mi memory). If usage is sitting right at the limit, the container is
being CPU-throttled or is close to an OOM kill — that alone explains slowness
without any crash.

```bash
kubectl describe node <node-name>
```

Check the `Allocated resources` section — if the node itself is over-committed
(too many Pods scheduled for its capacity), every Pod on it degrades, not
just yours.

### Step 2 — Isolate app-level latency from Kubernetes routing

Bypass every layer above the Pod and time the response directly:

```bash
kubectl exec -it <pod-name> -- sh
# inside the pod:
time wget -qO- http://localhost:3000/health
```

If the response is fast **inside** the Pod but slow from outside, the
bottleneck is in Kubernetes routing (Ingress, Service, DNS) — not the app.
If it's slow even inside the Pod, the bottleneck is the application itself.

### Step 3 — Check logs for slow operations

```bash
kubectl logs <pod-name> --tail=100
kubectl logs -f <pod-name>
```

Look for long gaps between log lines, repeated retries, or timeout messages
— these point to a slow downstream call (database, external API) rather
than the Pod itself being resource-starved.

### Step 4 — Check the Service and Ingress layer

```bash
kubectl describe svc nodejs-service
kubectl describe ingress nodejs-ingress
```

If `Endpoints` includes a Pod that's actually unhealthy or slow to respond
but still passing its readiness probe (probe checks a lightweight path, but
the real traffic hits a heavier one), some fraction of requests will be slow
while `kubectl get pods` shows everything green.

### Step 5 — Check events for resource pressure signals

```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

Look for `Evicted`, `FailedScheduling` on other Pods (signals node pressure),
or repeated `Unhealthy` warnings on probes that are borderline passing —
these often precede a full outage and explain intermittent slowness.

---

## Determining App Issue vs Kubernetes Issue

The single fastest diagnostic: **compare latency measured from inside the
Pod against latency measured from outside it.**

```bash
# Outside — through the full stack (Ingress → Service → Pod)
time curl -H "Host: nodejs-app.example.com" http://<ADDRESS>/health

# Inside — direct to the container, bypassing all K8s routing
kubectl exec -it <pod-name> -- sh -c "time wget -qO- http://localhost:3000/health"
```

| Result | Diagnosis |
|---|---|
| Fast inside, slow outside | Kubernetes-level — Ingress, Service, DNS, or network policy |
| Slow both inside and outside | Application-level — code, database query, external API call |
| Fast for `/health`, slow for real routes | App-level — the specific business logic is slow, not the process itself |
| Slow only under load, fine when idle | Resource-level — check `kubectl top pods` against `resources.limits` |

**Why this works:** `/health` and `/ready` are intentionally lightweight —
they don't touch a database or call anything external. If those respond
fast but real endpoints don't, the slowness is isolated to specific business
logic, not the container or the platform.

---

## Common Root Causes, Ranked by Likelihood

1. **CPU throttling** — Pod is hitting its CPU limit, Kubernetes throttles
   it, requests queue up. `kubectl top pods` sitting near `resources.limits.cpu`
   is the tell.
2. **Slow downstream dependency** — the app is waiting on a database query,
   external API, or another microservice that's degraded. Not visible in
   `kubectl top` at all — only shows up in logs or app-level tracing.
3. **Too few replicas for current load** — 3 Pods handling traffic that
   needs 6. Each individual Pod looks healthy; the aggregate can't keep up.
   Check request rate against replica count.
4. **Node-level resource contention** — other Pods on the same node are
   consuming CPU/memory, starving yours despite your Pod's own limits being
   fine. `kubectl describe node` reveals this.
5. **DNS resolution delay** — CoreDNS under load or misconfigured, adding
   latency to every outbound call the app makes. Check CoreDNS Pod health
   and logs if the app makes many external calls.

---

## Key Takeaways

1. `Running` and `Ready` only confirm the process is alive and passing its
   probe — neither says anything about performance.
2. Compare latency from inside the Pod against latency from outside it —
   this one test splits the investigation into "Kubernetes problem" vs
   "application problem" immediately.
3. `/health` and `/ready` are lightweight by design — if they're fast but
   real endpoints are slow, the issue is business logic, not the platform.
4. Check `kubectl top pods` against `resources.limits` before anything else
   — CPU throttling is the most common and cheapest-to-diagnose cause.
5. A slow downstream dependency (database, external API) never shows up in
   resource metrics — only in logs or application-level tracing. Don't stop
   at `kubectl top` if it looks clean.