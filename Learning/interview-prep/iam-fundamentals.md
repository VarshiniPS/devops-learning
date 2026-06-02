# AWS IAM Fundamentals

## What is IAM?

IAM (Identity and Access Management) is an AWS service used to securely manage access to AWS resources.

IAM allows administrators to control who can access resources and what actions they can perform.

---

## IAM User

An IAM User represents an individual person or application that needs access to AWS.

Examples:

* Developer
* Administrator
* Application User

An IAM User can have:

* Console Password
* Access Keys
* Permissions

---

## IAM Group

An IAM Group is a collection of IAM Users.

Permissions can be assigned to the group instead of individual users.

Example:

Developers Group

* User A
* User B
* User C

All users inherit the group's permissions.

---

## IAM Policy

An IAM Policy is a JSON document that defines permissions.

Policies determine:

* Allowed actions
* Denied actions
* Accessible resources

Policies can be attached to:

* Users
* Groups
* Roles

---

## IAM Role

An IAM Role provides temporary permissions.

Roles are commonly used by AWS services.

Examples:

* EC2 accessing S3
* Lambda accessing DynamoDB
* Cross-account access

Roles do not have permanent credentials.

---

## Authentication vs Authorization

### Authentication

Who are you?

Examples:

* Username
* Password
* MFA

Authentication verifies identity.

### Authorization

What can you do?

Examples:

* Launch EC2
* Read S3
* Delete DynamoDB

Authorization determines permissions.

---

## IAM Components Summary

User = Person

Group = Team

Policy = Permission Rules

Role = Temporary Permission Assignment

---

# Interview Questions

## What is IAM?

IAM is an AWS service used to manage identities and permissions for AWS resources.

---

## What is the difference between an IAM User and IAM Role?

An IAM User represents a person or application with long-term credentials.

An IAM Role provides temporary permissions and is commonly assumed by AWS services.

---

## Why do we use IAM Groups?

IAM Groups simplify permission management by assigning permissions to multiple users at once.

---

## What is an IAM Policy?

An IAM Policy is a JSON document that defines allowed or denied actions on AWS resources.

---

## What is the difference between Authentication and Authorization?

Authentication verifies identity.

Authorization determines permissions and access levels.

---

## Can an IAM User belong to multiple Groups?

Yes.

An IAM User can be a member of multiple IAM Groups.

---

## Why are IAM Roles preferred for EC2 instances?

Roles provide temporary credentials and eliminate the need to store access keys on EC2 instances.
