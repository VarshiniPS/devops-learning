# Helm Basics

## What Helm Is

Helm is the package manager for Kubernetes. A real application needs a Deployment,
Service, Ingress, ConfigMap, Secret, and HPA — all referencing the same app name,
image tag, and replica count. Managing these as individual YAML files means editing
the same values in multiple places and re-applying them one by one.

Helm packages all of that into one versioned, templated unit called a Chart, with
a single command to install, upgrade, or rollback the entire application.

> One sentence: Helm = Kubernetes YAML + templating + versioned releases.

---

## The Four Core Concepts

### 1. Chart

A Chart is a directory (or `.tgz` archive) containing everything needed to deploy
an application. Think of it like a `package.json` + `node_modules` equivalent
for Kubernetes.

```
my-app/
  Chart.yaml          ← chart metadata
  values.yaml         ← default config values
  charts/             ← sub-chart dependencies
  templates/          ← Kubernetes manifest templates
    _helpers.tpl
    deployment.yaml
    service.yaml
    ingress.yaml
    hpa.yaml
    NOTES.txt
```

### 2. values.yaml

The configuration file for the Chart. All the things that vary between environments
(image tag, replica count, service port, ingress hostname) live here as defaults.

```yaml
replicaCount: 1

image:
  repository: nginx
  tag: "1.21"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  host: myapp.example.com

resources:
  limits:
    cpu: 100m
    memory: 128Mi
```

You override these at install time — either with `--set` or a separate values file.

### 3. Templates

Template files are Kubernetes YAML with Go template syntax (double curly braces)
that reference values from `values.yaml`. At install time, Helm renders them into
plain Kubernetes manifests.

```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.port }}
```

Key template syntax:

| Syntax | Meaning |
|---|---|
| `{{ .Values.image.tag }}` | Reference a value from values.yaml |
| `{{ .Chart.Name }}` | Reference Chart.yaml field |
| `{{ .Release.Name }}` | The release name given at install time |
| `{{- if .Values.ingress.enabled }}` | Conditional block |
| `{{- include "my-app.fullname" . }}` | Call a named template from _helpers.tpl |
| `\| nindent 4` | Pipe to indent function (for YAML formatting) |

### 4. Release

A Release is a named, versioned instance of a Chart installed in a cluster.
You can install the same Chart multiple times as different releases
(e.g. `my-app-staging` and `my-app-prod`), each with different values.

```
Chart  ──install──▶  Release: my-app-prod  (revision 1)
                         ──upgrade──▶  revision 2
                         ──rollback──▶ revision 1
```

Helm stores release history as Kubernetes Secrets in the same namespace.

---

## Install, Verify, and Scaffold

### Install Helm

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
# version.BuildInfo{Version:"v3.x.x", ...}
```

### Create a new Chart

```bash
helm create my-app
```

This scaffolds the full directory structure. Every file is functional
and ready to customise.

```bash
# View the structure
tree my-app/
```

### Explore the generated files

```bash
# See the default values
cat my-app/values.yaml

# See the deployment template
cat my-app/templates/deployment.yaml

# Render templates locally without installing (dry run)
helm template my-app ./my-app

# Render with value overrides
helm template my-app ./my-app --set image.tag=v2.0
```

---

## Essential Helm Commands

### Install and manage releases

```bash
# Install a chart as a new release
helm install my-app ./my-app

# Install with value overrides
helm install my-app ./my-app \
  --set image.tag=v2.0 \
  --set replicaCount=3

# Install with a custom values file (for different environments)
helm install my-app ./my-app -f prod-values.yaml

# Install into a specific namespace (creates it if needed)
helm install my-app ./my-app --namespace production --create-namespace

# Dry run — show what would be installed without applying
helm install my-app ./my-app --dry-run

# Upgrade an existing release
helm upgrade my-app ./my-app --set image.tag=v3.0

# Install or upgrade (idempotent — safe to run repeatedly)
helm upgrade --install my-app ./my-app -f prod-values.yaml

# Rollback to a previous revision
helm rollback my-app 1        # roll back to revision 1

# Uninstall a release
helm uninstall my-app
```

### Inspect releases

```bash
# List all releases in the current namespace
helm list

# List across all namespaces
helm list -A

# Show full status of a release
helm status my-app

# Show release history (all revisions)
helm history my-app

