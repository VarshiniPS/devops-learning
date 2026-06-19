# AWS EKS Basics

## What EKS Is

EKS (Elastic Kubernetes Service) is AWS's managed Kubernetes offering.
Running Kubernetes yourself means operating the control plane — API server,
etcd, scheduler, controller manager — across multiple AZs with high availability.
EKS takes all of that off your plate. AWS runs and maintains the control plane;
you focus entirely on worker nodes and workloads.

> One sentence: EKS = Kubernetes, but AWS runs the control plane for you.

---

## Core Components

### Control plane (AWS-managed)

You never SSH into these. AWS runs them invisibly across multiple AZs.

| Component | Role |
|---|---|
| API server | Single entry point for all kubectl commands and internal cluster comms |
| etcd | Distributed key-value store — holds all cluster state (Pods, Services, configs) |
| Scheduler | Decides which worker node a new Pod lands on |
| Controller manager | Runs control loops — ReplicaSet, Deployment, Node controllers etc. |

### Worker nodes (you manage)

EC2 instances that actually run your Pods. Each node runs:

- `kubelet` — agent that talks to the API server, starts/stops Pods
- `kube-proxy` — handles Service IP routing on the node
- Container runtime (usually `containerd`)

### Node groups

A node group is a collection of EC2 instances with the same configuration
(instance type, AMI, IAM role). EKS has two flavours:

| Type | What it means |
|---|---|
| **Managed node groups** | AWS provisions, registers, and drains nodes for you. Recommended. |
| **Self-managed nodes** | You control the EC2s, AMIs, and lifecycle entirely. More flexibility, more work. |
| **Fargate** | No nodes at all — AWS runs each Pod in its own isolated compute. No EC2 to manage. |

Managed node groups are the default choice for most teams.

---

## Shared Responsibility Model

This is the most important EKS concept for interviews and production use.

### AWS is responsible for

- Control plane availability (API server, etcd, scheduler, controller manager)
- Multi-AZ control plane replication and failover
- Control plane version patching and security updates
- etcd backups and snapshots
- Native AWS integrations (IAM, VPC CNI, CloudWatch, ALB controller)

### You are responsible for

- Worker node OS patching and AMI updates
- Node group scaling and instance type selection
- Kubernetes version upgrades on worker nodes (drain → update AMI → uncordon)
- IAM roles for Pods (IRSA — IAM Roles for Service Accounts)
- VPC, subnets, security groups, and network policies
- Pod security, container images, and application updates
- Cluster add-ons (CoreDNS, kube-proxy, VPC CNI versioning)

> Memory hook: AWS owns everything above the node. You own everything on the node and inside it.

---

## Traffic Flow: Users → ALB → EKS → Pods

```
Users (internet)
      ↓  HTTPS
AWS ALB (Application Load Balancer)   ← L7, single external IP
      ↓
Ingress Controller Pod                ← AWS LB Controller reads Ingress rules
      ↓  routes by path/host
ClusterIP Service                     ← stable virtual IP, label selector
      ↓
Pods (on EC2 worker nodes)            ← actual containers
```

### Why ALB instead of a classic LoadBalancer Service?

On EKS, the AWS Load Balancer Controller lets an Ingress resource automatically
provision and configure an AWS ALB. This is the production-grade pattern because:

- One ALB handles all your HTTP/HTTPS services (cheaper than one LB per service)
- ALB supports path-based and host-based routing natively
- ALB integrates with AWS Certificate Manager for TLS — no cert management in-cluster
- ALB has native AWS WAF, access logs, and health check integration

---

## Key EKS-Specific Concepts

### IRSA — IAM Roles for Service Accounts

How Pods securely access AWS services (S3, DynamoDB, Secrets Manager etc.)
without hardcoding credentials.

```
Pod → Service Account → IAM Role → AWS API
```

