# Application Load Balancer (ALB) & Target Groups - AWS Interview Notes

## What is an ALB?

Application Load Balancer (ALB) is a Layer 7 load balancer that distributes HTTP and HTTPS traffic across multiple healthy targets.

### Why use ALB?

Without ALB:

```text
Users
 ↓
EC2
```

If the EC2 instance fails, the application becomes unavailable.

With ALB:

```text
Users
 ↓
ALB
 ↓
EC2-1
EC2-2
EC2-3
```

Traffic is distributed across healthy instances, improving availability and fault tolerance.

### Interview One-Liner

> ALB is a Layer 7 load balancer that distributes HTTP/HTTPS traffic across multiple healthy backend targets.

---

# What is a Target Group?

A Target Group is a logical collection of backend resources that receive traffic from the ALB.

Supported targets:

* EC2 Instances
* IP Addresses
* Lambda Functions

Example:

```text
ALB
 ↓
Target Group
 ↓
EC2-1
EC2-2
EC2-3
```

### Why do we need Target Groups?

The ALB does not directly forward traffic to EC2 instances.

Instead:

```text
ALB
 ↓
Target Group
 ↓
Targets
```

The Target Group maintains:

* Registered targets
* Health check configuration
* Health status of targets

### Interview One-Liner

> A Target Group is a collection of backend resources that receive traffic from the Load Balancer.

---

# Health Checks

ALB periodically performs health checks on registered targets.

Example health check path:

```text
/
```

or

```text
/health
```

Example:

```text
EC2-1 → Healthy
EC2-2 → Healthy
EC2-3 → Unhealthy
```

Traffic is sent only to healthy targets.

### Interview Question

What happens if an EC2 instance fails?

Answer:

> ALB health checks detect the unhealthy instance and stop routing traffic to it.

---

# Listeners

A Listener receives incoming requests on specific ports.

Common listener ports:

```text
80  → HTTP
443 → HTTPS
```

Example flow:

```text
User
 ↓
ALB Listener
 ↓
Listener Rules
 ↓
Target Group
 ↓
EC2
```

### Interview One-Liner

> Listeners receive incoming requests and forward them according to listener rules.

---

# Listener Rules

Listener Rules determine where traffic should be routed.

Examples:

```text
/api/*
```

↓

```text
API Target Group
```

---

```text
/images/*
```

↓

```text
Images Target Group
```

Example:

```text
ALB
 ↓
Listener
 ↓
Rules
 ├── /api/*    → API Target Group
 └── /images/* → Images Target Group
```

### Interview One-Liner

> Listener Rules route traffic based on URL paths, host headers, or other HTTP attributes.

---

# Complete Request Flow

## Basic Flow

```text
User
 ↓
ALB
 ↓
Target Group
 ↓
EC2
```

---

## Production Flow

```text
User
 ↓
Route53
 ↓
ALB
 ↓
Listener (80/443)
 ↓
Listener Rules
 ↓
Target Group
 ↓
Healthy EC2 Instances
 ↓
Application
 ↓
RDS
```

---

# What Happens When an Instance Becomes Unhealthy?

Example:

```text
Target Group
 ↓
EC2-1 → Healthy
EC2-2 → Unhealthy
EC2-3 → Healthy
```

ALB continues routing traffic only to:

```text
EC2-1
EC2-3
```

Traffic is not routed to EC2-2 until it becomes healthy again.

---

# Common Interview Questions

## Q1. What is an ALB?

Answer:

> ALB is a Layer 7 load balancer that distributes HTTP and HTTPS traffic across multiple healthy backend targets.

---

## Q2. Why use ALB?

Answer:

> ALB improves availability, fault tolerance, and scalability by distributing traffic across multiple healthy instances.

---

## Q3. What is a Target Group?

Answer:

> A Target Group is a logical collection of backend resources that receive traffic from the ALB.

---

## Q4. What happens when an EC2 instance becomes unhealthy?

Answer:

> ALB health checks detect the unhealthy instance and stop routing traffic to it.

---

## Q5. What are Listeners?

Answer:

> Listeners receive incoming requests on ports such as 80 or 443 and forward them according to listener rules.

---

## Q6. What are Listener Rules?

Answer:

> Listener Rules determine how requests are routed based on URL paths, host headers, or other HTTP conditions.

---

## Q7. Why is ALB called Layer 7?

Answer:

> Because it can inspect HTTP and HTTPS requests and route traffic based on application-layer information such as URL paths and host headers.

---

## Q8. All Targets Become Unhealthy. What Happens?

Answer:

> ALB stops routing traffic because no healthy targets are available. Users typically receive HTTP 503 Service Unavailable responses.

---

# Troubleshooting Scenario

## Target Group Shows Unhealthy

Checks to perform:

1. Verify the application is running.
2. Verify health check path is correct.
3. Verify health check port is correct.
4. Verify EC2 Security Group allows traffic from ALB Security Group.
5. Verify NACL is not blocking traffic.
6. Verify OS firewall is not blocking traffic.
7. Verify correct EC2 instances are registered in the Target Group.
8. Verify Listener and Listener Rules point to the correct Target Group.

---

# Quick Revision

```text
ALB
=
Layer 7 Load Balancer

Target Group
=
Backend Targets

Health Checks
=
Detect Healthy Targets

Listener
=
Receives Traffic

Listener Rules
=
Routing Logic

Healthy Targets
=
Receive Traffic

Unhealthy Targets
=
No Traffic
```

---

# 30-Second Interview Answer

> An Application Load Balancer (ALB) is a Layer 7 load balancer that distributes HTTP/HTTPS traffic across multiple healthy backend targets. Incoming requests are received by listeners, evaluated using listener rules, and then forwarded to the appropriate target group. The target group maintains registered targets and health check configurations. ALB periodically performs health checks and routes traffic only to healthy instances, improving availability and fault tolerance.
