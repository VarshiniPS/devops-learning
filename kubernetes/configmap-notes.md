# Kubernetes ConfigMaps ☸️

## What is a ConfigMap?

ConfigMap is a Kubernetes resource used to store application configuration separately from application code.

---

## Why ConfigMaps Are Needed

Applications often require configuration values such as:

* Environment names
* API URLs
* Database endpoints
* Feature flags

Keeping configuration separate makes applications more flexible and reusable.

---

## Example ConfigMap YAML

apiVersion: v1
kind: ConfigMap

metadata:
name: app-config

data:
APP_ENV: development
APP_NAME: myapp

---

## Environment Variables

ConfigMaps are commonly used to provide environment variables to Pods.

Example:
APP_ENV=development

---

## Benefits

* Separates config from application code
* Easier environment management
* Reusable across environments
* No need to rebuild container image for config changes

---

## ConfigMap vs Secret

ConfigMap:

* Stores normal configuration data

Secret:

* Stores sensitive information such as passwords, API keys, and tokens

---

## Real-World Usage

Different environments can use different configurations:

Development → dev database
Production → production database

Same application image can be reused with different ConfigMaps.
