# Horizontal Pod Autoscaler (HPA)

## What HPA Is

HPA is a controller that automatically adjusts a Deployment's replica count
based on observed metrics, most commonly CPU utilization. Instead of running
`kubectl scale` by hand, HPA continuously watches metrics and adjusts
capacity to match real demand.

## Why HPA Is Needed

A fixed replica count is always wrong in one direction:
- Too many replicas for average traffic → wasted cost, idle capacity
- Too few replicas for peak traffic → degraded performance or outages

HPA lets you run lean during normal load and expand automatically the moment
real usage demands it — capacity that tracks demand instead of guessing at
a static number.

## Metrics Server

HPA has no built-in visibility into resource usage — it depends entirely on
Metrics Server, a separate component that collects CPU/memory data from the
kubelet on every node and exposes it via the Kubernetes Metrics API.

```bash
kubectl top pods

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
```

Without Metrics Server, HPA's `TARGETS` column shows `<unknown>` forever and
no scaling decisions can be made.

## CPU-Based Scaling

You set a target utilization percentage. HPA polls current average CPU
across all Pods (every 15s by default) and calculates how many replicas
would bring utilization back to target.

```
desiredReplicas = ceil(currentReplicas x (currentUtilization / targetUtilization))
```

Example: 3 replicas at 80% CPU, target 50% -> ceil(3 x (80/50)) = ceil(4.8) = 5 replicas.

## Min Replicas / Max Replicas

| Setting | Purpose |
|---|---|
| minReplicas | Floor - prevents scaling to zero and losing all capacity |
| maxReplicas | Ceiling - prevents runaway scaling from exhausting cluster capacity or budget |

---

## hpa.yaml (wired to nodejs-deployment)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nodejs-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nodejs-deployment
  minReplicas: 2
  maxReplicas: 6
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60
```

Scale up reacts immediately (stabilizationWindowSeconds: 0) because
under-provisioning during a real spike hurts users. Scale down waits 5
minutes and removes at most 1 Pod at a time, preventing flapping - a Pod
removed right before the next spike, immediately recreated.

---

## Practice: Verify, Create, Observe

### Verify Metrics Server

```bash
kubectl top pods
```

### Create the HPA

```bash
kubectl apply -f kubernetes/hpa.yaml
```

### kubectl get hpa

```bash
kubectl get hpa
```

```
NAME         REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nodejs-hpa   Deployment/nodejs-deployment  12%/50%   2         6         2          30s
```

TARGETS shows current/target - 12%/50% means usage is well under target, so
HPA holds at the minimum replica count.

### kubectl describe hpa

```bash
kubectl describe hpa nodejs-hpa
```

```
Metrics:  ( current / target )
  resource cpu on pods: 12% (24m) / 50%
Min replicas:   2
Max replicas:   6
Deployment pods: 2 current / 2 desired

Events:
  Type    Reason             Age   From                       Message
  ----    ------             ----  ----                       -------
  Normal  SuccessfulRescale  10s   horizontal-pod-autoscaler  New size: 3; reason: cpu resource utilization above target
```

The Events section shows actual scaling decisions - same pattern as
describe pod, the control plane narrates what it did and why.

### Understanding scaling decisions

```bash
kubectl get hpa -w

kubectl run load-generator --image=busybox --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://nodejs-service/; done"
```

Watch TARGETS climb, then REPLICAS increase once it crosses 50%. After
stopping the load generator, REPLICAS holds for 5 minutes before scaling
back down.

```bash
kubectl delete pod load-generator
```

---

## Common Gotchas

| Problem | Symptom | Fix |
|---|---|---|
| Metrics Server missing | TARGETS shows unknown forever | Install Metrics Server |
| HPA never scales | Deployment has no resources.requests.cpu set | Utilization % is calculated against requests - without a request, HPA can't compute it |
| Scaling too aggressively | Replicas oscillate rapidly | Increase stabilizationWindowSeconds on scaleDown |
| scaleTargetRef typo | HPA does nothing, no errors | Confirm name matches the Deployment exactly |
| Load test doesn't trigger scaling | Requests too light to raise CPU | Increase concurrency in the load generator |

---

## Key Takeaways

1. HPA needs Metrics Server - it collects nothing on its own.
2. Utilization percentage is calculated against resources.requests.cpu, not
   limits - a Deployment without requests set can never be scaled by HPA.
3. minReplicas/maxReplicas are safety bounds, not just tuning knobs - they
   protect against both an outage (scale to zero) and runaway cost (scale to
   infinity).
4. Scale up fast, scale down slow - this asymmetry is deliberate, avoiding
   flapping while still protecting users during real spikes.
5. kubectl describe hpa Events section shows the actual scaling decisions
   and their reasons - the same pattern as Pod-level troubleshooting.
