# Kubernetes Networking

**Session:** 8:00 - 9:45 AM | Hands-On
**Goal:** Understand how Pods find and talk to each other, and the layers between an app and a Service

---
 
## Kubernetes DNS

Every Kubernetes cluster runs an internal DNS service (CoreDNS by default),
giving every Service a stable DNS name — so Pods never need to know Service IPs,
just names.

**Standard Service DNS format:**
```
<service-name>.<namespace>.svc.cluster.local
```

Example: `nodejs-service.default.svc.cluster.local`

From within the same namespace, the short form works too:
```
nodejs-service
```

**This is why apps reference each other by name, not IP** — Service IPs
(ClusterIPs) can technically change if a Service is deleted and recreated, but
the DNS name stays stable as long as the Service name doesn't change.

---

#
# Service Discovery

"Service discovery" is the general problem this all solves: *how does one Pod
find another Pod's current, correct address, when Pods are constantly being
created, destroyed, and rescheduled with new IPs?*

Kubernetes solves it with a layer of indirection:

```
App code references: http://nodejs-service
      │
      ▼  DNS lookup
CoreDNS resolves "nodejs-service" → ClusterIP (stable virtual IP)
      │
      ▼  kube-proxy routes traffic
ClusterIP → one of the healthy Pod IPs behind it
```


The app never hardcodes a Pod IP — it always goes through the Service's DNS
name, and Kubernetes handles the constantly-changing Pod IPs underneath.

---

## Service Types

### ClusterIP (default)

- Internal-only virtual IP, stable for the Service's lifetime
- Only reachable from inside the cluster
- Used for Pod-to-Pod communication (e.g. a frontend calling a backend API)

```yaml
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 3000
```

### NodePort

- Opens the same port on **every Node** in the cluster (range 30000-32767)
- Reachable from outside via `<any-node-IP>:<nodePort>`
- Mostly used for dev/testing, or as the layer underneath a LoadBalancer

```yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 3000
      nodePort: 30080
```

### LoadBalancer

- Provisions a real cloud load balancer (AWS ALB/NLB, etc.)
- Superset of NodePort + ClusterIP — traffic flows:
  `Internet → cloud LB → NodePort → ClusterIP → Pod`
- Standard for exposing production services directly (though Ingress is more
  common when routing multiple services through one entry point)

```yaml
spec:

type: LoadBalancer
  ports:
    - port: 80
      targetPort: 3000
```

### ExternalName (Overview)

A special Service type that doesn't proxy traffic to Pods at all — it's a pure
**DNS alias** to an external name.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: mydb.example-external-host.com
```

Any Pod that looks up `external-db` gets a `CNAME` pointing to
`mydb.example-external-host.com` — useful for referring to an external
database or third-party API using the same internal DNS pattern as every
other Service, without hardcoding the external hostname throughout your app.

> No ClusterIP, no port mapping, no proxying — it's purely a DNS-level redirect.

---

## CNI (Concept)

**CNI (Container Network Interface)** is the plugin standard that actually
gives every Pod its IP address and wires up Pod-to-Pod networking across
nodes. Kubernetes itself doesn't implement networking — it delegates to a CNI
plugin (Calico, Flannel, AWS VPC CNI, Cilium, etc.).

**What CNI is responsible for:**
- Assigning a unique IP to every Pod
- Making every Pod able to reach every other Pod's IP directly, even across
  different nodes, without NAT
- Enforcing NetworkPolicies (if the CNI plugin supports them — not all do)

**On EKS specifically:** the **AWS VPC CNI** is used, which assigns Pods real
IP addresses from the VPC's subnet ranges directly — this is why Pods on EKS
can be reached using standard AWS networking constructs (security groups,
VPC routing) in a way that's different from other CNI plugins that use
overlay networks.

You don't usually configure CNI directly day-to-day, but it's worth knowing
it's the layer beneath Services/kube-proxy that makes basic Pod IP
connectivity possible in the first place.

---

## Practice: Inspecting Services and Endpoints

```bash
# List all Services in the current namespace
kubectl get svc

