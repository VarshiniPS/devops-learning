# Kubernetes Troubleshooting — Advanced

**Session:** 6:20 - 7:30 PM | Kubernetes Troubleshooting
**Goal:** Extend the base troubleshooting reference with additional failure states, including one hit live this week (`CreateContainerConfigError`)

> See `docs/kubernetes-troubleshooting.md` for the original CrashLoopBackOff,
> ImagePullBackOff, Pending, and FailedScheduling reference. This doc adds
> **OOMKilled**, **ErrImagePull** (as distinct from ImagePullBackOff), and
> **CreateContainerConfigError**, plus a consolidated flow across all of them.

---

## CrashLoopBackOff (Recap)

| | |
|---|---|
| **Symptom** | `STATUS: CrashLoopBackOff`, `RESTARTS` climbing |
| **Cause** | Container starts, then exits repeatedly — app-level crash, missing env var, bad startup command |
| **Resolution** | `kubectl logs <pod>` and `kubectl logs <pod> --previous`, then `kubectl describe pod` for `Last State: Terminated` reason/exit code |

---

## ImagePullBackOff vs ErrImagePull — the Distinction

These two are related but represent **different points in the retry cycle**:

| | ErrImagePull | ImagePullBackOff |
|---|---|---|
| **What it means** | The **immediate** result of a failed pull attempt | Kubernetes has **given up retrying for now** and is waiting before trying again (exponential backoff) |
| **When you see it** | Briefly, right after a pull fails | Persists between retry attempts — this is the one you'll actually see sitting in `kubectl get pods` most of the time |

**In practice:** `ErrImagePull` flashes by quickly and gets replaced by
`ImagePullBackOff` almost immediately, which is why `ImagePullBackOff` is the
one usually visible when you run `kubectl get pods`. Both share the same root
causes and the same fix.

**Cause:** wrong image name/tag, private registry with no credentials, or
(on EKS) the node's IAM role lacking `AmazonEC2ContainerRegistryReadOnly`.

**Resolution:**
```bash
kubectl describe pod <pod-name>      # Events section shows the exact pull error
```
Common messages and what they mean:
- `manifest for <image>:<tag> not found` → typo in image name/tag
- `unauthorized` / `authentication required` → missing `imagePullSecret`, or on EKS, missing ECR IAM permission on the node role

---

## Pending Pods (Recap)

| | |
|---|---|
| **Symptom** | `STATUS: Pending`, never reaches `Running` |
| **Cause** | Scheduler can't place the Pod — insufficient CPU/memory on all nodes, taint/affinity mismatch, unbound PVC, or zero nodes at all |
| **Resolution** | `kubectl describe pod` → Events → `FailedScheduling` message; `kubectl get nodes` / `kubectl describe node` to check real capacity |

---

## OOMKilled

| | |
|---|---|
| **Symptom** | Pod shows `CrashLoopBackOff` in `get pods`, but `describe pod` reveals the *actual* reason underneath |
| **Cause** | Container exceeded its `resources.limits.memory` — the kernel's OOM killer terminates the process |
| **Resolution** | See below |

**This is easy to misdiagnose** — `kubectl get pods` just shows
`CrashLoopBackOff` like any other crash. The real signal is buried one level
deeper:

```bash
kubectl describe pod <pod-name>
```
Look specifically at:
```
Last State:     Terminated
  Reason:       OOMKilled
  Exit Code:    137
```

**Fix — two possible directions, and it matters which one you pick:**
1. **The app genuinely needs more memory** → raise `resources.limits.memory`
   (and `requests.memory` to match, so the scheduler places it correctly)
2. **There's a memory leak** → raising the limit only delays the crash, it
   doesn't fix it. Check `kubectl top pods` over time to see if memory usage
   climbs continuously rather than stabilizing — that pattern points to a
   leak, not an undersized limit.

This connects directly to the Resource Requests & Limits session —
**exit code 137 always means OOMKilled**, and it's one of the most common
real production incidents.

---

## CreateContainerConfigError

| | |
|---|---|
| **Symptom** | `STATUS: CreateContainerConfigError`, Pod never reaches `ContainerCreating` completion, no restarts climbing (unlike CrashLoopBackOff — this fails *before* the container even starts) |
| **Cause** | The Pod spec references a **ConfigMap or Secret key that doesn't exist**, or the ConfigMap/Secret itself doesn't exist |
| **Resolution** | See below |