Each Pod's service account is annotated with an IAM role ARN. AWS STS issues
temporary credentials to the Pod via a projected volume. No long-lived keys.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/my-app-role
```

### VPC CNI

EKS uses the AWS VPC CNI plugin — each Pod gets a real VPC IP address (not
a secondary overlay network). This means:

- Pod IPs are routable from anywhere in the VPC
- Security groups can be applied directly to Pods
- No NAT between Pods and other AWS services

### Cluster add-ons

EKS manages versioning for core add-ons separately from the cluster:

| Add-on | Purpose |
|---|---|
| `coredns` | In-cluster DNS resolution for Services and Pods |
| `kube-proxy` | Service routing on each node |
| `vpc-cni` | Pod networking via VPC IPs |
| `aws-ebs-csi-driver` | Persistent volumes backed by EBS |

You update these independently when upgrading Kubernetes versions.

---

## Essential kubectl + eksctl Commands

```bash
# Create a cluster (eksctl is the easiest way)
eksctl create cluster \
  --name my-cluster \
  --region ap-south-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2

# Update kubeconfig to talk to EKS cluster
aws eks update-kubeconfig --name my-cluster --region ap-south-1

# Verify connection
kubectl get nodes
kubectl get pods -A

# Check node group details
eksctl get nodegroup --cluster my-cluster

# Scale a node group
eksctl scale nodegroup \
  --cluster my-cluster \
  --name standard-workers \
  --nodes 4

# Upgrade cluster control plane version
eksctl upgrade cluster --name my-cluster --version 1.29 --approve

# Upgrade managed node group
eksctl upgrade nodegroup \
  --name standard-workers \
  --cluster my-cluster \
  --kubernetes-version 1.29

