# Kubernetes Learning Notes ☸️

## Imperative Approach

Imperative approach means giving direct commands to Kubernetes.

Example:
kubectl create deployment nginx-deployment --image=nginx

Here, the user manually tells Kubernetes what action to perform.

### Characteristics

* Command-based
* Quick for testing
* Manual process
* Not ideal for large-scale production environments

---

## Declarative Approach

Declarative approach means defining the desired state using YAML files.

Example:
kubectl apply -f deployment.yaml

Here, the user describes the final desired state, and Kubernetes automatically manages the resources to match that state.

### Characteristics

* YAML/configuration-based
* Reusable and version controlled
* Preferred in real-world production systems
* Works well with GitOps and CI/CD pipelines

---

## Difference

Imperative = Tell Kubernetes HOW to do something manually.

Declarative = Tell Kubernetes WHAT final state is needed.

## Self-Healing in Kubernetes

Kubernetes provides self-healing capabilities through Deployments and ReplicaSets.

If a Pod crashes or gets deleted manually, Kubernetes automatically creates a replacement Pod to maintain the desired number of replicas.

Example:
kubectl delete pod <pod-name> -n dev

After deletion, Kubernetes automatically recreates the Pod.

### How Self-Healing Works

Deployment
↓
ReplicaSet monitors desired replicas
↓
Missing Pod detected
↓
New Pod created automatically

---

## Rolling Updates

Rolling updates allow Kubernetes to update application versions gradually without downtime.

Old Pods are replaced with new Pods one by one while keeping the application available to users.

Example:
kubectl set image deployment/nginx-deployment nginx=nginx:1.25 -n dev

### Benefits

* Zero downtime deployments
* Safer production upgrades
* Easy rollback support

---

## Important Understanding

Self-healing handles failures automatically.

Rolling updates handle application upgrades gradually.

## Kubernetes Horizontal Pod Autoscaler (HPA)

### Topics Covered

* Horizontal Pod Autoscaler (HPA)
* Metrics Server
* CPU-based Scaling
* minReplicas and maxReplicas
* Scaling Boundaries
* Deployment vs HPA
* HPA YAML Configuration
* HPA Verification Commands

### Commands Practiced

```bash
kubectl apply -f hpa.yaml

kubectl get hpa

kubectl describe hpa nginx-hpa

kubectl top pods

kubectl top nodes
```

### Key Learning

HPA automatically scales Pod replicas based on CPU or memory utilization while respecting configured scaling boundaries.

