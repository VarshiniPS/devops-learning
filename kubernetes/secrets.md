# Kubernetes Secrets ☸️

## What is a Secret?

A Secret is a Kubernetes resource used to store sensitive information securely.

Examples include:

* Passwords
* API keys
* Tokens
* Certificates

---

## Create Secret

kubectl create secret generic db-secret --from-literal=password=mysecret

Creates a Secret named db-secret containing:

password=mysecret

---

## View Secrets

kubectl get secrets

Displays available Secrets in the namespace.

---

## Describe Secret

kubectl describe secret db-secret

Displays Secret metadata and stored key names.

Example output:

password: 8 bytes

The actual value is not displayed.

---

## ConfigMap vs Secret

ConfigMap:

* Stores non-sensitive configuration
* Environment variables
* Application settings

Secret:

* Stores sensitive data
* Passwords
* API keys
* Authentication tokens

---

## Benefits

* Keeps sensitive information separate from application code
* Improves security
* Supports secure application configuration
* Integrates with Pods through environment variables or mounted files

---

## Real-World Usage

Common Secret data includes:

* Database passwords
* API credentials
* Cloud access keys
* TLS certificates

Applications retrieve Secrets at runtime instead of hardcoding credentials.
