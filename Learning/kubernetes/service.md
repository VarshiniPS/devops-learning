# Kubernetes Services

## Why Services Exist

Pods are **ephemeral** — they restart constantly and get a new IP each time.
A Service provides a **stable virtual IP + DNS name** that never changes, and
automatically routes traffic to whatever healthy Pods are currently running.

> Rule: Never access a Pod directly by IP. Always go through a Service.

---

## Service Types

| Type | Accessible From | Use Case |
|---|---|---|
| `ClusterIP` | Inside cluster only | Microservice-to-microservice communication |
| `NodePort` | Outside via `<NodeIP>:<Port>` | Dev/testing, bare-metal clusters |
| `LoadBalancer` | Public internet (cloud only) | Production external traffic |

---

## Traffic Flow

```
User → LoadBalancer → NodePort → ClusterIP → Pod(s)
```

Each type **builds on** the one below it. LoadBalancer wraps NodePort, which
wraps ClusterIP.

---

## service.yaml — ClusterIP Example

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  namespace: default
  labels:
    app: my-app
spec:
  type: ClusterIP          # Default — internal only
  selector:
    app: my-app            # Targets Pods with label app=my-app
  ports:
    - name: http
      protocol: TCP
      port: 80             # Port the Service exposes
      targetPort: 8080     # Port the container listens on
```

Key fields:
- **`selector`** — how the Service finds its Pods (label matching, not IP)
- **`port`** — what callers use to reach the Service
- **`targetPort`** — what the container inside the Pod is actually listening on

---

## Essential kubectl Commands

```bash
# Apply the Service definition
kubectl apply -f service.yaml

# List all services in default namespace
kubectl get svc

# Detailed info: endpoints, selector, events
kubectl describe svc my-app-service

# Get the ClusterIP assigned to the service
kubectl get svc my-app-service -o wide

# Watch services live
kubectl get svc -w

# Delete the service
kubectl delete -f service.yaml
```

### What to look for in `kubectl get svc`

```
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
my-app-service   ClusterIP   10.96.142.201   <none>        80/TCP    5s
```

- `CLUSTER-IP` — the stable virtual IP assigned by Kubernetes
- `EXTERNAL-IP` — `<none>` for ClusterIP (expected), a real IP for LoadBalancer
- `PORT(S)` — `80/TCP` means port 80 is exposed internally

### What to look for in `kubectl describe svc`

```
Name:              my-app-service
Selector:          app=my-app
Type:              ClusterIP
IP:                10.96.142.201
Port:              http  80/TCP
TargetPort:        8080/TCP
Endpoints:         10.244.0.5:8080,10.244.0.6:8080   ← healthy Pod IPs
```

- **`Endpoints`** — lists the actual Pod IPs currently backing the Service.
  If this is `<none>`, the selector doesn't match any running Pods — check your labels.

---

## How the Selector Works

The Service uses `selector: app: my-app` to find Pods.
A Pod must have the matching label in its metadata:

```yaml
# Pod must have this label for the Service to route to it
metadata:
  labels:
    app: my-app   # ← must match Service selector exactly
```

When a Pod with this label starts → automatically added to Endpoints.
When it dies → automatically removed. No manual configuration needed.

---

## Common Gotchas

| Problem | Symptom | Fix |
|---|---|---|
| Selector mismatch | `Endpoints: <none>` | Check `kubectl get pods --show-labels` |
| Wrong targetPort | Connection refused | Match targetPort to container's `containerPort` |
| ClusterIP from outside | Can't connect | Use NodePort or kubectl port-forward |
| Missing namespace | Service not found | Add `-n <namespace>` to kubectl commands |

### Quick debug: test a ClusterIP from inside the cluster

```bash
# Spin up a temporary pod and curl the service
kubectl run tmp --image=curlimages/curl --restart=Never --rm -it \
  -- curl http://my-app-service:80
```

---

## Port-Forward for Local Testing

ClusterIP is not reachable from your laptop — use port-forward:

```bash
kubectl port-forward svc/my-app-service 8080:80
# Now open http://localhost:8080 in your browser
```

---

## Key Takeaways

1. Services decouple callers from Pod lifecycles — Pods can die and restart freely.
2. `ClusterIP` is the default and most common type — use it for all internal traffic.
3. The `selector` is the glue between a Service and its Pods.
4. `Endpoints` in `kubectl describe` tells you if the wiring is working.
5. Always check `Endpoints: <none>` first when a Service isn't routing traffic.