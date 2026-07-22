# Kubernetes RBAC Notes

## What is RBAC?

Role-Based Access Control — Kubernetes' system for controlling **who** can do
**what** to **which resources**, and **where** (namespace vs. cluster-wide).
"Who" can be a human user, a group, or (most common in automation/CI-CD
contexts) a **ServiceAccount**.

## Why it's needed

Without RBAC, anyone with API access to the cluster has unrestricted power —
every pod, every secret, every namespace. RBAC enables **least privilege**:
each identity gets exactly the permissions its job requires, nothing more.
This matters most for:
- CI/CD pipelines that only need to deploy to one namespace
- Monitoring tools that only need read access
- Multi-team clusters where teams shouldn't see/touch each other's namespaces

## The four objects

| Object | Scope | Defines |
|---|---|---|
| `Role` | One namespace | A set of permissions (verbs + resources) |
| `ClusterRole` | Cluster-wide (or reusable) | Same as Role, but not tied to one namespace |
| `RoleBinding` | One namespace | Grants a Role **or** ClusterRole to a subject, within one namespace |
| `ClusterRoleBinding` | Cluster-wide | Grants a ClusterRole to a subject, across all namespaces |

**The subtlety that matters most in interviews:** a `ClusterRole` bound via a
`RoleBinding` only grants permissions in *that one namespace* — it's a way to
define a permission set once (e.g. "pod-reader") and reuse it across many
namespaces without redefining it each time. A `ClusterRole` bound via a
`ClusterRoleBinding` grants it *everywhere*. Same ClusterRole, two very
different blast radii depending on which binding type is used.

Also: some resources (like **Nodes**) aren't namespaced at all — they only
exist cluster-wide — so granting access to them **requires** a ClusterRole;
a plain `Role` can't reference them.

## This exercise

Built two working examples in `k8s/rbac/`:

1. **Namespace-scoped read access** — `pod-reader-sa` (ServiceAccount) →
   `pod-reader-role` (Role: get/list/watch pods) → `pod-reader-binding`
   (RoleBinding), all scoped to the `default` namespace only.
2. **Cluster-wide read access** — the same `pod-reader-sa` also gets
   `node-reader-clusterrole` (ClusterRole: get/list/watch nodes) via
   `node-reader-binding` (ClusterRoleBinding) — necessary because nodes
   aren't namespaced.

### Files

| File | Kind |
|---|---|
| `serviceaccount.yaml` | ServiceAccount |
| `role.yaml` | Role (namespace-scoped) |
| `rolebinding.yaml` | RoleBinding |
| `clusterrole.yaml` | ClusterRole (cluster-scoped) |
| `clusterrolebinding.yaml` | ClusterRoleBinding |

### Verifying permissions

`kubectl auth can-i` impersonates a subject and checks a specific
verb/resource without actually attempting the action:

```bash
kubectl auth can-i list pods --as=system:serviceaccount:default:pod-reader-sa -n default
# yes

kubectl auth can-i create pods --as=system:serviceaccount:default:pod-reader-sa -n default
# no - never granted create

kubectl auth can-i list pods --as=system:serviceaccount:default:pod-reader-sa -n kube-system
# no - Role was scoped to 'default' only

kubectl auth can-i list nodes --as=system:serviceaccount:default:pod-reader-sa
# yes - via the ClusterRoleBinding, works regardless of namespace
```

## Gotchas / things to remember

- Applying a `Role` or `ClusterRole` alone does **nothing** — permissions
  only take effect once bound via a `RoleBinding` or `ClusterRoleBinding`.
- `apiGroups: [""]` means the **core** API group (pods, services, nodes,
  configmaps, etc.). Other resources need their real group, e.g.
  `apps` for Deployments, `rbac.authorization.k8s.io` for RBAC objects
  themselves.
- Least privilege as a default habit: start with an empty `rules` list and
  add verbs/resources only as actually needed, rather than starting from
  `["*"]` and narrowing down.
- `--as=system:serviceaccount:<namespace>:<name>` is the exact impersonation
  string format — easy to typo, worth having memorized.
