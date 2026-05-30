# Kubernetes Scaling and Self-Healing ☸️

## Scaling Deployments

Scaling allows Kubernetes to increase or decrease the number of application Pods.

Example:

kubectl scale deployment nginx-deployment --replicas=5 -n dev

This updates the desired replica count to 5.

---

## Verify Scaling

kubectl get pods -n dev

Displays all Pods running in the dev namespace.

After scaling, Kubernetes automatically creates additional Pods until the desired count is reached.

---

## Self-Healing

Kubernetes continuously maintains the desired state defined in the Deployment.

Example:

kubectl delete pod <pod-name> -n dev

When a Pod is deleted:

1. ReplicaSet detects that a Pod is missing.
2. Desired state no longer matches actual state.
3. Kubernetes automatically creates a replacement Pod.
4. Desired replica count is restored.

---

## Observation

Desired Pods: 5

One Pod Deleted

↓

ReplicaSet detects missing Pod

↓

New Pod created automatically

↓

Pod count returns to 5

---

## Benefits

* Automatic recovery from failures
* Reduced manual intervention
* Higher application availability
* Improved reliability

---

## Key Learning

Scaling changes the number of Pods.

Self-healing ensures the required number of Pods always exist.
