# Kubernetes Services

**Goal:** Understand how users access Pods

---

## Why Services Exist

Pods are ephemeral — they restart, get rescheduled, and their IPs change. A **Service** provides a stable, persistent endpoint that routes traffic to the right Pods using **label selectors**.

---

## Service Types

| Type | Accessible From | Use Case |
|------|----------------|----------|
| `ClusterIP` | Inside cluster only | Internal pod-to-pod communication |
| `NodePort` | Outside cluster via Node IP | Development / testing |
| `LoadBalancer` | Internet (cloud LB) | Production external traffic |

---

## ClusterIP

- Default service type
- Assigns a virtual IP only reachable within the cluster
- Traffic flow: `Client Pod → ClusterIP:port → Target Pod:targetPort`

```yaml
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 8080
```

---

## NodePort

- Opens a port on **every Node** in the cluster
- Traffic flow: `External Client → NodeIP:nodePort → ClusterIP → Pod`
- Port range: `30000–32767`

```yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 8080
      nodePort: 30080
```

Access via: `http://<NodeIP>:30080`

---

## LoadBalancer

- Provisions a cloud load balancer automatically (AWS ELB, GCP LB, etc.)
- Traffic flow: `Internet → LoadBalancer IP → NodePort → ClusterIP → Pod`
- Superset of NodePort + ClusterIP

```yaml
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
```

---

## Key Field: `selector`

Services find Pods via labels. The `selector` must match the labels on your Deployment's Pod template:

```yaml
# In Service:
selector:
  app: my-app

# In Deployment (pod template):
labels:
  app: my-app
```

---

## Commands

```bash
# Apply the service
kubectl apply -f service.yaml

# Check services
kubectl get services
kubectl get svc

# Describe a service (see endpoints, selector, ports)
kubectl describe svc my-app-clusterip

# Check which Pods the service is routing to
kubectl get endpoints my-app-clusterip

# Test ClusterIP from inside the cluster
kubectl run test --image=busybox --rm -it -- wget -qO- http://my-app-clusterip
```

---

## Mental Model

```
Internet
   │
   ▼
LoadBalancer (external IP)
   │
   ▼
NodePort (NodeIP:30080)
   │
   ▼
ClusterIP (internal virtual IP)
   │
   ▼
Pod(s) matching selector
```

Each type builds on the one below it.

---

## Summary

- Services decouple access from individual Pod IPs
- Use **ClusterIP** for internal services
- Use **NodePort** for quick external access in dev
- Use **LoadBalancer** for production on cloud providers
- The `selector` field is what connects a Service to its Pods
