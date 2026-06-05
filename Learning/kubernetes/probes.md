# Kubernetes Liveness and Readiness Probes

# Why Do We Need Probes?

Kubernetes must know:

1. Is the application alive?
2. Is the application ready to receive traffic?

These are different questions.

---

# Liveness Probe

Purpose:

Checks whether the application is still running correctly.

Question:

```text id="7mrgx3"
Is the application alive?
```

If the liveness probe fails:

```text id="thz2u6"
Kubernetes Restarts Container
```

---

# Readiness Probe

Purpose:

Checks whether the application is ready to serve requests.

Question:

```text id="f3q4ha"
Can the application receive traffic?
```

If readiness fails:

```text id="ycftn5"
Pod Stays Running
But
Removed From Service Endpoints
```

No traffic is sent to it.

---

# Difference

| Liveness                   | Readiness                |
| -------------------------- | ------------------------ |
| Checks if app is alive     | Checks if app is ready   |
| Failure causes restart     | Failure removes traffic  |
| Recovers hung applications | Prevents failed requests |

---

# Real World Example

Application Startup:

```text id="ggjlwm"
Container Starts
      ↓
Application Loading
      ↓
Database Connection
      ↓
Cache Warmup
      ↓
Ready
```

During startup:

```text id="x9s4r5"
Liveness = Success
Readiness = Failure
```

Result:

```text id="4tpsjs"
Pod Runs
No Traffic Sent Yet
```

Once startup completes:

```text id="sy2wgc"
Readiness = Success
```

Traffic begins.

---

# Why Liveness Probe?

Example:

```text id="6q5f4m"
Application Deadlock
```

Application:

* Process still exists
* Not responding

Without Liveness:

```text id="t3yx7s"
Container Runs Forever
```

With Liveness:

```text id="gmdntw"
Probe Fails
↓
Container Restarted
```

---

# Why Readiness Probe?

Example:

```text id="6g2f0h"
Application Starting
Database Not Connected
```

Without Readiness:

```text id="eq3yyk"
Traffic Sent Immediately
Users Get Errors
```

With Readiness:

```text id="wlrj4k"
Traffic Blocked
Until App Ready
```

---

# HTTP Probe Example

```yaml id="j0h0m4"
readinessProbe:
  httpGet:
    path: /
    port: 80
```

Kubernetes periodically checks:

```text id="fbl3vj"
http://pod-ip:80/
```

---

# Common Probe Types

## HTTP GET

```yaml id="m0w9ri"
httpGet:
  path: /
  port: 80
```

Most common.

---

## TCP Socket

```yaml id="07vow9"
tcpSocket:
  port: 3306
```

Checks port availability.

---

## Command Execution

```yaml id="8wwdba"
exec:
  command:
  - cat
  - /tmp/healthy
```

Runs inside container.

---

# Important Settings

## initialDelaySeconds

Time before first probe.

Example:

```yaml id="mym4dn"
initialDelaySeconds: 15
```

---

## periodSeconds

Probe frequency.

Example:

```yaml id="z4w6ud"
periodSeconds: 10
```

---

# Interview Questions

## What is a Liveness Probe?

A Liveness Probe checks whether an application is alive and healthy. If it fails, Kubernetes restarts the container.

---

## What is a Readiness Probe?

A Readiness Probe checks whether an application is ready to receive traffic. If it fails, Kubernetes stops sending traffic to the Pod.

---

## Why Are Both Needed?

Liveness answers:

```text id="rrb5h4"
Should I restart it?
```

Readiness answers:

```text id="xckpw7"
Should I send traffic to it?
```

---

## What Happens When Liveness Fails?

```text id="7f2sb3"
Container Restart
```

---

## What Happens When Readiness Fails?

```text id="0qzlhj"
Pod Runs
Traffic Removed
```

---

# Quick Revision

```text id="2nk38v"
Liveness
↓
Alive?
↓
Restart If Failed

Readiness
↓
Ready?
↓
Stop Traffic If Failed

Alive ≠ Ready
```
