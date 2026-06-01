# Kubernetes Debugging ☸️

## Why Debugging is Important

Kubernetes applications may fail due to container crashes, configuration issues, networking problems, or image errors.

Debugging helps identify and resolve these problems.

---

## Get Pod Names

kubectl get pods -n dev

Displays running Pods in the dev namespace.

---

## View Pod Logs

kubectl logs <pod-name> -n dev

Displays application logs from the Pod.

Logs help identify:

* Errors
* Startup failures
* Warnings
* Application output

---

## Describe Pod

kubectl describe pod <pod-name> -n dev

Displays detailed Pod information including:

* Events
* Image details
* Restart count
* Pod status
* Node information

---

## Enter Container

kubectl exec -it <pod-name> -n dev -- /bin/bash

Opens interactive shell inside the container.

If bash is unavailable:
kubectl exec -it <pod-name> -n dev -- /bin/sh

---

## Common Debugging Steps

1. Check Pod status
2. Check logs
3. Describe Pod
4. Enter container
5. Investigate files/processes/configuration

---

## Important Observations

* Logs are essential for troubleshooting.
* describe provides Kubernetes-level details.
* exec allows direct container inspection.
* Debugging is a critical DevOps and Kubernetes skill.
