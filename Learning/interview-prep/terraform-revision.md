# Terraform Revision Notes

## What is Terraform?

Terraform is an Infrastructure as Code (IaC) tool developed by HashiCorp.

It allows infrastructure to be defined and managed using code.

Benefits:

* Automation
* Consistency
* Version Control
* Repeatability
* Reduced Human Error
* Multi-Cloud Support

---

# Terraform Workflow

```text id="m1m32y"
terraform init
      ↓
terraform plan
      ↓
terraform apply
      ↓
Infrastructure Created
```

### terraform init

* Initializes working directory
* Downloads providers
* Configures backend

### terraform plan

* Shows proposed changes
* Compares desired state vs current state

### terraform apply

* Creates or modifies infrastructure

### terraform destroy

* Deletes infrastructure

---

# State File

Default file:

```text id="72t7yo"
terraform.tfstate
```

Purpose:

* Tracks infrastructure resources
* Stores current state
* Maps Terraform resources to cloud resources

Terraform uses it to compare:

```text id="0ztcux"
Desired State
      vs
Current State
```

---

# Why is State Important?

Without state:

* Terraform loses resource tracking
* Incorrect plans may occur
* Duplicate resource creation may occur
* Infrastructure drift becomes difficult to manage

---

# Local State

Stored on local machine:

```text id="tuhs1s"
terraform.tfstate
```

Problems:

* No collaboration
* Risk of loss
* No centralized source of truth
* No locking

---

# Remote State

Stored in shared backend.

Common AWS setup:

```text id="wy4frx"
S3 Bucket
```

Benefits:

* Team collaboration
* Centralized state
* Backup and durability
* Single source of truth

---

# Backend

Backend determines where Terraform stores state.

Example:

```hcl id="gk7m6z"
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

---

# State Locking

Problem:

```text id="85tyqa"
Two engineers run terraform apply
```

Possible issues:

* State corruption
* Resource conflicts
* Inconsistent infrastructure

Solution:

```text id="1z55l0"
DynamoDB Locking
```

Flow:

```text id="fgubrw"
Engineer 1
     ↓
Acquires Lock
     ↓
Terraform Apply
     ↓
Release Lock

Engineer 2
     ↓
Lock Error
     ↓
Wait
```

---

# S3 + DynamoDB

S3:

```text id="ccr2m8"
Stores State File
```

DynamoDB:

```text id="e6jnuy"
Stores Lock
```

Most common production setup.

---

# Providers

Providers allow Terraform to communicate with external platforms.

Examples:

```text id="i9xv5h"
AWS
Azure
GCP
Kubernetes
```

Example:

```hcl id="2ij4g5"
provider "aws" {
  region = "us-east-1"
}
```

Role:

```text id="9jq7r0"
Terraform → Provider → Cloud APIs
```

---

# Variables

Variables make Terraform reusable.

Example:

```hcl id="hm32ph"
variable "instance_type" {
  default = "t2.micro"
}
```

Usage:

```hcl id="r9n2j0"
instance_type = var.instance_type
```

Benefits:

* Reusability
* Flexibility
* Environment-specific configuration

---

# Common Interview Questions

## What is the purpose of the state file?

The state file stores Terraform's understanding of the infrastructure and is used to compare current state with desired state.

---

## Why use remote state?

Remote state provides collaboration, centralized storage, backup, and state locking.

---

## Why use DynamoDB with Terraform?

DynamoDB provides state locking and prevents concurrent infrastructure modifications.

---

## What is a provider?

A provider allows Terraform to interact with cloud platforms and external services.

---

## What is a variable?

A variable allows values to be parameterized, making Terraform configurations reusable.

---

# Quick Revision

Terraform:

```text id="mspz8f"
Infrastructure as Code
```

State File:

```text id="zlt7ri"
Tracks Infrastructure
```

Remote State:

```text id="esyo61"
S3
```

Locking:

```text id="n7pqgk"
DynamoDB
```

Provider:

```text id="s2v0h2"
Connects Terraform to Cloud APIs
```

Variable:

```text id="fngg9x"
Reusable Input Value
```
