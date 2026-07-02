# Amazon EKS Deployment Notes

**Session:** 8:00 - 9:45 AM | AWS Hands-On
**Goal:** Understand how kubectl connects to EKS and deploy the app to a real cluster

---

## How kubectl Connects to EKS

`kubectl` doesn't talk to EKS directly through some special protocol — it talks to
the **Kubernetes API server**, exactly like it would for any cluster (Docker Desktop,
minikube, etc). The difference is *how it authenticates and finds that API server*.

```
kubectl command
      │
      ▼
~/.kube/config (kubeconfig file)
      │  contains: cluster API endpoint + auth info
      ▼
AWS IAM Authenticator
      │  signs request using your AWS credentials
      ▼
EKS API Server (managed by AWS)
      │
      ▼
Cluster responds (nodes, pods, etc.)
```

**Key point:** EKS's control plane (API server, etcd, scheduler) is fully managed
by AWS — you never see or SSH into those servers. `kubectl` just needs the right
endpoint URL and IAM-based credentials to talk to it, both of which come from
your **kubeconfig**.

---

## Worker Nodes vs Managed Node Groups

| Concept | What it is |
|---|---|
| **Worker Node** | An EC2 instance (or Fargate) that actually runs your Pods |
| **Managed Node Group** | AWS-managed group of EC2 worker nodes — handles provisioning, scaling, and lifecycle (patching, draining) for you |
| **Self-managed nodes** | Alternative where you manage the EC2 instances yourself (more control, more overhead) |
| **Fargate** | Serverless option — no EC2 nodes to manage at all, AWS runs Pods directly |

**This project uses:** Managed Node Groups — AWS handles node provisioning and
lifecycle, you just define the Deployment and EKS + the node group handle where
Pods actually run.

```
Amazon EKS Cluster
      │
      ├── Control Plane (AWS-managed — API server, etcd, scheduler)
      │
      └── Managed Node Group
              ├── Worker Node (EC2) ── Pod, Pod, Pod
              ├── Worker Node (EC2) ── Pod, Pod
              └── Worker Node (EC2) ── Pod
```

---

## What is kubeconfig?

The kubeconfig file (`~/.kube/config`) tells `kubectl` **which cluster to talk to**
and **how to authenticate**. It contains:

- Cluster API server endpoint (URL)
- Certificate authority data (to trust the API server)
- User auth info (in EKS's case, this delegates to AWS IAM via `aws eks get-token`)
- Context (which cluster + user + namespace combo is "current")

You don't hand-write this for EKS — the AWS CLI generates it for you.

---

## Hands-On: Connect kubectl to EKS

### Step 1 — Confirm your EKS cluster exists (or create one)

```bash
# List existing clusters
aws eks list-clusters --region us-east-1
```

If none exists, create one via the Console (**EKS → Create cluster**) or CLI/eksctl:
```bash
eksctl create cluster \
  --name my-cluster \
  --region us-east-1 \
  --nodegroup-name my-nodes \
  --node-type t3.medium \
  --nodes 2
```
> Cluster creation typically takes 10–15 minutes.

---

### Step 2 — Configure kubectl to point at your EKS cluster

```bash
aws eks update-kubeconfig --region us-east-1 --name my-cluster
```

This writes/updates `~/.kube/config` with your cluster's endpoint and IAM-based
auth — no manual editing needed.

**Expected output:**
```
Updated context arn:aws:eks:us-east-1:715708572462:cluster/my-cluster in /home/user/.kube/config
```

---

### Step 3 — Verify connection

```bash
kubectl get nodes
```

**Expected output (example):**
```
NAME                                         STATUS   ROLES    AGE   VERSION
ip-192-168-11-22.us-east-1.compute.internal  Ready    <none>   10m   v1.29.0
ip-192-168-33-44.us-east-1.compute.internal  Ready    <none>   10m   v1.29.0
```

If this returns nodes, `kubectl` is correctly talking to your EKS cluster.

---

## Hands-On: Deploy the App

### Step 4 — Apply manifests

```bash
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml
```

> Make sure `deployment.yaml` references your **ECR image URI**:
> `715708572462.dkr.ecr.us-east-1.amazonaws.com/my-app:latest`

---

### Step 5 — Verify everything is running

```bash
kubectl get pods
```
```
NAME                          READY   STATUS    RESTARTS   AGE
nodejs-deployment-abc123-xy   1/1     Running   0          45s
nodejs-deployment-abc123-zt   1/1     Running   0          45s
nodejs-deployment-abc123-qw   1/1     Running   0          45s
```

```bash
kubectl get svc
```
```
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
nodejs-service   ClusterIP   10.100.45.12    <none>        80/TCP    50s
```

```bash
kubectl get ingress
```
```
NAME             CLASS   HOSTS   ADDRESS                                          PORTS   AGE
nodejs-ingress   nginx   *       a1b2c3d4-xxxx.us-east-1.elb.amazonaws.com        80      1m
```

> On real EKS (unlike Docker Desktop), `ADDRESS` will show an actual AWS **ALB/NLB
> DNS name** once the Ingress Controller provisions it — this is your public entry point.

---

## Full Flow Recap

```
aws eks update-kubeconfig     →  kubectl now points at EKS
      │
kubectl get nodes             →  confirms connection to Managed Node Group
      │
kubectl apply -f deployment.yaml  →  Pods scheduled onto worker nodes
      │
kubectl apply -f service.yaml     →  stable internal endpoint created
      │
kubectl apply -f ingress.yaml     →  ALB provisioned, public entry point live
      │
kubectl get pods / svc / ingress  →  verify each layer is healthy
```

---

## Troubleshooting

### `kubectl get nodes` returns nothing or times out

**Cause:** kubeconfig isn't pointing at the right cluster, or IAM permissions
are missing.

**Fix:**
```bash
# Confirm current context
kubectl config current-context

# Re-run update-kubeconfig
aws eks update-kubeconfig --region us-east-1 --name my-cluster

# Confirm your IAM user/role is mapped in aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml
```

---

### Pods stuck in `Pending`

**Cause:** No worker nodes available, or resource requests exceed node capacity.

**Fix:**
```bash
kubectl describe pod <pod-name>   # check Events for reason
kubectl get nodes                 # confirm nodes are Ready
```

---

### `ImagePullBackOff` on EKS

**Cause:** Worker nodes can't pull from ECR — usually an IAM permissions issue
(Node IAM role needs `AmazonEC2ContainerRegistryReadOnly` policy).

**Fix:**
```bash
kubectl describe pod <pod-name>   # confirm the exact error
# Then verify node IAM role has ECR read permissions in IAM Console
```

---

## Key Concepts to Remember

- `kubectl` talks to the **EKS-managed API server**, authenticated via IAM through kubeconfig
- `aws eks update-kubeconfig` is what wires `kubectl` to a specific cluster
- **Managed Node Groups** = AWS handles worker node provisioning/lifecycle
- Deployment → Service → Ingress is the same pattern on EKS as on local Kubernetes —
  the only real difference is the Ingress Controller provisions a real **AWS ALB**
- Worker nodes need IAM permissions to **pull images from ECR**