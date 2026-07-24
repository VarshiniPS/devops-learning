# StatefulSet Production Scenarios

Real-world design decisions for running stateful workloads on Kubernetes.

---

## Scenario 1: Deploying PostgreSQL on Kubernetes

### Would you use a Deployment or StatefulSet?

**StatefulSet.**

### Why?

Each PostgreSQL replica has its own data directory that must persist and
reattach to that **same specific pod** across restarts and rescheduling —
not to any interchangeable pod. A Deployment's pods are disposable clones;
if `postgres-1` were killed and recreated as part of a Deployment, the new
pod has no guaranteed relationship to the old pod's data. A StatefulSet
guarantees `postgres-1` (specifically, by stable name) always reattaches
to the volume it owned before.

This matters concretely for PostgreSQL because:
- Each replica's on-disk data represents real committed state, not a
  cache that can be safely thrown away and rebuilt.
- Replicas may be at different points in the replication stream (a
  primary vs. streaming replicas), so they are not interchangeable —
  which pod is which actually matters.
- Ordered startup matters if replicas depend on discovering a primary
  before joining as a replica.

### How would persistent storage be handled?

**Mechanism: `volumeClaimTemplates`.** Each replica (`postgres-0`,
`postgres-1`, `postgres-2`, ...) gets its own dedicated PersistentVolumeClaim
generated from this template — e.g. `data-postgres-0`, `data-postgres-1` —
and that PVC follows that specific pod across rescheduling, exactly like
`data-mysql-0` did in our hands-on exercise.

Production-specific details that matter beyond just using
`volumeClaimTemplates`:

| Concern | Detail |
|---|---|
| **Access mode** | `ReadWriteOnce` — each replica's volume must be exclusive to it, not shared. Never `ReadWriteMany` for a database's own data directory. |
| **StorageClass** | In production, specify a `storageClassName` backed by real block storage — e.g. `gp3` (AWS EBS), `pd-ssd` (GCP Persistent Disk) — chosen for the IOPS/throughput a database actually needs, not the platform default. |
| **Storage size** | Set in `resources.requests.storage` per replica; plan for data growth, since resizing later may require a `StorageClass` that supports volume expansion. |
| **Replication logic is separate from storage** | A StatefulSet + PVCs solves identity and storage-attachment — it does **not** make PostgreSQL replicas replicate to each other. That's a database-level concern, typically handled by **Patroni** or an operator (Zalando Postgres Operator, CrunchyData PGO) that manages primary election, streaming replication, and failover. |
| **Backups are still required** | Persistent storage protects against pod rescheduling — it does **not** protect against accidental data deletion, disk corruption, or full cluster loss. Scheduled `pg_dump` / WAL archiving to separate storage (e.g. S3) is still necessary, independent of the PVC setup. |

### Lesson from hands-on experience

This scenario connects directly to a real incident from tonight's
StatefulSet exercise: even with correct PVCs and `volumeClaimTemplates`
in place, `mysql-0`'s data directory became corrupted after repeated
crashed startup attempts (`Cannot create redo log files because data
files are corrupt`) and required manually deleting the PVC to force a
clean re-initialization.

**Takeaway:** PVCs and StatefulSets correctly solve *"which pod does this
data belong to"* — they do not solve *"is this data safe/recoverable if
something goes wrong."* Persistent storage is not a backup strategy.
Production PostgreSQL needs both StatefulSet-managed storage identity
**and** a separate backup/restore plan.

### Quick answer for interview delivery

> "I'd use a StatefulSet, since each PostgreSQL replica needs its own
> data directory to persist and reattach to that same specific pod
> across restarts — not an interchangeable one. For storage, each
> replica gets its own PVC via `volumeClaimTemplates`, using
> `ReadWriteOnce` access mode and a `StorageClass` backed by real block
> storage in production, like EBS or a persistent disk. PVCs alone only
> solve identity and storage-attachment — they don't handle actual
> database replication between the pods, so in production I'd pair this
> with something like Patroni or a Postgres Operator to manage primary
> election and failover. And persistent storage isn't a backup
> strategy — I'd still want separate scheduled backups, since a
> corrupted or accidentally-deleted volume is still possible even with
> StatefulSets handling identity correctly."