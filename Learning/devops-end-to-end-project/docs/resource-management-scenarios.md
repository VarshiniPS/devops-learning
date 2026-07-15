# Kubernetes Resource Management - Production Scenarios

# Scenario 1: Application is Restarting Frequently Under Load

## Problem

A developer reports that the application runs normally under light traffic but starts restarting frequently when the load increases.

---

# Step 1: Check Pod Status

First, check whether the Pod is restarting.

```bash
kubectl get pods
```

Example:

```text
NAME          READY   STATUS    RESTARTS
my-app        1/1     Running   15
```

A high restart count indicates the container is repeatedly crashing.

---

# Step 2: Describe the Pod

```bash
kubectl describe pod <pod-name>
```

Things to check:

* Events
* OOMKilled
* Failed Liveness Probe
* Failed Readiness Probe
* Image Pull Errors
* Scheduling Errors

Example:

```text
Last State:
Terminated
Reason: OOMKilled
Exit Code: 137
```

---

# Step 3: Check Pod Logs

```bash
kubectl logs <pod-name>
```

If the Pod has already restarted:

```bash
kubectl logs <pod-name> --previous
```

Look for:

* Out of Memory errors
* Application exceptions
* Connection failures
* Crash stack traces

---

# Could it be CPU?

Yes.

Symptoms:

* Application becomes slow
* High response time
* Increased latency
* CPU throttling
* Pod usually keeps running

CPU exceeding its limit does **not** restart the container.

Instead, Linux throttles CPU usage.

---

# Could it be Memory?

Yes.

This is one of the most common reasons for Pod restarts.

If memory usage exceeds the configured memory limit:

* Container is terminated
* Pod status becomes OOMKilled
* Kubernetes restarts the container (depending on the restart policy)

Example:

```text
Reason: OOMKilled
```

Memory issues commonly appear only during heavy traffic.

---

# Step 4: Check Resource Usage

```bash
kubectl top pod
```

Example:

```text
NAME        CPU    MEMORY
my-app      950m   980Mi
```

If memory usage is close to or exceeds the configured limit, investigate memory leaks or increase the memory limit.

---

# Step 5: Check Resource Requests and Limits

```bash
kubectl describe pod <pod-name>
```

Example:

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "1Gi"
```

Verify whether the configured requests and limits are appropriate for the application's workload.

---

# Step 6: Check Node Resources

```bash
kubectl top node
```

This helps determine whether the worker node itself is under resource pressure.

---

# Common kubectl Commands

## List Pods

```bash
kubectl get pods
```

---

## Describe Pod

```bash
kubectl describe pod <pod-name>
```

---

## View Logs

```bash
kubectl logs <pod-name>
```

Previous container logs:

```bash
kubectl logs <pod-name> --previous
```

---

## Pod Resource Usage

```bash
kubectl top pod
```

---

## Node Resource Usage

```bash
kubectl top node
```

---

## View Deployment

```bash
kubectl get deployment
```

---

# Interview Answer

**Question:**

> A developer reports that the application restarts frequently under load. How would you troubleshoot it?

**Answer:**

> First, I would check the Pod status using `kubectl get pods` to confirm whether the container is restarting. Next, I would inspect the Pod using `kubectl describe pod` to identify events such as OOMKilled, failed probes, or scheduling issues. I would then review the application logs using `kubectl logs` (or `kubectl logs --previous` if the container has restarted). After that, I would check resource usage with `kubectl top pod` and compare it with the configured resource requests and limits. If memory usage exceeds the limit, the container will be OOMKilled and restarted. If CPU usage is high, the container is typically throttled rather than restarted. Finally, I would check node resource usage using `kubectl top node` to determine whether the worker node itself is under resource pressure.

---

# Key Takeaways

* High CPU usage → CPU is throttled; container usually continues running.
* High memory usage → Container is terminated with **OOMKilled** and restarted.
* Use `kubectl describe pod` to identify restart reasons.
* Use `kubectl logs --previous` to inspect logs from the previous container instance.
* Compare actual resource usage with configured requests and limits before deciding whether to tune the application or adjust resource allocations.
