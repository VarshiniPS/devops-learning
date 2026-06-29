# Kubernetes Ingress — Project Notes

## What This File Covers

- What Ingress is and why it exists
- The two required components
- Our `ingress.yaml` broken down line by line
- Internet → Pods traffic flow (6 steps)
- Path-based vs host-based routing
- TLS setup
- Full kubectl audit command reference
- Common gotchas

---

## Why Ingress

Without Ingress, every HTTP service needs its own LoadBalancer Service —
one cloud load balancer per service. On AWS that means one ELB per service:
slow to provision, expensive, and hard to manage at scale.

Ingress gives the entire cluster **one external entry point**. Routing rules
inside the Ingress resource dispatch traffic to the right ClusterIP Service
based on URL path or hostname.

```
Without Ingress             With Ingress
──────────────              ────────────
ELB ──▶ app-svc             ELB ──▶ Ingress Controller
ELB ──▶ api-svc                       ├── /    ──▶ app-svc
ELB ──▶ admin-svc                     ├── /api ──▶ api-svc
(3 cloud LBs, 3 IPs)                  └── /admin──▶ admin-svc
                                      (1 cloud LB, 1 IP)
```

---

## Two Required Components

Ingress is always two separate things — both must exist:

| Component | What it is | What it does |
|---|---|---|
| **Ingress resource** | A YAML object (`kind: Ingress`) | Declares routing rules — stored in the cluster |
| **Ingress Controller** | A running Pod (nginx, Traefik, ALB) | Reads the rules and actually routes traffic |

> The Ingress resource does nothing without a Controller. The Controller does
> nothing without rules.

---

## Our ingress.yaml — Line by Line

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: devops-node-app-ingress
  namespace: default
```

Standard metadata. Namespace must match the Services it routes to.

```yaml
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/limit-rps: "100"
```

Annotations configure the Controller's behaviour per-Ingress:
- `ingress.class` — tells which Controller to handle this resource
- `rewrite-target` — strips path prefix before forwarding to the Service
- `ssl-redirect` — forces HTTP → HTTPS
- `limit-rps` — rate limits to 100 req/s per client IP

```yaml
spec:
  ingressClassName: nginx
```

Preferred over the annotation in Kubernetes 1.18+. Both do the same thing.

```yaml
  tls:
    - hosts:
        - devops-node-app.example.com
      secretName: devops-node-app-tls
```

TLS block tells the Controller where to find the cert and key.
The Secret must be created before applying the Ingress:

```bash
# Manual cert
kubectl create secret tls devops-node-app-tls \
  --cert=tls.crt --key=tls.key

# Or use cert-manager (auto-renewing Let's Encrypt)
kubectl annotate ingress devops-node-app-ingress \
  cert-manager.io/cluster-issuer=letsencrypt-prod
```

```yaml
  rules:
    - host: devops-node-app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: devops-node-app-clusterip
                port:
                  number: 80
```

One rule per host. Each host has one or more path entries. `Prefix` matches
the path and all sub-paths. `Exact` matches only the exact string.

---

## Internet → Pods: 6-Step Flow

```
① Browser: GET https://devops-node-app.example.com/api
      ↓  DNS resolves to external IP
② LoadBalancer Service
      External IP · port 443 → Ingress Controller Pod
      ↓
③ Ingress Controller (nginx Pod)
      Terminates TLS (decrypts HTTPS)
      Reads Ingress rules
      ↓
④ Path matching: /api → Prefix match
      Routes to devops-node-app-clusterip:80
      ↓
⑤ ClusterIP Service
      Virtual IP · selector: app=devops-node-app
      Load balances across healthy Pod endpoints
      ↓
⑥ Pod (containerPort 3000)
      app.js handles GET /api
      Response flows back up the chain
```

Key insight: the Ingress Controller is itself a Pod with its own LoadBalancer
Service in front of it. That's the only cloud LB the entire cluster needs.

---

## Path Types

| pathType | Behaviour | Example |
|---|---|---|
| `Prefix` | Matches path and all sub-paths | `/api` matches `/api`, `/api/users`, `/api/v2/items` |
| `Exact` | Matches only this exact string | `/health` matches `/health` only — not `/health/live` |
| `ImplementationSpecific` | Controller decides | Varies by controller |

Use `Prefix` for application routes. Use `Exact` for specific endpoints
like `/health` where you don't want sub-paths matched.

---

## Path-Based vs Host-Based Routing

### Path-based (one host, split by URL)

```yaml
host: devops-node-app.example.com
paths:
  - path: /          → app-service
  - path: /api       → api-service
  - path: /admin     → admin-service
```

### Host-based (multiple subdomains, each to a different service)

```yaml
rules:
  - host: app.example.com
    paths: [/ → app-service]
  - host: api.example.com
    paths: [/ → api-service]
  - host: admin.example.com
    paths: [/ → admin-service]
