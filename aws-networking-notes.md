# AWS Networking Interview Notes

## 1. What is a VPC?

**VPC (Virtual Private Cloud)** is a logically isolated virtual network in AWS where resources such as EC2, RDS, ALB, and EFS can be deployed.

### Why do we need a VPC?

* Isolation from other AWS customers
* Control over IP addressing
* Custom routing
* Security and network segmentation

---

## 2. Public vs Private Subnet

### Public Subnet

A subnet whose route table contains a route to an Internet Gateway (IGW).

Example:

```text
0.0.0.0/0 → Internet Gateway
```

Typical resources:

* Application Load Balancer (ALB)
* Bastion Host
* NAT Gateway

### Private Subnet

A subnet that does not have a direct route to the Internet Gateway.

Typical resources:

* EC2 Application Servers
* RDS Databases
* Internal Services

---

## 3. Route Tables

A Route Table contains rules that determine where network traffic should be sent.

Default local route:

```text
10.0.0.0/16 → local
```

Examples:

```text
0.0.0.0/0 → Internet Gateway
```

```text
0.0.0.0/0 → NAT Gateway
```

### Interview Question

**Q: How does AWS decide where to send traffic?**

AWS checks the destination IP address and selects the most specific matching route from the route table.

---

## 4. Internet Gateway (IGW)

Internet Gateway is an AWS-managed component attached to a VPC that allows communication between resources and the internet.

Requirements for internet access:

1. Public IP
2. Route to Internet Gateway

### Interview Question

**Q: Is a Public IP enough for internet access?**

No. A route to the Internet Gateway must also exist.

---

## 5. NAT Gateway

A NAT Gateway allows resources in a private subnet to access the internet without being directly reachable from the internet.

### Requirements

Private subnet route table:

```text
0.0.0.0/0 → NAT Gateway
```

Public subnet route table:

```text
0.0.0.0/0 → Internet Gateway
```

### Why NAT Gateway is in Public Subnet?

Because NAT Gateway itself needs internet access through the Internet Gateway.

---

## 6. Security Groups

Security Groups act as virtual firewalls for EC2 instances.

### Characteristics

* Stateful
* Instance-level
* Supports Allow rules only

Example:

```text
Allow SSH (22) from My IP
Allow HTTP (80) from ALB
```

### Stateful Meaning

If inbound traffic is allowed, return traffic is automatically allowed.

---

## 7. Network ACL (NACL)

Network ACL is a subnet-level firewall.

### Characteristics

* Stateless
* Subnet-level
* Supports Allow and Deny rules

### Stateless Meaning

Both inbound and outbound rules must be configured.

---

## 8. Security Group vs NACL

| Feature        | Security Group | NACL                       |
| -------------- | -------------- | -------------------------- |
| Level          | Instance       | Subnet                     |
| Stateful       | Yes            | No                         |
| Allow Rules    | Yes            | Yes                        |
| Deny Rules     | No             | Yes                        |
| Return Traffic | Automatic      | Must be explicitly allowed |

---

## 9. Bastion Host

A Bastion Host is an EC2 instance deployed in a public subnet that acts as a secure entry point into private subnets.

Flow:

```text
Laptop
↓
Bastion Host
↓
Private EC2
```

### Why Use Bastion Host?

Avoid exposing application servers directly to the internet.

---

## 10. VPC Peering

VPC Peering allows two VPCs to communicate using private IP addresses.

Example:

```text
VPC-A (10.0.0.0/16)
↔
VPC-B (172.31.0.0/16)
```

### Requirements

1. VPC Peering Connection
2. Route Table Updates
3. Security Group Rules
4. NACL Rules

### Important Limitation

VPC Peering is NOT transitive.

Example:

```text
VPC-A ↔ VPC-B ↔ VPC-C
```

This does NOT allow:

```text
VPC-A ↔ VPC-C
```

---

## 11. Transit Gateway

Transit Gateway acts as a central networking hub.

Instead of creating many VPC peerings:

```text
VPC-A
VPC-B
VPC-C
```

Attach all VPCs to:

```text
Transit Gateway
```

Benefits:

* Easier management
* Scalable architecture
* Centralized routing

---

## 12. Common Architecture Flow

```text
User
↓
Route53
↓
CloudFront
↓
ALB
↓
EC2 (Private Subnet)
↓
RDS
```

### Storage Components

* S3 → Uploaded files, backups, logs
* EBS → EC2 root volume
* EFS → Shared file system across EC2 instances

---

# Common Interview Questions

## Q1. Why is RDS deployed in a Private Subnet?

RDS contains sensitive application data and should not be directly accessible from the internet.

---

## Q2. Why use NAT Gateway?

To allow private resources to access the internet for updates, package downloads, and external API calls.

---

## Q3. Can EC2 instances in different subnets communicate?

Yes. If they are in the same VPC, AWS uses the local route. Security Groups and NACLs must allow traffic.

---

## Q4. What should you check if SSH to EC2 fails?

1. Public IP assigned?
2. Internet Gateway attached?
3. Route table configured?
4. Security Group allows port 22?
5. NACL rules?
6. OS firewall?
7. Correct key pair?

---

## Q5. What should you check if Private EC2 loses internet access?

1. NAT Gateway exists?
2. Route table points to NAT Gateway?
3. NAT Gateway subnet has route to Internet Gateway?
4. Elastic IP attached?
5. NACL blocking traffic?

---

# Key Interview One-Liners

### Public Subnet

Subnet with a route to an Internet Gateway.

### Private Subnet

Subnet without a direct route to an Internet Gateway.

### Security Group

Stateful instance-level firewall.

### NACL

Stateless subnet-level firewall.

### NAT Gateway

Provides outbound internet access to private resources.

### VPC Peering

Private communication between two VPCs.

### Transit Gateway

Central hub connecting multiple VPCs.

### Internet Gateway

Enables communication between a VPC and the internet.
