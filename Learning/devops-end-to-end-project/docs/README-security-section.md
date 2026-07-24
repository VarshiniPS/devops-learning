# Kubernetes Security

This section covers the security hardening applied to workloads in this
project: NetworkPolicies for network-layer access control, and pod
`securityContext` for container-level hardening. Full concept notes:
[`docs/kubernetes-security.md`](docs/kubernetes-security.md). Production
scenario write-ups: [`docs/kubernetes-security.md`](docs/kubernetes-security.md#gotchas--things-to-remember).

## What's implemented

| Concern | File | What it does |
|---|---|---|
| Network access control | `k8s/security/networkpolicy.yaml` | Default-deny-all ingress, then explicitly allows only `frontend` → `backend` on port 8080, plus restricts `backend`'s egress to DNS resolution only |
| Container hardening | `k8s/security/sample-apps.yaml` (`backend` Deployment) | Runs as non-root (UID 101), read-only root filesystem, no privilege escalation |

## Applying

```bash
kubectl apply -f k8s/security/sample-apps.yaml
kubectl apply -f k8s/security/networkpolicy.yaml
```

## Verifying

```bash
# Non-root confirmed
kubectl exec -it deploy/backend -- id
# uid=101 gid=101

# Read-only root filesystem confirmed
kubectl exec -it deploy/backend -- touch /test-file
# touch: /test-file: Read-only file system

# But explicitly mounted paths ARE writable
kubectl exec -it deploy/backend -- touch /tmp/test-file
# succeeds - proves the restriction is scoped to volumes, not blanket failure

# NetworkPolicy: frontend can reach backend
kubectl exec -it deploy/frontend -- wget -qO- --timeout=2 backend
# succeeds

# NetworkPolicy: anything NOT labeled frontend cannot
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- --timeout=2 backend
# times out
```

## Best Practices

**NetworkPolicy**
- Start every namespace with an explicit `default-deny-all` policy, then layer specific `allow` rules on top — don't rely on the flat-network default and try to restrict after the fact.
- Restrict **egress**, not just ingress — a compromised pod with unrestricted egress can exfiltrate data even if inbound access is locked down.
- Verify your CNI plugin actually enforces NetworkPolicy before relying on it — not all CNIs do (e.g. plain Flannel historically doesn't); applying a policy on an unsupported CNI silently does nothing.
- Test both the positive and negative case: confirm the traffic you *meant* to allow still works, and confirm traffic you *meant* to block is actually blocked — a policy that "looks right" but was never tested against a real denied request can hide a scoping mistake.

**Pod securityContext**
- Default to non-root (`runAsUser`) for every workload unless there's a specific, understood reason not to.
- Prefer images built for non-root/read-only operation (e.g. `nginxinc/nginx-unprivileged`) over bolting `securityContext` restrictions onto a stock image that assumes root — mismatched assumptions between the image and the security settings cause real, sometimes silent startup failures.
- Use `readOnlyRootFilesystem: true` paired with explicit `emptyDir` volumes for the specific paths the application actually needs to write to — don't leave the whole filesystem writable "just in case."
- Set `allowPrivilegeEscalation: false` as a default on every container; there are very few legitimate reasons for a workload to need it `true`.
- Remember `fsGroup` when combining `runAsUser` with mounted volumes — without it, a non-root process often can't write to a volume owned by root by default.

**General**
- Treat security hardening as something to verify, not assume — every setting in this project (non-root, read-only fs, network restrictions) was confirmed with an actual `kubectl exec`/`wget` test against real running pods, not just reviewed as YAML.
