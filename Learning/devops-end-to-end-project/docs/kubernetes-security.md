# Kubernetes Security Notes

## NetworkPolicies

### What they are
A NetworkPolicy controls which pods can communicate with which other
pods (and external endpoints) — the network-layer equivalent of RBAC.
RBAC restricts API access; NetworkPolicy restricts actual network traffic.

### Why they're needed
By default, Kubernetes networking is **completely flat and open** — any
pod can reach any other pod, across any namespace, with zero restriction.
If an attacker compromises one exposed pod, they can freely reach
anything else in the cluster unless NetworkPolicy explicitly restricts
it. This is least privilege applied at the network layer.

### Ingress rules
Control **inbound** traffic to pods matching a selector. Match by pod
labels, namespace labels, or IP blocks (CIDR ranges). Defined under
`spec.ingress`.

### Egress rules
Control **outbound** traffic from pods matching a selector. Defined
under `spec.egress`. Easy to forget, but equally important — restricts
what a compromised pod could exfiltrate data to.

### Default deny policy — the concept that trips people up
NetworkPolicies are **additive/whitelist-based**:
- If **no** policy selects a pod, that pod is fully open (the flat
  default).
- The moment **any** policy selects a pod for a direction (ingress or
  egress), that direction becomes **deny-by-default** for that pod —
  only explicitly allowed traffic gets through.

Common pattern: apply an explicit `default-deny-all` policy first
(`podSelector: {}`, no rules), then layer specific `allow-*` policies on
top for exactly the traffic that should be permitted.

---

## Pod Security Context

| Setting | What it does |
|---|---|
| `runAsUser` | Forces the container process to run as a specific non-root UID instead of whatever the image defaults to (often root/UID 0) |
| `runAsGroup` | Same idea, for the primary GID the process runs as |
| `fsGroup` | Sets group ownership on mounted volumes so a non-root user (from `runAsUser`) can still read/write to them |
| `readOnlyRootFilesystem` | Mounts the container's root filesystem read-only — app can only write to explicitly mounted volumes, limiting what a compromised process can do |
| `allowPrivilegeEscalation` | Blocks a process from gaining more privileges than its parent (e.g. via setuid binaries) — should almost always be `false` |

**Key distinction:** pod-level `securityContext` (under `spec.securityContext`)
sets defaults for all containers in the pod; container-level
`securityContext` (under `spec.containers[].securityContext`) can
override those defaults per-container.

---

## This exercise

Built in `k8s/security/`:

| File | Purpose |
|---|---|
| `sample-apps.yaml` | `frontend` and hardened `backend` Deployments + a `backend` Service. `backend` runs `nginxinc/nginx-unprivileged`, non-root (UID 101), read-only root filesystem |
| `networkpolicy.yaml` | Consolidated: default-deny-all ingress, allow `frontend` → `backend` on port 8080, and restrict `backend`'s egress to DNS only |

### Observing the behavior change

```bash
kubectl apply -f sample-apps.yaml

# Before any policy: unrestricted
kubectl exec -it deploy/frontend -- wget -qO- --timeout=2 backend   # succeeds

kubectl apply -f networkpolicy.yaml   # applies default-deny-all + allow-frontend-to-backend + egress rule together
kubectl exec -it deploy/frontend -- wget -qO- --timeout=2 backend   # succeeds - frontend is explicitly allowed

# Confirm scope: a pod that ISN'T labeled frontend still can't reach backend
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- --timeout=2 backend
# times out - proves the allow rule is scoped to app=frontend specifically,
# not "networking reopened for everyone"
```

### Verifying securityContext

`backend` itself is hardened (no separate demo deployment needed):

```bash
kubectl exec -it deploy/backend -- id
# uid=101 gid=101 -- confirms non-root

kubectl exec -it deploy/backend -- touch /test-file
# Read-only file system -- confirms readOnlyRootFilesystem is enforced

kubectl exec -it deploy/backend -- touch /tmp/test-file
# succeeds -- confirms the restriction is scoped to volumes, not a blanket failure
```

## Gotchas / things to remember

- A NetworkPolicy with `podSelector: {}` and no listed rules under
  `ingress`/`egress` is a full deny for that direction — an empty
  `ingress: []` (or the key omitted entirely) means "allow nothing,"
  not "no restriction." This is the opposite of how an absent RBAC
  Role behaves and is easy to get backwards.
- NetworkPolicy enforcement depends on the **CNI plugin** actually
  supporting it — not every CNI does (Flannel alone, for example,
  historically didn't; Calico, Cilium, and others do). Applying a
  NetworkPolicy on an unsupported CNI silently does nothing.
- `readOnlyRootFilesystem: true` often breaks images that weren't
  designed for it (many expect to write to `/tmp`, `/var/cache`, etc.
  at runtime) — expect to add `emptyDir` volumes for those specific
  paths rather than assuming the flag "just works" on any image.
- `fsGroup` matters specifically when combining `runAsUser` with a
  mounted volume — without it, a non-root process frequently can't
  write to a volume that's owned by root by default.

## Real incident from this exercise

First attempt at hardening used stock `nginx` with `runAsUser: 101` +
`readOnlyRootFilesystem: true` + `containerPort: 8080`. The container
failed to become `Ready` (`kubectl exec` errored with "container not
found"), because stock nginx's config still said `listen 80` — the
`containerPort` change alone doesn't reconfigure the application inside
the container. Switched to `nginxinc/nginx-unprivileged:stable`, a
purpose-built image that already listens on 8080 and already tolerates
non-root/read-only constraints, which resolved it immediately.
**Lesson:** `securityContext` restrictions often require an image
actually built to tolerate them — bolting hardening flags onto an
arbitrary image's defaults is a common source of silent startup
failures, not just a config nitpick.
