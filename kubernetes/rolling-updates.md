# Kubernetes Rolling Updates ☸️

## What is a Rolling Update?

Rolling update is a Kubernetes deployment strategy used to update application versions gradually without downtime.

Kubernetes slowly replaces old Pods with new Pods while keeping the application available.

---

## Check Deployment

kubectl get deployment nginx-deployment -n dev

Displays deployment status inside the dev namespace.

---

## Update Deployment Image

kubectl set image deployment/nginx-deployment nginx=nginx:1.25 -n dev

Updates the container image version for the deployment.

---

## Check Rollout Status

kubectl rollout status deployment/nginx-deployment -n dev

Displays rollout/update progress.

---

## View Rollout History

kubectl rollout history deployment/nginx-deployment -n dev

Displays deployment revision history.

---

## Important Observations

* Kubernetes updates Pods gradually.
* Application remains available during updates.
* Old Pods are terminated one by one.
* New Pods are created automatically.
* Rolling updates help avoid downtime in production environments.

---

## Real-World Importance

Rolling updates are widely used in production systems because applications can be upgraded safely without stopping user traffic.
