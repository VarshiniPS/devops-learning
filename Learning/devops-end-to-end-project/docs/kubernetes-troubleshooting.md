# Kubernetes Troubleshooting

**Session:** 8:00 - 9:30 AM | Hands-On
**Goal:** Build a systematic debugging workflow using core kubectl commands

---

## The Debugging Toolkit

| Command | What it tells you |
|---|---|
| `kubectl get pods` | Quick status: Running, Pending, CrashLoopBackOff, etc. |
| `kubectl describe pod <name>` | Full detail: events, resource limits, mount status, image pull status |
| `kubectl logs <name>` | What the container actually printed (stdout/stderr) |
| `kubectl logs <name> --previous` | Logs from *before* the last crash/restart |
| `kubectl get events` | Cluster-wide event timeline — scheduling failures, pulls, warnings |
| `kubectl get all` | Everything in the namespace at once — Deployments, Pods, Services, ReplicaSets |
| `kubectl exec -it <name> -- sh` | Shell directly into a running container to inspect live state |

### The Standard Debugging Order

```
1. kubectl get pods                → spot the problem (STATUS column)
2. kubectl describe pod <name>     → read the Events section at the bottom
3. kubectl logs <name>             → see what the app itself said
4. kubectl get events              → check for cluster-level issues (scheduling, quota)
5. kubectl exec -it <name> -- sh   → poke around live, if the container is running
```

Always start with `describe` before `logs` — `describe`'s **Events** section usually
tells you *why* a Pod never got healthy in the first place (image pull failure,
scheduling failure), which `logs` can't show if the container never actually started.

---

## Issue → Cause → Resolution

### 1. CrashLoopBackOff

| | |
|---|---|
| **Symptom** | `kubectl get pods` shows `STATUS: CrashLoopBackOff`, `RESTARTS` climbing |
| **Cause** | The container starts, then exits (crashes) repeatedly — usually an app-level error: unhandled exception on startup, missing env var, bad config, wrong entrypoint command |
| **Resolution** | ```bash<br>kubectl logs <pod-name>              # see the crash reason<br>kubectl logs <pod-name> --previous   # if it crashed before logging anything<br>kubectl describe pod <pod-name>      # check Events + Last State: Terminated Reason<br>``` Fix the underlying app issue (missing env var, bad startup command, uncaught exception), then `kubectl apply` again. |

---

### 2. ImagePullBackOff / ErrImagePull

| | |
|---|---|
| **Symptom** | `kubectl get pods` shows `STATUS: ImagePullBackOff` or `ErrImagePull`; Pod never reaches `Running` |
| **Cause** | Kubernetes can't pull the container image — wrong image name/tag, private registry with no credentials, or the node's IAM role lacks registry read permission (e.g. missing `AmazonEC2ContainerRegistryReadOnly` for ECR) |
| **Resolution** | ```bash<br>kubectl describe pod <pod-name>      # check Events for the exact pull error<br>``` Common fixes: correct a typo'd image name/tag, create an `imagePullSecret` for private registries, or attach the correct IAM policy to the node role (for ECR on EKS). |

---

### 3. Pending

| | |
|---|---|
| **Symptom** | `kubectl get pods` shows `STATUS: Pending` — Pod never gets scheduled onto a node |
| **Cause** | The scheduler can't place the Pod anywhere — usually insufficient CPU/memory on all nodes, no nodes matching a `nodeSelector`/taint tolerance, or a PersistentVolumeClaim that can't bind |
| **Resolution** | ```bash<br>kubectl describe pod <pod-name>      # check Events: "FailedScheduling" reason<br>kubectl get nodes                    # confirm nodes are Ready and have capacity<br>kubectl describe node <node-name>    # check Allocatable vs Requested resources<br>``` Fix by lowering resource requests, adding more/larger nodes, or correcting `nodeSelector`/tolerations. |

---

### 4. FailedScheduling

| | |
|---|---|
| **Symptom** | Appears in `kubectl get events` or `kubectl describe pod` Events, alongside a `Pending` Pod |
| **Cause** | Same root causes as `Pending` above, but this is the specific **event reason** string the scheduler emits — worth recognizing directly since it's what you'll actually see in the Events table |
| **Resolution** | ```bash<br>kubectl get events --sort-by=.lastTimestamp<br>``` Read the event message closely — it usually says exactly what failed: `Insufficient cpu`, `node(s) didn't match Pod's node affinity`, `0/3 nodes are available: 3 Insufficient memory`, etc. |

---

### 5. Failed (Pod phase)

| | |
|---|---|
| **Symptom** | `kubectl get pods` shows `STATUS: Failed` |
| **Cause** | All containers in the Pod terminated, and at least one terminated in failure (non-zero exit code), and the Pod's `restartPolicy` is `Never` or `OnFailure` and retries are exhausted |
| **Resolution** | ```bash<br>kubectl describe pod <pod-name>      # check Last State: Terminated, Exit Code, Reason<br>kubectl logs <pod-name>              # see what happened before it failed<br>``` Common exit codes: `1` = generic app error, `137` = OOMKilled (out of memory — raise `resources.limits.memory`), `143` = SIGTERM (often a graceful shutdown that didn't finish in time). |

---

## Quick Reference: Exit Codes You'll See in `describe pod`

| Exit Code | Meaning |
|---|---|
| `0` | Success (nothing to debug) |
| `1` | Generic application error — check logs |
| `137` | OOMKilled — container exceeded its memory limit |
| `143` | SIGTERM — graceful termination, possibly didn't shut down in time |

---

## Practical Example Flow

```bash
# Step 1: spot the problem
kubectl get pods
# NAME                     READY   STATUS             RESTARTS   AGE
# nodejs-deployment-abc    0/1     CrashLoopBackOff   5          3m

# Step 2: get full detail
kubectl describe pod nodejs-deployment-abc
# Look at:
#   - Events (bottom section) for scheduling/pulling issues
#   - Last State: Terminated → Reason + Exit Code

# Step 3: check what the app said before crashing
kubectl logs nodejs-deployment-abc --previous

# Step 4: check cluster-wide events if it's not obviously app-level
kubectl get events --sort-by=.lastTimestamp

# Step 5: if it IS running but misbehaving, go inside
kubectl exec -it nodejs-deployment-abc -- sh
```

---

## Key Concepts to Remember

- **`describe` before `logs`** — Events explain *why* a Pod never got healthy; logs only work if the container actually started
- **`--previous` flag** is essential for CrashLoopBackOff — the *current* container may not have logged anything useful yet
- **Exit code 137 = OOMKilled** — one of the most common production issues, always check `resources.limits.memory` first
- **`Pending` + `FailedScheduling`** almost always trace back to resource capacity or affinity/taint mismatches — check `kubectl describe node` next
- **`ImagePullBackOff` on EKS** is very often an IAM permissions issue on the node role, not a typo — check both