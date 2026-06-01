# Kubernetes Pod Commands

## Create Pod

kubectl run nginx-pod --image=nginx

Creates a Pod named nginx-pod using the nginx image.

---

## View Pods

kubectl get pods

Displays all running Pods.

---

## Describe Pod

kubectl describe pod nginx-pod

Shows detailed information about the Pod including events, status, image, and node details.

---

## Delete Pod

kubectl delete pod nginx-pod

Deletes the Pod.

---

## Observations

* Pod status becomes Running after successful creation.
* Pods are temporary resources.
* When manually deleted, the Pod is not recreated automatically because no Deployment or ReplicaSet manages it.
* kubectl is used to communicate with the Kubernetes cluster.
