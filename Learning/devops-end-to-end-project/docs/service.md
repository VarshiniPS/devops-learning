# Kubernetes Services

## Objective

Expose Pods using Kubernetes Services and understand Service networking.

---

## Why Services?

Pods are ephemeral.

Pod IPs change when Pods are recreated.

Services provide:

* Stable IP
* Stable DNS Name
* Load Balancing

---

## Service Architecture

User
↓
Service
↓
Pods

---

## Service Types

### ClusterIP

Default Service type.

Accessible only within cluster.

Example:

Backend → Database

---

### NodePort

Exposes application externally.

Access format:

<NodeIP>:<NodePort>

Example:

localhost:30080

---

### LoadBalancer

Creates cloud load balancer.

Provides public IP.

Used in production environments.

---

## Example Service YAML

```yaml id="fz2n7j"
apiVersion: v1
kind: Service
metadata:
  name: nodejs-service

spec:
  selector:
    app: nodejs-app

  ports:
  - port: 80
    targetPort: 3000

  type: NodePort
```

---

## Useful Commands

Apply:

```bash id="5a5v0r"
kubectl apply -f service.yaml
```

List Services:

```bash id="dwhgqj"
kubectl get svc
```

Describe Service:

```bash id="5xytad"
kubectl describe svc nodejs-service
```

Delete Service:

```bash id="8yy37d"
kubectl delete -f service.yaml
```

---

## Interview Questions

### Why do we need Services?

Pods are ephemeral and their IPs change.

Services provide stable networking.

---

### Difference between ClusterIP, NodePort, and LoadBalancer?

ClusterIP:

* Internal communication

NodePort:

* External access using Node IP and Port

LoadBalancer:

* Internet-facing cloud load balancer

---

### Can Ingress directly route to Pods?

No.

Ingress → Service → Pods

---

## Learning Outcome

Understood Kubernetes Service networking and Service Types.
