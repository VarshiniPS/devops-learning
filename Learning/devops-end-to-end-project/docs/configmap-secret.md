# ConfigMap & Secret

**Session:** 6:45 - 8:00 PM | Project Hands-On
**Goal:** Externalize configuration and sensitive values from the container image

---

## Why This Matters

Hardcoding config (URLs, ports, feature flags) or secrets (passwords, API keys)
directly into a Docker image or app code means:
- Rebuilding the image every time a value changes
- Secrets sitting in plain text in version control

Kubernetes solves this with two objects:

| Object | Use for | Encoding |
|---|---|---|
| **ConfigMap** | Non-sensitive config (env, ports, flags) | Plain text |
| **Secret** | Sensitive values (passwords, keys, tokens) | Base64 (not encryption!) |

> ⚠️ **Base64 is encoding, not encryption.** Anyone with `kubectl get secret -o yaml`
> access can decode it instantly. Real protection comes from RBAC restricting who
> can read Secrets, and ideally a proper secrets manager (AWS Secrets Manager,
> HashiCorp Vault) for production.

---

## ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: node-app-config
data:
  NODE_ENV: "production"
  PORT: "3000"
  LOG_LEVEL: "info"
  APP_NAME: "node-app"
```

Apply it:
```bash
kubectl apply -f configmap.yaml
```

---

## Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: node-app-secret
type: Opaque
data:
  DB_PASSWORD: c3VwZXJzZWNyZXRwYXNzd29yZA==
  API_KEY: bXlzZWNyZXRhcGlrZXkxMjM=
```

**Encoding a value before adding it:**
```bash
echo -n 'supersecretpassword' | base64
# c3VwZXJzZWNyZXRwYXNzd29yZA==
```

**Decoding to verify:**
```bash
echo 'c3VwZXJzZWNyZXRwYXNzd29yZA==' | base64 --decode
# supersecretpassword
```

Apply it:
```bash
kubectl apply -f secret.yaml
```

---

## Consuming Both in the Deployment

Two ways to pull values into a container:

### 1. `envFrom` — inject *all* keys at once
```yaml
envFrom:
  - configMapRef:
      name: node-app-config
  - secretRef:
      name: node-app-secret
```
Every key in the ConfigMap/Secret becomes an environment variable automatically.
Fast, but less explicit about exactly what the app depends on.

### 2. `env` + `valueFrom` — reference a specific key
```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: node-app-secret
        key: DB_PASSWORD
```
More verbose, but explicit — useful when you want to rename a key or only pull
in one or two specific values rather than everything.

**This project uses both**: `envFrom` for convenience, plus one explicit `env`
entry for `DB_PASSWORD` to show the pattern.

---

## Full Command Sequence

```bash
# 1. Apply the ConfigMap
kubectl apply -f configmap.yaml

# 2. Apply the Secret
kubectl apply -f secret.yaml

# 3. Apply the updated Deployment (references both)
kubectl apply -f deployment.yaml

# 4. Force Pods to pick up the new config
#    (Pods don't auto-restart when a ConfigMap/Secret changes)
kubectl rollout restart deployment nodejs-deployment

# 5. Watch the rollout complete
kubectl rollout status deployment/nodejs-deployment

# 6. Verify env vars actually landed in the Pod
kubectl describe pod <pod-name>
# Look under Containers > node-app > Environment Variables from:
```

---

## Verifying Values Inside a Running Pod

```bash
# Shell into a pod and check env vars directly
kubectl exec -it <pod-name> -- printenv | grep -E "NODE_ENV|PORT|DB_PASSWORD"
```

You should see the ConfigMap and Secret values present as plain environment
variables inside the container (Kubernetes decodes the Secret automatically
before injecting it — your app never has to base64-decode anything itself).

---

## Important: ConfigMap/Secret Changes Don't Auto-Restart Pods

If you edit a ConfigMap or Secret and just re-apply it, **already-running Pods
keep their old environment variables** — env vars are only set at container
start time. This is exactly why `kubectl rollout restart` is a required step,
not optional — it forces new Pods to spin up and pick up the latest values.

```bash
kubectl apply -f configmap.yaml          # updates the ConfigMap object
kubectl rollout restart deployment nodejs-deployment   # forces Pods to reload it
```

---

## Key Concepts to Remember

- **ConfigMap** = plain-text config, safe to commit to Git
- **Secret** = base64-encoded sensitive values — encoding, not encryption; never commit real secrets to Git
- **`envFrom`** injects everything; **`env` + `valueFrom`** is explicit per-key
- Editing a ConfigMap/Secret alone does **not** restart Pods — always follow with `kubectl rollout restart`
- `kubectl describe pod` is the fastest way to confirm which env vars a Pod actually received
