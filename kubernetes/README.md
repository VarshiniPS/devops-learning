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
