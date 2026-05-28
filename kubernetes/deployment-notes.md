# Kubernetes Deployment Notes

## Create Deployment

kubectl create deployment nginx-deployment --image=nginx

Creates a Deployment running the nginx image.

---

## View Deployments

kubectl get deployments

Displays all Deployments.

---

## View ReplicaSets

kubectl get replicasets

Displays ReplicaSets created by Deployments.

---

## View Pods

kubectl get pods

Displays running Pods.

---

## Scale Deployment

kubectl scale deployment nginx-deployment --replicas=3

Scales the Deployment to 3 Pods.

---

## Observations

* Deployment automatically creates ReplicaSet and Pods.
* ReplicaSet ensures the desired number of Pods are always running.
* Scaling increases the number of running Pods automatically.
* If a Pod crashes or is deleted, Kubernetes recreates it automatically.
* Deployments provide self-healing and scalability.
