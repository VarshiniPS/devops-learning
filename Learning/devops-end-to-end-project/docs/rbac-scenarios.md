# RBAC Production Scenarios

Real-world troubleshooting playbooks for RBAC-related issues.

---

## Scenario 1: "My application cannot list Pods even though it is running"

### Symptom
A developer reports their application is running fine (pod is `Running`,
not crashing) but calls to the Kubernetes API to list Pods are failing —
typically with a `403 Forbidden` error in the application logs, something
like:
```
pods is forbidden: User "system:serviceaccount:default:my-app-sa" cannot list resource "pods" in API group "" in the namespace "default"
```

### Why "it's running" doesn't mean "it has permissions"
A pod being `Running` only means the container started and its process is
alive — it says nothing about what that process is *authorized* to do
against the Kubernetes API. RBAC is enforced per-request, at the API
server, completely independent of whether the pod itself is healthy.

### Troubleshooting sequence

**1. Identify which ServiceAccount the pod is actually using**
```bash
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.serviceAccountName}'
```
If this returns nothing, the pod is using the namespace's `default`
ServiceAccount — a common root cause on its own (see `docs/rbac.md` for why
that's risky in general, beyond just this scenario).

**2. Check first: is there a RoleBinding or ClusterRoleBinding at all?**

This is the first object to check — *before* inspecting the Role's rules —
because even a perfectly correct Role grants nothing if it was never bound
to this ServiceAccount.
```bash
kubectl get rolebinding,clusterrolebinding -A -o wide | grep <serviceaccount-name>
```
Two possible outcomes:
- **Nothing found** → root cause: no binding exists at all. This is the
  most common cause of this exact symptom.
- **A binding is found** → move to step 3 to check what it actually grants.

**3. Inspect the Role or ClusterRole the binding references**
```bash
kubectl describe role <role-name> -n <namespace>
# or, if bound via a ClusterRole:
kubectl describe clusterrole <clusterrole-name>
```
Check specifically:
- Is `pods` listed under `resources`?
- Is `list` present under `verbs`? (A common subtle bug: `get` is granted
  but `list` was forgotten — these are different verbs and both are
  needed to `kubectl get pods` style listing.)
- Is `apiGroups` set to `[""]`? (Pods are in the core API group; a typo
  here silently breaks the rule.)

**4. Verify directly with `kubectl auth can-i`**
```bash
kubectl auth can-i list pods \
  --as=system:serviceaccount:<namespace>:<serviceaccount-name> \
  -n <namespace>
```
This impersonates the exact ServiceAccount and checks the exact verb and
resource, without needing to exec into the pod or reproduce the API call
from inside the application. Expected output is a plain `yes` or `no`.

Also worth checking the negative case explicitly, to confirm scope:
```bash
kubectl auth can-i list pods \
  --as=system:serviceaccount:<namespace>:<serviceaccount-name> \
  -n <some-other-namespace>
```
If this also returns `no` where it should return `yes` (or vice versa),
it confirms whether the issue is scope (wrong namespace) vs. a missing
permission entirely.

### Root cause checklist (in likelihood order)
1. No RoleBinding/ClusterRoleBinding exists for this ServiceAccount at all
2. Binding exists, but Role/ClusterRole doesn't include `pods` in `resources`
3. Binding exists, Role includes `pods`, but `list` is missing from `verbs`
4. RoleBinding exists but is scoped to the wrong namespace
5. Pod is using `default` ServiceAccount, and `default` was never granted
   any permissions in this namespace (correct, secure-by-default behavior —
   the actual fix is creating a dedicated ServiceAccount + Role + RoleBinding
   for this application, not granting permissions to `default`)

### Fix
Create a dedicated ServiceAccount, Role (scoped to exactly the verbs/
resources needed), and RoleBinding for this application specifically —
see `k8s/rbac/` for working examples of this pattern — rather than
widening `default`'s permissions or the existing Role beyond what's
actually required.
