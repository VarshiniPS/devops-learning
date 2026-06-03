# Terraform Interview Notes

## What is Terraform?

Terraform is an Infrastructure as Code (IaC) tool developed by HashiCorp that allows infrastructure to be provisioned, modified, and managed using code.

Terraform uses declarative configuration files to define the desired state of infrastructure.

Examples:

* EC2 Instances
* VPCs
* Subnets
* Security Groups
* Load Balancers
* S3 Buckets

---

# Why Terraform?

Benefits:

* Infrastructure as Code
* Version Control
* Automation
* Consistency
* Repeatability
* Reduced Manual Errors

---

# Terraform Architecture

```text
Developer
    |
Terraform CLI
    |
Terraform Provider
    |
Cloud APIs
(AWS APIs)
    |
Infrastructure
(EC2, VPC, S3, etc.)
```

---

# Terraform Workflow

## Step 1: Write Configuration

Example:

```hcl
provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "web" {
  ami           = "ami-123456"
  instance_type = "t2.micro"
}
```

---

## Step 2: terraform init

```bash
terraform init
```

Purpose:

* Initializes Terraform project
* Downloads providers
* Creates `.terraform` directory

Think:

```text
Prepare Terraform Environment
```

---

## Step 3: terraform plan

```bash
terraform plan
```

Purpose:

* Shows proposed changes
* Compares current state vs desired state
* No infrastructure changes are made

Think:

```text
Preview Changes
```

---

## Step 4: terraform apply

```bash
terraform apply
```

Purpose:

* Creates or modifies infrastructure
* Executes the plan

Think:

```text
Create Infrastructure
```

---

## Step 5: terraform destroy

```bash
terraform destroy
```

Purpose:

* Deletes resources managed by Terraform

Think:

```text
Remove Infrastructure
```

---

# Terraform State File

## What is Terraform State?

Terraform stores infrastructure information in a state file.

File:

```text
terraform.tfstate
```

The state file tracks:

* Existing resources
* Resource IDs
* Current infrastructure state

---

## Why is State File Needed?

Terraform needs to know:

```text
Desired State
vs
Current State
```

Without state, Terraform would not know what resources already exist.

---

## Interview Answer

### What is terraform.tfstate?

Terraform state file stores metadata and information about infrastructure resources managed by Terraform. Terraform uses it to track existing resources and determine what changes need to be made.

---

# Providers

## What is a Provider?

Providers allow Terraform to communicate with external platforms.

Examples:

* AWS Provider
* Azure Provider
* Google Cloud Provider
* Kubernetes Provider

Example:

```hcl
provider "aws" {
  region = "ap-south-1"
}
```

---

## Interview Answer

A Provider acts as a bridge between Terraform and the target platform.

Terraform uses providers to interact with APIs and manage infrastructure resources.

---

# Resources

Resources are the infrastructure objects managed by Terraform.

Examples:

```hcl
resource "aws_instance" "web" {

}
```

Examples of resources:

* EC2 Instances
* VPCs
* Security Groups
* S3 Buckets
* IAM Roles

---

## Interview Answer

A Resource is the actual infrastructure component that Terraform creates and manages.

---

# Variables

Variables make Terraform configurations reusable and flexible.

Example:

```hcl
variable "instance_type" {
  default = "t2.micro"
}
```

Usage:

```hcl
instance_type = var.instance_type
```

---

## Why Use Variables?

Benefits:

* Reusability
* Flexibility
* Environment-specific values
* Reduced code duplication

---

# Terraform Flow

```text
Developer
    |
terraform init
    |
terraform plan
    |
terraform apply
    |
Terraform Provider
    |
AWS APIs
    |
Infrastructure Created
```

---

# Common Interview Questions

## What is Terraform?

Terraform is an Infrastructure as Code tool used to provision and manage infrastructure through code.

---

## What is Infrastructure as Code?

Infrastructure is defined and managed using code instead of manual provisioning.

---

## Difference Between terraform plan and terraform apply?

terraform plan:

```text
Preview Changes
```

terraform apply:

```text
Execute Changes
```

---

## What does terraform init do?

* Downloads providers
* Initializes working directory
* Creates Terraform environment

---

## What does terraform destroy do?

Deletes resources managed by Terraform.

---

## What is Terraform State?

Terraform State stores information about existing infrastructure resources.

---

## Why is Terraform State Important?

Terraform uses the state file to compare desired state with current state and determine required changes.

---

## What is a Provider?

A Provider enables Terraform to interact with cloud platforms and APIs.

Example:

```text
AWS Provider
```

---

## What is a Resource?

A Resource is an infrastructure component managed by Terraform.

Examples:

```text
EC2
VPC
S3
IAM
Security Group
```

---

## What are Variables?

Variables allow dynamic and reusable Terraform configurations.

---

# Quick Revision

```text
Terraform
    ↓
Infrastructure as Code

Provider
    ↓
Connects Terraform to AWS

Resource
    ↓
Actual Infrastructure

Variable
    ↓
Reusable Input

terraform init
    ↓
Initialize

terraform plan
    ↓
Preview

terraform apply
    ↓
Create / Modify

terraform destroy
    ↓
Delete

terraform.tfstate
    ↓
Tracks Infrastructure
```