**This is a distinct failure mode from CrashLoopBackOff** — the container
never actually starts running at all, so `kubectl logs` will return nothing
useful. The problem is entirely in kubelet's config-building step, before the
container runtime is even invoked.

```bash
kubectl describe pod <pod-name>
```
Look for an Events message like:
```
Warning  Failed  kubelet  Error: couldn't find key MYSQL_ROOT_PASSWORD in Secret default/mysql-secret
```
or
```
Warning  Failed  kubelet  configmap "mysql-config" not found
```

**Common root causes:**
1. **Referenced Secret/ConfigMap was never applied** — the Deployment/StatefulSet
   references it via `envFrom` or `secretKeyRef`, but `kubectl apply -f secret.yaml`
   was never run (or was run in the wrong namespace)
2. **Secret/ConfigMap exists, but the specific key is misspelled or missing**
   — e.g. Pod spec asks for `MYSQL_ROOT_PASSWORD`, Secret only defines `ROOT_PASSWORD`
3. **Namespace mismatch** — the Secret exists, but in a different namespace
   than the Pod

**Fix:**
```bash
# Confirm the Secret/ConfigMap actually exists in the right namespace
kubectl get secret <secret-name> -n <namespace>
kubectl get configmap <configmap-name> -n <namespace>

# Check exactly which keys it actually contains
kubectl describe secret <secret-name> -n <namespace>

# Compare against what the Pod spec references
kubectl get pod <pod-name> -o yaml | grep -A 5 "envFrom\|secretKeyRef\|configMapKeyRef"
```
Then either fix the key name/typo in the Deployment spec, or apply the
missing Secret/ConfigMap — no restart needed, just re-`apply` the corrected
manifest once the reference is fixed.

---

## Practice: The Five Core Commands

```bash
# 1. Spot the problem
kubectl get pods

# 2. Full detail — the Events section is the single most useful part
kubectl describe pod <pod-name>

# 3. What did the app itself log? (only useful if the container actually started)
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# 4. Cluster-wide event timeline
kubectl get events --sort-by=.lastTimestamp

# 5. Get inside a running container to inspect live state
kubectl exec -it <pod-name> -- sh
```

---

## Consolidated Comparison Table

| State | Container ever started? | `logs` useful? | Root cause category |
|---|---|---|---|
| **CrashLoopBackOff** | Yes, then exits repeatedly | Yes (`--previous`) | App-level error |
| **ImagePullBackOff / ErrImagePull** | No | No | Wrong image ref, or registry auth |
| **Pending** | No | No | Scheduler can't place the Pod |
| **OOMKilled** | Yes, then killed by kernel | Sometimes — check before OOM event | Memory limit exceeded |
| **CreateContainerConfigError** | No | No | Missing/misspelled ConfigMap or Secret key |

**The pattern worth internalizing:** *whether `kubectl logs` will tell you
anything depends entirely on whether the container process ever actually
started.* Three of these five states (`ImagePullBackOff`, `Pending`,
`CreateContainerConfigError`) fail **before** that point — `describe pod`
Events is the only source of truth for those. Only `CrashLoopBackOff` and
`OOMKilled` give you real application logs to work with.

---

## Full Debugging Flow

```
kubectl get pods
   │
   ▼
STATUS column tells you which branch to take:
   │
   ├── CrashLoopBackOff ──────► kubectl logs --previous, then describe for exit code
   ├── ImagePullBackOff ──────► kubectl describe → check image name/tag/auth
   ├── Pending ────────────────► kubectl describe → FailedScheduling → check nodes/resources
   ├── CreateContainerConfigError ─► kubectl describe → missing ConfigMap/Secret key
   └── Running but exit code 137 in describe ─► OOMKilled → raise limits or find the leak
```

---

## Key Concepts to Remember

- **`ImagePullBackOff` is what persists; `ErrImagePull` is the fleeting first attempt** — same root causes, same fix
- **Exit code 137 = OOMKilled**, always — check `kubectl describe pod`'s `Last State` section, not just `get pods`
- **`CreateContainerConfigError` means the container never started at all** — `kubectl logs` is useless here, go straight to `describe pod` Events for the missing key/Secret/ConfigMap name
- **Three failure states never produce app logs**: `ImagePullBackOff`, `Pending`, `CreateContainerConfigError` — recognizing this saves time by skipping straight to `describe pod` instead of trying `logs` first
- **Raising a memory limit fixes an undersized limit, but not a leak** — check `kubectl top pods` over time to tell the difference