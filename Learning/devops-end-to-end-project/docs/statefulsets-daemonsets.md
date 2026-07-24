# StatefulSets & DaemonSets Notes

## StatefulSets

### What it is
A workload controller for pods that need a **stable, unique identity** —
unlike a Deployment, where every pod is an interchangeable clone.

### Why they exist
Deployments assume pods are stateless and identical: any pod can be
killed and replaced, in any order, with a random name. That breaks down
for databases and distributed systems where:
- Each replica may hold **different data** (e.g. different Kafka partitions)
- Replicas need to address **specific peers by stable name** (e.g. electing
  a primary in a MongoDB replica set)
- Storage must follow **the same pod**, not just any pod, across restarts

### The four core guarantees

| Property | What it means |
|---|---|
| **Stable pod names** | `mysql-0`, `mysql-1`, `mysql-2` — sequential, predictable, not random suffixes |
| **Stable storage** | Each pod gets its own PVC via `volumeClaimTemplates`; on reschedule, it reattaches to the *same* PVC, not a fresh one |
| **Ordered deployment** | Pods start sequentially — `pod-0` must be Running/Ready before `pod-1` is created |
| **Ordered termination** | Scale-down happens in reverse — highest ordinal (`pod-2`) terminates first |

### Requires a headless Service
StatefulSets need a Service with `clusterIP: None` to give each pod its own
DNS name (`mysql-0.mysql.default.svc.cluster.local`), instead of one shared
virtual IP load-balancing across all pods indiscriminately.

### When to use
MySQL, PostgreSQL, MongoDB, Kafka, ZooKeeper — anything where replicas
are **not interchangeable**: they hold distinct data, need ordered
startup/shutdown, or need to reference each other by a stable name.

---

## DaemonSets

### What it is
A controller that ensures **exactly one pod runs on every node** in the
cluster (or a selected subset via node selectors/affinity).

### One pod per node
There's no `replicas:` field. Pod count is tied directly to node count —
add a node, a pod is scheduled there automatically; remove a node, its
pod is cleaned up automatically.

### Why they exist
Some workloads are node-level infrastructure, not application logic —
they need uniform presence on every node with no gaps:
- Log collectors that must see every node's logs
- Monitoring agents that must report every node's metrics
- Network/storage plugins needing a per-node presence to function

### Real examples
- **Fluentd / Filebeat** — ship logs from every node
- **Prometheus Node Exporter** — exposes per-node hardware/OS metrics for scraping

---

## Comparison: Deployment vs StatefulSet vs DaemonSet

| | Deployment | StatefulSet | DaemonSet |
|---|---|---|---|
| **Pod identity** | Interchangeable — random suffix (e.g. `web-7f8b9-x2k4p`) | Stable, sequential (`mysql-0`, `mysql-1`) | One per matching node, named after the node |
| **Replica count** | Set explicitly (`replicas: 3`) | Set explicitly (`replicas: 3`) | Not set — tied to node count automatically |
| **Storage** | Pods typically share a volume, or are stateless | Each pod gets its own PVC, reattached on reschedule | Usually stateless, or reads host paths directly (e.g. `/var/log`) |
| **Startup/shutdown order** | No ordering — all pods created/removed in parallel | Ordered — sequential create, reverse-order terminate | No ordering — one per node, independent of each other |
| **Networking identity** | Shared Service VIP, no per-pod DNS needed | Per-pod stable DNS via headless Service | Often uses `hostNetwork: true` to bind to the node's own IP |
| **Typical use case** | Stateless web apps, APIs | Databases, distributed systems needing per-replica identity | Node-level infrastructure: logging, monitoring, networking agents |
| **Example** | nginx web server, REST API | MySQL, Kafka, ZooKeeper | Fluentd, Node Exporter, Filebeat |
| **Scaling model** | Manually or via HPA, any number | Manually or via HPA, ordered | Automatic — follows cluster node count |

**The one-line mental model for each:**
- **Deployment** — "I want N identical, disposable copies of this, somewhere in the cluster."
- **StatefulSet** — "I want N copies of this, each with its own permanent identity and storage, created and destroyed in a specific order."
- **DaemonSet** — "I want exactly one copy of this on every node, automatically, with no gaps."

---

## This exercise

Built in `k8s/statefulsets-daemonsets/`:

| File | Purpose |
|---|---|
| `mysql-headless-service.yaml` | Headless Service (`clusterIP: None`) giving each MySQL pod a stable DNS name |
| `mysql-statefulset.yaml` | 3-replica MySQL StatefulSet with per-pod PVCs via `volumeClaimTemplates` |
| `node-exporter-daemonset.yaml` | DaemonSet running Prometheus Node Exporter on every node |

### Verifying

```bash
kubectl apply -f mysql-headless-service.yaml
kubectl apply -f mysql-statefulset.yaml
kubectl apply -f node-exporter-daemonset.yaml

kubectl get statefulsets
kubectl get pods -l app=mysql -w   # watch ordered creation live: mysql-0 -> mysql-1 -> mysql-2
kubectl get daemonsets              # DESIRED should match your node count
```

## Gotchas / things to remember

- Deleting a StatefulSet pod doesn't delete its PVC — this is intentional
  (data survives), but it means you must manually clean up PVCs if you
  want to fully reset storage, e.g. `kubectl delete pvc data-mysql-0`.
- Scaling a StatefulSet down and back up **reuses** the same PVCs for the
  same ordinals — `mysql-2`'s data comes back if you scale 3 -> 2 -> 3.
- A DaemonSet pod ignores the default scheduler's normal load-balancing
  logic in one sense — it's *guaranteed* a pod per matching node regardless
  of that node's current resource pressure, unless resource requests can't
  be satisfied.
- `hostNetwork`/`hostPID`/`hostPath` (used in the node-exporter example) are
  powerful and somewhat privileged access to the underlying node — appropriate
  for infrastructure DaemonSets, but not something to reach for in ordinary
  application workloads.
