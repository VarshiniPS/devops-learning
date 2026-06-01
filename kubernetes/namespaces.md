# Kubernetes Namespaces ☸️

## What is a Namespace?

Namespace is a logical separation inside a Kubernetes cluster used to organize and isolate resources.

---

## View Namespaces

kubectl get namespaces

Displays all namespaces in the cluster.

---

## Create Namespace

kubectl create namespace dev

Creates a new namespace called dev.

---

## Create Deployment Inside Namespace

kubectl create deployment nginx-deployment --image=nginx -n dev

Creates deployment inside the dev namespace.

---

## View Pods in Namespace

kubectl get pods -n dev

Displays Pods running inside the dev namespace.

---

## Important Observations

* Namespaces help organize resources.
* Multiple teams/applications can share one Kubernetes cluster safely.
* Resources inside one namespace are isolated from others.
* By default, kubectl commands use the default namespace.
* Namespace-specific resources require -n <namespace> option.

---

## Example

default/nginx-deployment

dev/nginx-deployment

Both deployments can exist without conflict because they belong to different namespaces.
