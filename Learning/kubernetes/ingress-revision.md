# Kubernetes Ingress

## Why Ingress Exists

Without Ingress, every Service that needs external traffic gets its own LoadBalancer
— which means one cloud load balancer (and one external IP) per service. That's slow
to provision and expensive.

Ingress gives you **one entry point** for all external HTTP/HTTPS traffic, with routing
rules that dispatch to the right Service based on hostname or URL path.

> Rule: Services handle pod-level load balancing. Ingress handles external HTTP routing.

---

## Ingress vs Service — Key Differences

| | Service (LoadBalancer) | Ingress |
|---|---|---|
| Entry point | One per Service | One for all Services |
| Protocol | Any (TCP/UDP) | HTTP / HTTPS only |
| Routing | By port only | By path or hostname |
| TLS termination | No | Yes |
| Cost | One LB per service | One LB total |

**When to use what:**
- Internal traffic between services → `ClusterIP` (no Ingress needed)
- Non-HTTP external traffic (databases, gRPC raw, etc.) → `LoadBalancer` or `NodePort`
- HTTP/HTTPS external traffic → Ingress

---

## Two Things You Always Need

Ingress is made of two separate parts. Both must exist:

**1. Ingress Controller** — a Pod (usually nginx or Traefik) that runs inside the cluster
and actually processes traffic. It watches the API server for Ingress resources and
reconfigures its routing accordingly.

**2. Ingress resource** — a YAML object that declares your routing rules. It does nothing
on its own; the Controller reads it and acts on it.

> Analogy: the Ingress resource is the routing table. The Ingress Controller is the
> router that reads and enforces it.

---

## Full Traffic Flow

```
Internet
    ↓
LoadBalancer Service        ← cloud LB, single external IP, port 80/443
    ↓
Ingress Controller Pod      ← nginx/traefik, reads Ingress rules
    ↓  (matches host/path)
ClusterIP Service           ← stable internal virtual IP
    ↓
Pod(s)                      ← actual containers serving the response
```

The Ingress Controller itself is exposed via its own `LoadBalancer` or `NodePort` Service
— that's the only "door" into the cluster.

---

## Path-Based Routing

One hostname, different paths go to different Services.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: myapp.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-svc
                port:
                  number: 80
          - path: /app
            pathType: Prefix
            backend:
              service:
                name: app-svc
                port:
                  number: 3000
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-svc
                port:
                  number: 8080
```

Routing result:
- `myapp.com/` → `frontend-svc:80`
- `myapp.com/app` → `app-svc:3000`
- `myapp.com/api` → `api-svc:8080`

---

## Host-Based Routing

Different hostnames go to entirely different Services. Each host is its own rule block.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: app.myco.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-service
                port:
                  number: 80
    - host: api.myco.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 8080
```

Routing result:
- `app.myco.com` → `app-service:80`
- `api.myco.com` → `api-service:8080`

---

## TLS / HTTPS

Add a `tls` block and reference a Secret containing your cert and key.

```yaml
spec:
  tls:
    - hosts:
        - myapp.com
      secretName: myapp-tls-secret   # kubectl create secret tls myapp-tls-secret ...
  rules:
    - host: myapp.com
      ...
```

In practice, use **cert-manager** to auto-provision and renew Let's Encrypt certs rather
than managing the Secret manually.

---

## pathType Values

| Value | Behaviour |
|---|---|
| `Prefix` | Matches the path and all sub-paths (`/api` matches `/api/users`) |
| `Exact` | Matches only the exact path string |
| `ImplementationSpecific` | Behaviour depends on the Ingress Controller |

`Prefix` is the most common. Use `Exact` when you need to lock down a specific endpoint.

---

## Essential kubectl Commands

```bash
# Apply an Ingress
kubectl apply -f ingress.yaml

# List all Ingresses
kubectl get ingress

# Detailed view — shows rules and ADDRESS
kubectl describe ingress path-ingress

# Check Ingress Controller pods are running
kubectl get pods -n ingress-nginx

# Get logs from the Ingress Controller (nginx example)
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller

# Test routing locally (no DNS needed)
curl -H "Host: myapp.com" http://<EXTERNAL-IP>/api
```

### What to look for in `kubectl get ingress`

```
NAME           CLASS   HOSTS        ADDRESS         PORTS   AGE
path-ingress   nginx   myapp.com    34.120.45.11    80      2m
```

- `ADDRESS` — the external IP. If blank, the LoadBalancer Service for the controller
  hasn't got an IP yet (usually takes 30–60s on cloud).
- `PORTS` — `80, 443` once TLS is configured.

### What to look for in `kubectl describe ingress`

```
Rules:
  Host        Path    Backends
  ----        ----    --------
  myapp.com   /       frontend-svc:80   (10.244.0.5:80)
              /app    app-svc:3000      (10.244.0.6:3000)
              /api    api-svc:8080      (10.244.0.7:8080)
```

Endpoints listed in parentheses confirm the backend Services have healthy Pods. If you
see `<none>` there, the Service selector isn't matching any Pods.

---

## Popular Ingress Controllers

| Controller | Notes |
|---|---|
| **nginx** (`ingress-nginx`) | Most common, stable, rich annotation support |
| **Traefik** | Good for dynamic config, popular in dev environments |
| **AWS ALB** | Native on EKS, integrates with AWS ACM for certs |
| **GKE Ingress** | Native on GKE, backed by Google Cloud LB |

Install nginx controller on a local cluster (minikube/kind):

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# minikube shortcut
minikube addons enable ingress
```

---

## Common Gotchas

| Problem | Symptom | Fix |
|---|---|---|
| No Ingress Controller installed | `ADDRESS` stays blank | Install nginx/traefik controller |
| Missing `ingressClassName` | Rules ignored silently | Add `ingressClassName: nginx` |
| `pathType: Exact` too strict | `/api` works, `/api/users` returns 404 | Switch to `Prefix` |
| Backend Service wrong port | 502 Bad Gateway | Match `port.number` to Service's `port` field |
| TLS Secret missing | HTTPS fails | Create Secret before applying TLS block |
| DNS not pointing to ADDRESS | `curl` works by IP, not hostname | Update DNS A record or use `/etc/hosts` for testing |

### Quick local test without DNS

```bash
echo "34.120.45.11 myapp.com" | sudo tee -a /etc/hosts
curl http://myapp.com/api
```

---

## Key Takeaways

1. Ingress = **one external IP, many services** — far cheaper than one LoadBalancer each.
2. The **Ingress Controller** (Pod) is the actual proxy. The **Ingress resource** (YAML) is just the rules.
3. Path-based: same host, different paths → different services.
4. Host-based: different hostnames → different services.
5. Always check `kubectl describe ingress` — the `Backends` section shows whether your Services and Pods are actually reachable.
6. `ADDRESS` blank = controller not running or LB not provisioned yet.
