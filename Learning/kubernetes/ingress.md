# Kubernetes Ingress ☸️

## What is Ingress?

Ingress is a Kubernetes resource that manages external HTTP/HTTPS traffic and routes requests to the appropriate Services inside a Kubernetes cluster.

Ingress acts as a single entry point for external users.

---

## Why Do We Need Ingress?

Without Ingress:

* Each application may require its own LoadBalancer Service.
* More external endpoints need to be managed.
* Infrastructure costs can increase.
* Routing becomes harder to manage.

With Ingress:

* Single external entry point.
* Routes traffic to multiple Services.
* Easier traffic management.
* Supports advanced routing rules.

---

## Traffic Flow

User
↓
Ingress
↓
Service
↓
Pods

Ingress does not send traffic directly to Pods.

Services still route traffic to healthy Pods.

---

## What is an Ingress Controller?

An Ingress resource only contains routing rules.

An Ingress Controller reads those rules and performs the actual traffic routing.

Without an Ingress Controller, Ingress rules do not work.

Common Ingress Controllers:

* NGINX Ingress Controller
* Traefik
* AWS Load Balancer Controller

---

## Host-Based Routing

Routes traffic based on hostname.

Example:

app.company.com
↓
app-service

api.company.com
↓
api-service

admin.company.com
↓
admin-service

Ingress checks the hostname and sends traffic to the appropriate Service.

---

## Path-Based Routing

Routes traffic based on URL path.

Example:

company.com/app
↓
app-service

company.com/api
↓
api-service

company.com/admin
↓
admin-service

Ingress checks the URL path and routes traffic accordingly.

---

## Ingress vs LoadBalancer Service

### LoadBalancer Service

* Exposes a single Service externally.
* Provides an external IP or endpoint.
* One external entry point per Service.

Example:

Internet
↓
LoadBalancer
↓
Frontend Service

### Ingress

* Exposes multiple Services through one entry point.
* Supports host-based routing.
* Supports path-based routing.
* Easier to manage multiple applications.

Example:

Internet
↓
Ingress

/app → app-service

/api → api-service

/admin → admin-service

---

## Key Learning

Service = Reception desk for Pods

Ingress = Reception desk for Services

Ingress sits in front of Services and routes external traffic to the correct Service.

---

# Interview Questions

### 1. What is Ingress?

Ingress is a Kubernetes resource that manages external HTTP/HTTPS traffic and routes requests to Services inside the cluster.

---

### 2. Why is Ingress needed?

Ingress provides a single entry point for multiple applications and supports advanced routing using hostnames and URL paths.

---

### 3. What is an Ingress Controller?

An Ingress Controller is a component that reads Ingress rules and performs the actual routing of traffic.

---

### 4. What is the difference between Ingress and Service?

A Service provides networking and load balancing for Pods.

Ingress sits in front of Services and manages external HTTP/HTTPS access.

---

### 5. What is the difference between Ingress and LoadBalancer Service?

LoadBalancer Service exposes one Service externally.

Ingress exposes multiple Services through a single entry point and supports host-based and path-based routing.

---

### 6. What is Host-Based Routing?

Host-based routing directs traffic based on the hostname.

Example:

app.company.com → app-service

api.company.com → api-service

---

### 7. What is Path-Based Routing?

Path-based routing directs traffic based on the URL path.

Example:

company.com/app → app-service

company.com/api → api-service

---

### 8. Explain the traffic flow using Ingress.

User
↓
Ingress
↓
Service
↓
Pods

Ingress routes traffic to the correct Service, and the Service routes traffic to healthy Pods.

---

### 9. Can Ingress work without an Ingress Controller?

No.

Ingress only contains routing rules. An Ingress Controller is required to enforce those rules and route traffic.

---

### 10. Give a real-world analogy for Ingress.

Ingress is like a reception desk in a large office building.

Visitors arrive at one entrance, and the receptionist directs them to the correct department based on their destination.
