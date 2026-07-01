# Amazon ECR Notes

**Session:** 8:00 - 9:30 AM | AWS Hands-On  
**Goal:** Understand ECR basics and push a Docker image to a private repository

---

## What is Amazon ECR?

**ECR (Elastic Container Registry)** is AWS's fully managed Docker container image registry. It lets you store, manage, and deploy container images securely — tightly integrated with EKS, ECS, and Lambda.

Think of it as: **GitHub is to code what ECR is to Docker images.**

---

## Use Cases

- Store Docker images built by CI/CD pipelines (e.g. GitHub Actions)
- Supply images to EKS deployments via image URL in `Deployment` manifests
- Version and tag images per release (`v1.0`, `latest`, `sha-abc123`)
- Control access to images using IAM policies
- Scan images for security vulnerabilities automatically

---

## Private vs Public Repositories

| Feature | Private | Public |
|---|---|---|
| Access | IAM-controlled, AWS accounts only | Anyone can pull (no auth needed) |
| Use case | Internal apps, production workloads | Open source projects, public tools |
| Registry URL | `<account-id>.dkr.ecr.<region>.amazonaws.com` | `public.ecr.aws/<alias>` |
| Storage pricing | Pay per GB stored | Free for public images |
| Pull auth required | Yes (AWS credentials) | No (for pulling) |

**Rule of thumb:** Use **Private** for anything you'd deploy to production. Use **Public** only for images you intentionally want to share with the world.

---

## Hands-On: Push a Docker Image to ECR

### Prerequisites
- AWS CLI installed and configured (`aws configure`)
- Docker installed and running
- An existing Docker image (or build one)

---

### Step 1 — Create an ECR Repository

**Via AWS Console:**
1. Go to **Amazon ECR** → **Repositories** → **Create repository**
2. Choose **Private**
3. Name it (e.g. `my-app`)
4. Enable **Image scan on push** (recommended)
5. Click **Create repository**

**Via AWS CLI:**
```bash
aws ecr create-repository \
  --repository-name my-app \
  --region us-east-1
```

You'll get back a `repositoryUri` like:
```
123456789.dkr.ecr.us-east-1.amazonaws.com/my-app
```

---

### Step 2 — Authenticate Docker with ECR

Docker needs to log in to your private ECR registry before it can push images.

```bash
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com
```

You should see: `Login Succeeded`

> **Why this works:** `get-login-password` fetches a temporary token from AWS (valid 12 hours), and pipes it directly into `docker login` as the password.

---

### Step 3 — Build Your Docker Image (if not already built)

```bash
docker build -t my-app .
```

---

### Step 4 — Tag the Image for ECR

Docker needs the image tagged with the full ECR repository URI before pushing.

```bash
docker tag my-app:latest \
  123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

Format: `<repositoryUri>:<tag>`

---

### Step 5 — Push the Image to ECR

```bash
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

Docker uploads each image layer. Once done, your image is stored in ECR.

---

### Step 6 — Verify in AWS Console

Go to **ECR → Repositories → my-app → Images**  
You should see your image listed with its tag, size, and push date.

Or via CLI:
```bash
aws ecr list-images \
  --repository-name my-app \
  --region us-east-1
```

---

## Full Command Reference

```bash
# 1. Create repository
aws ecr create-repository --repository-name my-app --region us-east-1

# 2. Authenticate Docker
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

# 3. Build image
docker build -t my-app .

# 4. Tag image
docker tag my-app:latest \
  123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

# 5. Push image
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

# 6. Verify
aws ecr list-images --repository-name my-app --region us-east-1
```

---

## How ECR Fits in the Full Flow

```
Developer
   ↓ git push
GitHub
   ↓ triggers
GitHub Actions
   ↓ docker build + docker push
Amazon ECR  ← YOU ARE HERE
   ↓ image pulled by
Amazon EKS (Deployment manifest references ECR image URI)
   ↓
Service → Ingress → Users
```

---

## Key Concepts to Remember

- ECR is a **private Docker registry** hosted by AWS
- You must **authenticate Docker** before pushing (token valid 12 hours)
- Images are referenced by **URI + tag** in Kubernetes `Deployment` manifests
- Use **image scanning** to catch vulnerabilities on push
- ECR integrates natively with **EKS, ECS, CodePipeline, and GitHub Actions**