```

Both can be combined in the same Ingress resource. Host-based is cleaner
for microservices that need separate domains.

---

## Install the Ingress Controller

### minikube

```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx     # wait for controller to be Running
```

### kind (local cluster)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/\
controller-v1.9.4/deploy/static/provider/kind/deploy.yaml
```

### EKS (AWS Load Balancer Controller)

```bash
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

---

## Apply and Audit Commands

### Apply

```bash
# Apply just the Ingress
kubectl apply -f kubernetes/ingress.yaml

# Apply all three K8s files together
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml
```

### Get — quick status

```bash
kubectl get ingress
```

```
NAME                      CLASS   HOSTS                          ADDRESS         PORTS     AGE
devops-node-app-ingress   nginx   devops-node-app.example.com   34.120.45.11    80, 443   2m
```

What to check:
- `ADDRESS` — the external IP. Blank means the LB hasn't provisioned yet (wait 30–60s on cloud)
- `PORTS` — `80, 443` confirms TLS is configured
- `CLASS` — confirms the right controller picked it up

### Describe — full detail

```bash
kubectl describe ingress devops-node-app-ingress
```

```
Name:             devops-node-app-ingress
Namespace:        default
Address:          34.120.45.11
Ingress Class:    nginx
TLS:              devops-node-app-tls terminates devops-node-app.example.com
Rules:
  Host                          Path     Backends
  ----                          ----     --------
  devops-node-app.example.com
                                /        devops-node-app-clusterip:80 (10.244.0.5:3000,10.244.0.6:3000)
                                /health  devops-node-app-clusterip:80 (10.244.0.5:3000,10.244.0.6:3000)
                                /api     devops-node-app-clusterip:80 (10.244.0.5:3000,10.244.0.6:3000)
```

What to check:
- **Backends with IPs** — Pod endpoints listed in parentheses = wiring is correct
- **Backends `<none>`** — Service selector doesn't match any running Pods
- **TLS line** — confirms the Secret was found

### Check Ingress Controller logs

```bash
# Find controller pod name
kubectl get pods -n ingress-nginx

# Stream logs
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller -f
```

Look for `200`, `301`, `404` lines — these are real requests being processed.

### Test locally without DNS

```bash
# Add to /etc/hosts (Mac/Linux)
echo "34.120.45.11 devops-node-app.example.com" | sudo tee -a /etc/hosts

# Test
curl https://devops-node-app.example.com/health
curl https://devops-node-app.example.com/api

# Or use curl -H to bypass DNS entirely
curl -H "Host: devops-node-app.example.com" http://34.120.45.11/health
```

### Full audit sequence

```bash
# 1. Confirm Ingress Controller is running
kubectl get pods -n ingress-nginx

# 2. Apply resources
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml

# 3. Check all resources
kubectl get deployment devops-node-app
kubectl get svc
kubectl get ingress

# 4. Wait for external IP
kubectl get ingress -w    # -w watches for changes

# 5. Describe for deep audit
kubectl describe ingress devops-node-app-ingress

# 6. Check Pod endpoints are wired
kubectl get endpoints devops-node-app-clusterip

# 7. Test the route
curl -H "Host: devops-node-app.example.com" http://<ADDRESS>/health
```

---

## Common Gotchas

| Problem | Symptom | Fix |
|---|---|---|
| No Controller installed | `ADDRESS` blank forever | Install nginx controller or enable minikube addon |
| Wrong `ingressClassName` | Rules silently ignored | Match class to installed controller (`nginx`, `alb`) |
| TLS Secret missing | HTTPS fails, 404 on port 443 | Create Secret before applying Ingress |
| `rewrite-target` missing | 404 on sub-paths | Add `nginx.ingress.kubernetes.io/rewrite-target: /` |
| `Backends: <none>` | 503 Service Unavailable | Service selector doesn't match Pod labels |
| DNS not pointing to ADDRESS | `curl` works by IP, not hostname | Add to `/etc/hosts` for local testing |
| pathType `Prefix` too broad | Wrong service gets traffic | Use `Exact` for specific routes like `/health` |

---

## Key Takeaways

1. Ingress = one external IP for all HTTP/HTTPS services. One cloud LB, not many.
2. Two parts always required: **Ingress resource** (rules) + **Ingress Controller** (enforcement).
3. `ADDRESS` blank = Controller not installed or LB not provisioned yet.
4. `Backends: <none>` = Service selector doesn't match any running Pod — check labels.
5. `pathType: Prefix` matches path and all sub-paths. `Exact` matches only that string.
6. TLS Secret must exist before applying the Ingress — create it first.
7. Use `curl -H "Host: ..."` to test routing before DNS is configured.