# Full detail on a specific Service — selector, ports, type
kubectl describe svc nodejs-service

# See which Pod IPs are actually behind a Service right now
kubectl get endpoints nodejs-service

# The newer, more scalable version of Endpoints (used internally since k8s 1.19+)
kubectl get endpointslices
```

**What to look for in `describe svc` output:**
```
Name:              nodejs-service
Selector:          app=nodejs-app
Type:              ClusterIP
IP:                10.100.45.12
Port:              <unset>  80/TCP
TargetPort:        3000/TCP
Endpoints:         10.244.0.14:3000,10.244.0.15:3000,10.244.0.16:3000
```

If `Endpoints:` shows `<none>`, the Service's `Selector` doesn't match any
Pod's `labels` — the single most common cause of "Service exists but nothing
works," covered in earlier troubleshooting sessions.

---

## Practice: Testing DNS Resolution from Inside a Pod

```bash
# Exec into a running Pod
kubectl exec -it <pod-name> -- sh

# Once inside, test DNS resolution
nslookup nodejs-service
# or, if nslookup isn't available in a minimal image:
cat /etc/resolv.conf          # confirms the cluster DNS server is configured
wget -qO- http://nodejs-service     # actually test connectivity end-to-end
```

**Expected `nslookup` output:**
```
Server:    10.96.0.10
Address:   10.96.0.10:53

Name:      nodejs-service.default.svc.cluster.local
Address:   10.100.45.12
```

That `10.96.0.10` is the cluster's internal DNS Service (CoreDNS) — every Pod
gets this injected automatically via `/etc/resolv.conf`, which is how DNS
lookups for Service names work without any manual configuration in the app.

**Quick one-liner without exec'ing in interactively:**
```bash
kubectl run dns-test --image=busybox --rm -it -- nslookup nodejs-service
```

---

## The Full Chain: Application → Service → Endpoints → Pods

```
Application code
      │  makes a request to "http://nodejs-service"
      ▼
DNS Resolution (CoreDNS)
      │  "nodejs-service" → ClusterIP (e.g. 10.100.45.12)
      ▼
Service (ClusterIP)
      │  kube-proxy intercepts traffic to this virtual IP
      │  looks up current Endpoints/EndpointSlices for this Service
      ▼
Endpoints / EndpointSlices
      │  the live list of Pod IPs currently matching the Service's selector
      │  updated automatically as Pods are created/destroyed/become (un)ready
      ▼
Pod
      │  one specific Pod IP is chosen (load balanced across all healthy ones)
      ▼
Container (actual app handling the request)
```

**Why this layered design matters:** the Service's ClusterIP never changes,
but the Pods behind it constantly do (restarts, scaling, rollouts). Endpoints
is the live, auto-updating bridge between the stable Service identity and the
ever-changing set of actual Pod IPs — the application only ever needs to know
the Service name, never any Pod IP directly.

---

## Key Concepts to Remember

- **DNS name format:** `<service-name>.<namespace>.svc.cluster.local` — short
  form `<service-name>` works within the same namespace
- **ClusterIP** = internal only. **NodePort** = exposed on every node's IP.
  **LoadBalancer** = provisions a real cloud LB (superset of NodePort/ClusterIP)
- **ExternalName** = pure DNS alias, no proxying, no ClusterIP at all
- **CNI** is what actually gives Pods real IPs and lets them talk cross-node —
  Kubernetes delegates this, it doesn't implement it natively
- **Empty `Endpoints`** almost always means a selector/label mismatch — check
  this before assuming a networking/DNS problem
- **`/etc/resolv.conf` inside any Pod** shows the cluster DNS server (usually
  `10.96.0.10` or similar) — this is injected automatically, not manually configured