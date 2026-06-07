# Terraform Scenario Questions

## Scenario 1: State File Deleted

### Question

Your team stores Terraform state locally and a developer accidentally deletes `terraform.tfstate`.

What happens?

### Answer

Terraform loses track of the infrastructure it manages.

Although the actual AWS resources still exist, Terraform no longer knows about them.

Possible issues:

* Incorrect plans
* Duplicate resource creation attempts
* Infrastructure drift
* Loss of resource mapping

Recovery options:

* Restore state from backup
* Use remote state
* Re-import resources using:

```bash
terraform import
```

---

## Scenario 2: Two Engineers Run Terraform Apply

### Question

Engineer A and Engineer B both run:

```bash
terraform apply
```

at the same time.

What can happen?

### Answer

Without state locking:

* State corruption
* Resource conflicts
* Inconsistent infrastructure

With remote state and DynamoDB locking:

* First engineer acquires lock
* Second engineer receives lock error
* Second engineer waits until lock is released

---

## Scenario 3: Laptop Crash

### Question

A developer stores state locally and their laptop crashes.

What is the impact?

### Answer

The local state file may be lost.

Problems:

* Terraform loses resource tracking
* Team cannot access latest state
* Recovery becomes difficult

Best practice:

* Store state remotely in S3
* Enable versioning
* Use DynamoDB locking

---

## Scenario 4: Resource Deleted Manually

### Question

Terraform created an EC2 instance.

Someone deletes it directly from AWS Console.

What happens during Terraform Plan?

### Answer

Terraform compares:

Desired State
vs
Current State

Terraform detects resource drift.

Plan output will show:

```text
Resource missing
Will be recreated
```

Running:

```bash
terraform apply
```

will recreate the EC2 instance.

---

## Scenario 5: Terraform State is Corrupted

### Question

Terraform state becomes corrupted.

What would you do?

### Answer

Recovery steps:

1. Stop Terraform changes
2. Restore state from backup
3. Verify infrastructure
4. Run:

```bash
terraform plan
```

5. Confirm state matches infrastructure

Best prevention:

* Remote backend
* S3 versioning
* State locking

---

## Scenario 6: Why Not Store State in Git?

### Question

Can we commit terraform.tfstate into GitHub?

### Answer

Not recommended.

Reasons:

* May contain sensitive information
* Causes merge conflicts
* Not suitable for collaboration
* No state locking

Preferred solution:

```text
S3 + DynamoDB
```

---

## Scenario 7: Why Use S3 and DynamoDB Together?

### Question

Why do teams commonly use S3 and DynamoDB together?

### Answer

S3:

* Stores Terraform state

DynamoDB:

* Provides state locking

Together they provide:

* Centralized state
* Team collaboration
* Locking
* Reliability

---

## Scenario 8: Terraform Apply Fails Midway

### Question

Terraform creates 5 resources and fails on the 6th.

What happens?

### Answer

Resources already created remain in AWS.

Terraform records successful resources in state.

After fixing the issue:

```bash
terraform apply
```

Terraform continues from current state and creates only missing resources.

---

# Quick Interview Revision

State File:

```text
Tracks Infrastructure
```

Remote State:

```text
Single Source Of Truth
```

S3:

```text
Stores State
```

DynamoDB:

```text
State Locking
```

Terraform Drift:

```text
Infrastructure Changed Outside Terraform
```
