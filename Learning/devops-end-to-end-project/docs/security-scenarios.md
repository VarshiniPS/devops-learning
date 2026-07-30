# Production Scenario: "Pods from one application can reach every other application"

## The Scenario

The security team flags that Pods belonging to one app can freely
communicate with Pods belonging to completely unrelated applications in the
same cluster. Nothing is technically broken — this is Kubernetes' default
behavior. That's exactly the problem.

---

## Why Is This a Problem?

### 1. No blast radius containment

By default, every Pod in a cluster can reach every other Pod, on any port,
regardless of namespace or application boundary. If a single Pod is
compromised — a vulnerable dependency, a leaked credential, a container
escape — the attacker isn't contained to that one application. They can
immediately probe and reach every other workload in the cluster, including
ones with no logical relationship to the compromised app.

### 2. Sensitive services are equally exposed

A public-facing web app Pod and an internal payments or database Pod sit on
the same flat network by default. A compromised frontend Pod can talk
directly to a database Pod it should never have any reason to reach — no
firewall, no segmentation, nothing stopping it at the network layer.

### 3. Violates least privilege

Security best practice is that every component should only have the access
it explicitly needs. A default-open network is the opposite: every
component has access to everything, whether it needs it or not. This is
true even without a compromise — a coding bug in app-a could accidentally
send malformed traffic to app-b's internal API with nothing stopping it.

### 4. Lateral movement is the actual attack technique this enables

This is the specific attack pattern security teams are worried about: an
attacker who gains a foothold in one low-value Pod uses the flat network to
move laterally toward higher-value targets — databases, secrets managers,
internal admin APIs — that were never meant to be reachable from where they
landed.

---

## How Would You Restrict Traffic?

Use **Network Policies** — Kubernetes' native mechanism for defining
allowed traffic between Pods, based on label selectors.

### The restriction strategy, step by step

**1. Start with a default-deny policy per namespace**

This flips the default from open to closed — nothing is allowed until
explicitly permitted.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}          # applies to every Pod in this namespace
  policyTypes:
    - Ingress
    - Egress
```

**2. Explicitly allow only the traffic each app actually needs**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-to-db
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: db                    # this policy protects the db Pods
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: nodejs-app     # only Pods labeled app=nodejs-app may connect
      ports:
        - protocol: TCP
          port: 5432
```

With both policies applied: the `db` Pod accepts traffic only from Pods
labeled `app: nodejs-app`, on port 5432. Every other Pod in the cluster —
including completely unrelated applications — is denied by default.

**3. Repeat per application boundary**

Each application gets its own explicit allow-list of what it's permitted to
talk to. Anything not listed is denied — this is what actually closes the
lateral movement gap the security team flagged.

### Namespace isolation as a complementary layer

Beyond per-Pod policies, placing unrelated applications in **separate
namespaces** and writing Network Policies scoped to namespace boundaries
adds another layer — an entire application's Pods can be denied from ever
reaching another application's namespace at all, regardless of label
mistakes within either app.

```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            name: production
        podSelector:
          matchLabels:
            app: nodejs-app
```

---

## Which Kubernetes Resource Would You Use?

**`NetworkPolicy`** (`networking.k8s.io/v1`) — the native Kubernetes
resource for this exact problem.

Two things to verify before relying on it in production:

1. **CNI plugin support is required.** `NetworkPolicy` objects are inert
   unless your CNI plugin enforces them. Calico, Cilium, and most cloud
   CNIs (AWS VPC CNI as of newer versions) support enforcement — but plain
   `kube-proxy` networking silently ignores NetworkPolicy objects entirely.
   Applying one and assuming it's protecting you, without confirming
   enforcement is active, is a real production trap.

2. **Verify the fix, don't just assume it worked.**
   ```bash
   kubectl exec -it <app-a-pod> -- wget -qO- --timeout=3 http://payments-service
   # Before fix: succeeds
   # After fix: times out or connection refused
   ```

---

## Full Response to the Security Team

1. Confirm the CNI plugin in use supports NetworkPolicy enforcement.
2. Apply a default-deny NetworkPolicy per namespace — closes the flat
   network immediately, even before individual allow-rules exist.
3. Work with each app team to define explicit allow-rules — only the
   specific Pod-to-Pod paths that are actually required.
4. Verify enforcement with a direct connectivity test, not just by reading
   the applied YAML.
5. Document the intended traffic graph so future NetworkPolicy changes have
   a reference for what's supposed to be allowed.

---

## Key Takeaways

1. Kubernetes' default is fully open Pod-to-Pod networking — isolation is
   opt-in, not opt-out. This is the root cause of the scenario.
2. `NetworkPolicy` is the native resource for restricting this, using label
   selectors to define allowed ingress/egress per Pod.
3. Default-deny-then-explicit-allow is the standard pattern — deny
   everything first, then open only the specific paths each app needs.
4. NetworkPolicy objects do nothing without CNI plugin support — always
   confirm enforcement is active, don't assume from the YAML alone.
5. This scenario is the practical consequence of the "flat, open by
   default" networking model — the same default networking model discussed
   in interview prep, now showing up as an actual security finding.