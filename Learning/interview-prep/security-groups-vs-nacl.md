# Security Groups vs NACL - AWS Interview Notes

## Security Groups

### What is a Security Group?

A Security Group is a stateful virtual firewall attached to an EC2 instance or ENI (Elastic Network Interface) that controls inbound and outbound traffic.

### Key Characteristics

* Instance-level firewall
* Stateful
* Supports Allow rules only
* Multiple Security Groups can be attached to one EC2 instance
* Default deny for anything not explicitly allowed

### Example

Allow SSH from your laptop:

```text
Port: 22
Source: Your Public IP/32
```

Allow HTTP from ALB:

```text
Port: 80
Source: ALB Security Group
```

### Interview One-Liner

> Security Groups are stateful instance-level firewalls that support only allow rules. Any traffic not explicitly allowed is implicitly denied.

---

## NACL (Network Access Control List)

### What is a NACL?

A Network ACL is a stateless firewall attached to a subnet that controls inbound and outbound traffic for all resources within that subnet.

### Key Characteristics

* Subnet-level firewall
* Stateless
* Supports Allow and Deny rules
* One NACL can be associated with multiple subnets
* Rules are processed in order

### Interview One-Liner

> NACLs are stateless subnet-level firewalls that support both allow and deny rules.

---

# Stateful vs Stateless

## Security Group = Stateful

Example:

```text
Laptop
↓ SSH (22)
EC2
```

If inbound SSH is allowed:

```text
Port 22
Source = My IP
```

The response traffic is automatically allowed.

No separate rule is required for the return path.

### Interview Answer

> Security Groups are stateful because when a request is allowed, the corresponding response traffic is automatically allowed.

---

## NACL = Stateless

Example:

```text
Laptop
↓ SSH (22)
EC2
```

You must explicitly allow:

### Inbound

```text
Port 22
```

### Outbound

```text
Ephemeral Ports
```

Otherwise communication fails.

### Interview Answer

> NACLs are stateless because inbound and outbound traffic are evaluated separately. Both directions must be explicitly allowed.

---

# Security Group vs NACL

| Feature        | Security Group | NACL                       |
| -------------- | -------------- | -------------------------- |
| Scope          | Instance Level | Subnet Level               |
| Stateful       | Yes            | No                         |
| Stateless      | No             | Yes                        |
| Allow Rules    | Yes            | Yes                        |
| Deny Rules     | No             | Yes                        |
| Return Traffic | Automatic      | Must Be Explicitly Allowed |
| Applied To     | EC2 / ENI      | Entire Subnet              |

---

# Traffic Flow

```text
Internet
↓
NACL
↓
Security Group
↓
EC2
```

Traffic must pass through both NACL and Security Group.

If either blocks traffic, communication fails.

---

# Common Interview Questions

## Q1. What is the difference between Security Group and NACL?

Answer:

> Security Groups are stateful instance-level firewalls that support only allow rules. NACLs are stateless subnet-level firewalls that support both allow and deny rules.

---

## Q2. Why are Security Groups stateful?

Answer:

> Because once a request is allowed, the corresponding response traffic is automatically allowed.

---

## Q3. Why are NACLs stateless?

Answer:

> Because inbound and outbound traffic are evaluated separately and both must be explicitly allowed.

---

## Q4. Can Security Groups deny traffic?

Answer:

> No. Security Groups support only allow rules. Any traffic not explicitly allowed is implicitly denied.

---

## Q5. Can NACLs deny traffic?

Answer:

> Yes. NACLs support both allow and deny rules.

---

## Q6. Which is evaluated first?

Answer:

```text
Internet
↓
NACL
↓
Security Group
↓
EC2
```

NACL is evaluated first because it operates at the subnet level.

---

## Q7. Security Group allows Port 80 but NACL denies Port 80. What happens?

Answer:

> Traffic is blocked because NACL is evaluated before the Security Group.

---

## Q8. Can EC2 instances in different subnets communicate?

Answer:

> Yes. AWS automatically creates a local route within the VPC. Security Groups, NACLs, and OS firewalls can still block communication.

---

# Troubleshooting Scenarios

## Cannot SSH to EC2

Check:

1. Public IP assigned
2. Route to Internet Gateway
3. Security Group allows Port 22
4. NACL allows Port 22
5. OS Firewall
6. Correct SSH key

---

## Private EC2 Cannot Access Internet

Check:

1. NAT Gateway exists
2. Private subnet route table points to NAT Gateway

```text
0.0.0.0/0 → NAT Gateway
```

3. NAT Gateway subnet route table points to Internet Gateway

```text
0.0.0.0/0 → Internet Gateway
```

4. NACL rules
5. Security Group outbound rules

---

# Quick Revision Before Interview

```text
Security Group
=
Instance Level
=
Stateful
=
Allow Only
=
Implicit Deny

NACL
=
Subnet Level
=
Stateless
=
Allow + Deny

Traffic Flow:
Internet
↓
NACL
↓
Security Group
↓
EC2
```

# 30-Second Interview Answer

> Security Groups are stateful instance-level firewalls that support only allow rules. Response traffic is automatically allowed. NACLs are stateless subnet-level firewalls that support both allow and deny rules. Since NACLs are stateless, inbound and outbound traffic must be explicitly allowed.
