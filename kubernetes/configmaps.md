# Kubernetes ConfigMaps ☸️

## What is a ConfigMap?

A ConfigMap stores application configuration separately from application code.

This helps applications remain reusable across different environments.

---

## Create ConfigMap

kubectl create configmap app-config --from-literal=ENV=dev

Creates a ConfigMap named app-config containing:

ENV=dev

---

## View ConfigMaps

kubectl get configmaps

Displays available ConfigMaps in the namespace.

---

## Describe ConfigMap

kubectl describe configmap app-config

Displays detailed information including stored key/value pairs.

---

## Example

ConfigMap Name:
app-config

Data:
ENV=dev

---

## Benefits

* Separates configuration from code
* Easier environment management
* Reusable application images
* No need to rebuild image for config changes

---

## Real-World Usage

Common values stored in ConfigMaps:

* Environment names
* API URLs
* Application settings
* Feature flags

Applications read these values at runtime.
