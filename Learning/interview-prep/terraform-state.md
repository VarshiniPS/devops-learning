# Terraform State File

## What is a Terraform State File?

Terraform state is a file that stores Terraform's understanding of the infrastructure it manages.

Terraform uses the state file to:

* Track existing resources
* Map resources in code to real cloud resources
* Compare desired state vs current state
* Determine what needs to be created, modified, or deleted

Default file:

```text
terraform.tfstate
```

---

# Why is the State File Important?

Terraform is declarative.

We define:

```text
Desired State
```

Terraform compares that with:

```text
Current State
```

stored in the state file.

Without the state file, Terraform would not know:

* Which resources already exist
* Which resources Terraform created
* What changes are required

---

# Local State

By default Terraform stores state locally:

```text
terraform.tfstate
```

Advantages:

* Simple setup
* Good for learning and personal projects

Disadvantages:

* Not suitable for teams
* State can be lost if laptop crashes
* No centralized source of truth
* Multiple engineers may have different versions
* Risk of conflicting changes

---

# Remote State

Remote state stores the state file in a shared backend.

Common backend:

```text
AWS S3
```

Benefits:

* Centralized state management
* Team collaboration
* Single source of truth
* Backup and durability
* Better security controls

---

# Terraform Backend

A backend determines where Terraform stores its state.

Example:

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

Backend responsibilities:

* Store state
* Retrieve state
* Lock state
* Share state

---

# State Locking

Problem:

Two engineers run:

```text
terraform apply
```

at the same time.

Possible issues:

* Resource conflicts
* Corrupted state
* Infrastructure inconsistency

Terraform uses state locking to prevent concurrent updates.

---

# DynamoDB State Locking

Common AWS setup:

```text
S3
+
DynamoDB
```

Responsibilities:

S3:

```text
Stores terraform.tfstate
```

DynamoDB:

```text
Stores lock information
```

Flow:

1. Engineer runs terraform apply
2. Terraform acquires lock in DynamoDB
3. Infrastructure changes are executed
4. State file updated in S3
5. Lock released

If another engineer runs terraform apply while locked:

```text
Error acquiring state lock
```

---

# Local State vs Remote State

| Feature            | Local State | Remote State |
| ------------------ | ----------- | ------------ |
| Team Collaboration | No          | Yes          |
| Shared State       | No          | Yes          |
| State Locking      | No          | Yes          |
| Backup             | Manual      | Automatic    |
| Production Ready   | No          | Yes          |

---

# Interview Questions

## What is a Terraform State File?

Terraform state is a file that stores Terraform's understanding of the infrastructure it manages and is used to compare desired state with current state.

---

## Why is Remote State Preferred?

Remote state provides a centralized source of truth, enables collaboration, supports state locking, and prevents conflicting infrastructure changes.

---

## What Happens if the State File is Deleted?

Terraform loses track of managed resources and may attempt to recreate resources or produce incorrect plans.

---

## Why Use DynamoDB with Terraform?

DynamoDB provides state locking, preventing multiple engineers from modifying infrastructure simultaneously.

---

# Quick Revision

Terraform State:

```text
Current Infrastructure State
```

Remote Backend:

```text
S3
```

State Locking:

```text
DynamoDB
```

Purpose:

```text
Desired State
       vs
Current State
```