# Delete cluster (tears down everything)
eksctl delete cluster --name my-cluster
```

### What `kubectl get nodes` shows on EKS

```
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-45.ec2.internal     Ready    <none>   2d    v1.29.1-eks-ab12c3d
ip-10-0-2-12.ec2.internal     Ready    <none>   2d    v1.29.1-eks-ab12c3d
```

- No `control-plane` role — those nodes are fully hidden by AWS
- Node names are private VPC DNS names (EC2 internal IPs)
- Version has an EKS-specific suffix

---

## EKS vs Self-Managed Kubernetes

| | EKS | Self-managed (kubeadm) |
|---|---|---|
| Control plane | AWS runs it | You run it |
| HA control plane | Built-in | Manual setup |
| Cost | ~$0.10/hr + EC2 | EC2 only (but more EC2 for control plane) |
| Upgrades | Managed (control plane) | Fully manual |
| AWS integrations | Native (ALB, IAM, VPC) | Manual setup |
| Learning | Less ops overhead | Full understanding of internals |

EKS makes sense for production. Self-managed makes sense for learning how
Kubernetes actually works under the hood.

---

## Common Gotchas

| Problem | Symptom | Fix |
|---|---|---|
| kubeconfig not updated | `kubectl` hits wrong cluster | `aws eks update-kubeconfig` |
| Node group in wrong subnets | Pods can't reach AWS services | Use private subnets with NAT gateway |
| IRSA not set up | `AccessDenied` from Pods | Annotate service account with role ARN |
| Node version behind control plane | Scheduling issues | Upgrade node group AMI |
| Add-on version mismatch | CoreDNS errors, CNI issues | Update add-ons after cluster upgrade |
| Security group blocks Pod traffic | Intermittent connection refused | Check SG rules on worker nodes |

---

## Key Takeaways

1. EKS = AWS manages the control plane. You manage worker nodes and workloads.
2. The shared responsibility line: **AWS owns above the node, you own on and inside it.**
3. Traffic flow: `Users → ALB → Ingress Controller → ClusterIP Service → Pods`
4. Use **managed node groups** — less operational burden, AWS handles draining.
5. Use **IRSA** for any Pod that needs AWS API access — never use long-lived IAM keys.
6. **VPC CNI** means Pods get real VPC IPs — no overlay network complexity.
7. Cluster add-ons (CoreDNS, kube-proxy, vpc-cni) must be updated separately when upgrading Kubernetes versions.

---

## Common Interview Questions

### Q1: Should we use EKS or ECS?

Ask three questions to decide:
1. Does the team know Kubernetes?
2. Do we need multi-cloud portability?
3. Do we need K8s ecosystem tooling — Helm, Argo CD, Istio, service meshes?

If yes to any → **EKS**. If the team is new to containers and we're AWS-only → **ECS**.

| | ECS | EKS |
|---|---|---|
| Learning curve | Low — AWS-native | High — full Kubernetes |
| Portability | AWS only | Multi-cloud |
| Ecosystem | AWS tooling | Helm, Argo, Istio, etc. |
| Ops overhead | Lower | Higher (nodes, add-ons, IRSA) |
| Fargate support | Yes | Yes |

Both ECS and EKS support Fargate. Fargate removes node management entirely regardless of which orchestrator you choose.

> Trap to avoid: ECS = AWS vendor lock-in. EKS = cloud portability. Don't reverse these.

---

### Q2: Why choose EKS over self-managed Kubernetes?

**EKS removes control plane operations.** AWS runs the API server, etcd, scheduler, and controller manager across multiple AZs — with HA, automatic patching, and etcd backups included. You pay ~$0.10/hr per cluster for this.

With self-managed (kubeadm), you own all of that:
- Setting up etcd clusters with HA
- Certificate rotation every 12 months
- Control plane upgrades (manual, risky)
- API server HA behind a load balancer

**Choose EKS** for production — it's undifferentiated heavy lifting you don't want to own.

**Choose self-managed** if you need deep control plane customisation (custom admission controllers, non-standard configs) or want to learn Kubernetes internals thoroughly.

> What you give up with EKS: less control over control plane config, AWS vendor dependency, and you learn less about how K8s works underneath.

---

### Q3: What container infrastructure for migrating a monolith to microservices?

Start by engaging with the context — the team is already stretched breaking up the monolith, so minimise ops overhead during migration.

**Default recommendation: ECS on Fargate**
- No nodes to manage
- Simple AWS integration
- Team focuses on decomposition, not Kubernetes ops

**Choose EKS with managed node groups if:**
- Team already has Kubernetes experience
- You need Helm, Argo CD, or a service mesh
- Multi-cloud portability is a requirement within 12 months

Either way, use Fargate during the migration phase to reduce risk. You can migrate from ECS to EKS later — doing both simultaneously (migrating + learning K8s) is a recipe for failure.

> Framing tip: always reference the scenario in your answer. "Given we're mid-migration, I'd prioritise reducing ops overhead" signals senior engineering thinking.

---

### Q4: A worker node goes down. Whose responsibility is it? What do you do?

**Three-beat answer:**

**1. What Kubernetes does automatically:**
The scheduler detects the node is unavailable and reschedules Pods to healthy nodes. Workload recovery happens automatically — you don't need to intervene for the Pods.

**2. What you check:**
```bash
kubectl get nodes                          # look for NotReady status
kubectl describe node <node-name>          # check events and conditions
kubectl get pods -A -o wide               # confirm Pods rescheduled successfully
```

**3. How the node gets replaced:**
Worker nodes sit in a managed node group backed by an Auto Scaling Group. ASG detects the unhealthy EC2 via health checks and provisions a replacement automatically. If it doesn't, check ASG health check configuration in the AWS console.

**Root cause investigation:**
- `NotReady` = kubelet lost contact with API server (network, resource exhaustion)
- Terminated = EC2 instance failed (hardware, spot interruption)
- Check CloudWatch metrics for the EC2 (CPU, memory, disk) and VPC flow logs for network issues

> Memory hook: AWS replaces a broken API server. You replace a broken worker node (or ASG does it for you).

---

### Q5: Managed node groups vs self-managed nodes vs Fargate — when to use each?

| | Managed node groups | Self-managed | Fargate |
|---|---|---|---|
| Who manages EC2 | AWS (provisioning, draining, updates) | You | No EC2 at all |
| Upgrade experience | AWS drains nodes automatically | Manual cordon, drain, replace | N/A |
| Flexibility | Standard instance types | Full control — any AMI, any config | No DaemonSets, no stateful |
| Cost | Standard EC2 pricing | Standard EC2 pricing | Higher per unit, zero node ops |
| Use when | Most production workloads | Custom AMIs, GPUs, special hardware | Batch jobs, short-lived, zero-ops teams |

**Key details:**
- Managed node groups handle `cordon → drain → terminate → replace` automatically during upgrades. This is the specific thing that makes node upgrades painless.
- Self-managed is required for GPU workloads with custom drivers, custom OS configs, or Bottlerocket with bespoke settings.
- Fargate doesn't support DaemonSets (no node-level agents) or stateful workloads that need persistent local storage.

> One-liner: managed for most things, self-managed for custom hardware, Fargate for serverless-style workloads.