# Show the computed values for a release
helm get values my-app

# Show the rendered manifests for a release
helm get manifest my-app
```

### Work with the Helm Hub / repositories

```bash
# Add a chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repo index
helm repo update

# Search for a chart
helm search repo nginx

# Install from a repo
helm install my-nginx bitnami/nginx

# Show configurable values for a chart
helm show values bitnami/nginx
```

---

## Helm Architecture Flow

```
Chart (directory)
  ├── Chart.yaml         metadata
  ├── values.yaml        default values
  └── templates/         Go-templated K8s YAML
        ├── _helpers.tpl
        ├── deployment.yaml
        └── service.yaml
         ↓
    helm install / upgrade
         ↓
    Helm CLI merges values → templates
         ↓
    Rendered K8s manifests (plain YAML)
         ↓
    kubectl apply (done by Helm internally)
         ↓
    Release stored in cluster (as a Secret)
    Kubernetes objects created/updated
```

---

## values.yaml Override Patterns

### At install time with --set

```bash
helm install my-app ./my-app \
  --set image.tag=v2.0 \
  --set replicaCount=3 \
  --set ingress.enabled=true \
  --set ingress.host=prod.myapp.com
```

### With environment-specific values files

```
my-app/
  values.yaml           ← base defaults
  values-staging.yaml   ← staging overrides
  values-prod.yaml      ← prod overrides
```

```bash
# Staging
helm upgrade --install my-app ./my-app \
  -f values.yaml \
  -f values-staging.yaml

# Production
helm upgrade --install my-app ./my-app \
  -f values.yaml \
  -f values-prod.yaml
```

Later files take precedence — prod values override base values.

---

## Template Conditionals and Loops

### Conditional blocks

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "my-app.fullname" . }}
spec:
  rules:
    - host: {{ .Values.ingress.host }}
{{- end }}
```

### Loops (range)

```yaml
# In values.yaml
env:
  - name: NODE_ENV
    value: production
  - name: LOG_LEVEL
    value: info

# In deployment.yaml template
env:
  {{- range .Values.env }}
  - name: {{ .name }}
    value: {{ .value }}
  {{- end }}
```

### _helpers.tpl (named templates)

```yaml
# _helpers.tpl
{{- define "my-app.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "my-app.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

Called in templates as: `{{ include "my-app.fullname" . }}`

---

## Helm vs Raw kubectl

| | kubectl apply | Helm |
|---|---|---|
| Versioning | None | Full revision history |
| Rollback | Manual | `helm rollback my-app 1` |
| Templating | None | Go templates + values |
| Packaging | Individual files | Single chart |
| Reusability | Copy-paste | Parameterise via values |
| Dependencies | Manual | `helm dep update` |

Use raw `kubectl` for quick one-off tasks and learning. Use Helm for anything
you want to install, upgrade, and rollback reliably across environments.

---

## Common Gotchas

| Problem | Symptom | Fix |
|---|---|---|
| Release already exists | `Error: cannot re-use a name` | Use `helm upgrade --install` instead |
| Template render error | `Error: parse error` | Run `helm template` locally to debug |
| Values not applied | Old config still running | Check `helm get values my-app` — ensure `--set` is correct |
| Indentation error in YAML | Pod fails to start | Use `\| nindent N` in templates, validate with `helm lint` |
| Chart not found | `Error: chart not found` | Run `helm repo update` before installing from repo |
| Wrong namespace | Release missing | Add `-n <namespace>` to all helm commands |
| Rollback fails | Resources in bad state | Check `helm history` for revision numbers, check K8s events |

### Lint before you install

```bash
# Validate chart structure and template syntax
helm lint ./my-app

# Validate with specific values
helm lint ./my-app -f prod-values.yaml
```

---

## Key Takeaways

1. Chart = the package. values.yaml = the config. Templates = K8s YAML with placeholders. Release = an installed instance.
2. `helm create my-app` scaffolds everything — start from there, don't write from scratch.
3. `helm template` renders locally without touching the cluster — use it to debug templates.
4. `helm upgrade --install` is idempotent — safe to run in CI pipelines every deploy.
5. Override values with `-f prod-values.yaml` for environments, `--set` for quick one-offs.
6. `helm rollback` works because Helm stores every revision as a Secret in the cluster.
7. `helm lint` before every install — catches YAML and template errors before they hit the cluster.