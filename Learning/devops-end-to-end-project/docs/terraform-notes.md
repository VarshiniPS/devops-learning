# Terraform Notes

Personal notes from building the AWS networking + EC2 project in `terraform/`.

## What this project builds

A minimal, self-contained public network in AWS:

```
Internet
   |
Internet Gateway
   |
Route Table (0.0.0.0/0 -> IGW)
   |
Public Subnet (10.0.1.0/24)
   |
Security Group (22, 80 in / all out)
   |
EC2 Instance
```

All of it lives inside one VPC (`10.0.0.0/16`).

## Resource-by-resource

| Resource | Terraform type | Purpose |
|---|---|---|
| VPC | `aws_vpc` | Isolated network space; everything else lives inside it |
| Public Subnet | `aws_subnet` | A slice of the VPC's IP range; `map_public_ip_on_launch = true` so instances launched here get a public IP automatically |
| Internet Gateway | `aws_internet_gateway` | The VPC's door to the internet; attached to the VPC, not the subnet |
| Route Table | `aws_route_table` + `aws_route_table_association` | The rule "anything not in the VPC (0.0.0.0/0) goes out through the IGW," then wired to the public subnet |
| Security Group | `aws_security_group` | Instance-level firewall — allowed SSH (22) and HTTP (80) in, everything out |
| EC2 Instance | `aws_instance` | The actual server, placed in the public subnet, using the security group |

## Key concepts I want to remember

- **Implicit dependency graph.** I never wrote "create the subnet after the VPC." Referencing `aws_vpc.main.id` inside `aws_subnet` is enough — Terraform builds the dependency order from these references automatically.
- **A subnet becomes "public" for two reasons together**, not one:
  1. It has a route to an Internet Gateway (via the route table association).
  2. Instances in it get a public IP (`map_public_ip_on_launch = true`).
  Missing either one and the subnet isn't really public.
- **Security groups are stateful.** I only had to open port 22/80 inbound — return traffic is automatically allowed back out, so I didn't need a matching inbound rule for responses.
- **Variables vs. tfvars.** `variables.tf` *declares* what inputs exist (name, type, description, optional default). `terraform.tfvars` *assigns* the actual values for this specific deployment. Terraform loads `terraform.tfvars` automatically without needing a `-var-file` flag, because of its exact filename.
- **Outputs are for humans (and other tools).** They don't change what gets built; they just surface values (like the instance's public IP) after `apply` so I'm not digging through the AWS console.

## Command sequence and what each one actually checks

| Command | What it needs | What it verifies |
|---|---|---|
| `terraform init` | Internet access | Downloads the AWS provider plugin; sets up local `.terraform/` state |
| `terraform validate` | Nothing (no AWS creds needed) | Syntax is correct, internal references resolve, types match |
| `terraform plan` | AWS credentials | Compares config against real AWS state; shows what *would* change |
| `terraform apply` | AWS credentials | Actually creates/changes/destroys resources (not run yet in this project) |

## Gotchas I ran into / should watch for

- The AMI ID is **region-specific**. The default I used only exists in `us-east-1`. If I change `aws_region`, I have to look up a matching AMI or `plan`/`apply` will fail.
- `key_name` is blank by default, so there's currently no way to SSH into the instance until I set it to a real key pair name that already exists in my AWS account.
- `ssh_allowed_cidr` defaults to `0.0.0.0/0` (open to the whole internet) — fine for a learning sandbox, but I would never leave this open on anything real. Should narrow it to my own IP (`x.x.x.x/32`) before doing this for real.

## Next steps (not done yet)

- [ ] Run `terraform apply` in a disposable AWS account/sandbox
- [ ] Confirm I can reach the instance over SSH/HTTP
- [ ] Run `terraform destroy` to tear it back down and confirm no orphaned resources
- [ ] Try tightening `ssh_allowed_cidr` to a single IP and re-plan