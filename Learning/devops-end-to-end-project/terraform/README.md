# AWS Terraform Learning Project

A hands-on Terraform project that provisions a basic public network in AWS: a VPC, public subnet, Internet Gateway, route table, security group, and a single EC2 instance.

## Infrastructure

This project creates the following AWS resources:

- **VPC** — an isolated `10.0.0.0/16` network
- **Public Subnet** — `10.0.1.0/24`, with auto-assigned public IPs enabled
- **Internet Gateway** — attached to the VPC to allow internet access
- **Route Table** — routes `0.0.0.0/0` traffic to the Internet Gateway, associated with the public subnet
- **Security Group** — allows inbound SSH (22) and HTTP (80), and all outbound traffic
- **EC2 Instance** — a `t2.micro` instance launched into the public subnet, using the security group above

```
Internet --- Internet Gateway --- Route Table --- Public Subnet --- Security Group --- EC2 Instance
                                                        |
                                                       VPC
```

Full explanation of each resource and the concepts behind them: see [`docs/terraform-notes.md`](docs/terraform-notes.md).

## Terraform Folder

```
terraform/
├── provider.tf        # Terraform + AWS provider configuration
├── variables.tf       # Input variable declarations (types, descriptions, defaults)
├── main.tf             # Core resources: VPC, subnet, IGW, route table, security group, EC2
├── outputs.tf          # Output values (VPC ID, subnet ID, instance public IP, etc.)
└── terraform.tfvars    # Actual values assigned to the variables for this deployment
```

| File | Purpose |
|---|---|
| `provider.tf` | Declares the required Terraform version and AWS provider version; configures the AWS region |
| `variables.tf` | Declares every configurable input (region, CIDR blocks, instance type, AMI, key name, etc.) |
| `main.tf` | The actual infrastructure — every AWS resource in this project |
| `outputs.tf` | Values printed after `apply`, e.g. the EC2 instance's public IP |
| `terraform.tfvars` | Concrete values for the variables (auto-loaded by Terraform, no flag needed) |

## Deployment Sequence

Run these from inside the `terraform/` folder, in order:

1. **Configure AWS credentials** (once, outside of Terraform):
   ```bash
   aws configure
   ```

2. **Initialize the working directory** — downloads the AWS provider plugin:
   ```bash
   terraform init
   ```

3. **Validate the configuration** — checks syntax and internal consistency (no AWS credentials required):
   ```bash
   terraform validate
   ```

4. **Preview the execution plan** — shows exactly what will be created, with no changes made yet:
   ```bash
   terraform plan
   ```

5. **Apply the configuration** — actually creates the resources in AWS *(not run yet in this project)*:
   ```bash
   terraform apply
   ```

6. **Tear down when done** — destroys everything created, to avoid ongoing AWS costs:
   ```bash
   terraform destroy
   ```

## Status

- [x] `terraform/` files written
- [x] `terraform init`, `validate`, `plan` — instructions documented (see `docs/terraform-notes.md`)
- [ ] `terraform apply` — not yet run
- [ ] `terraform destroy` — not yet run

## Notes

See [`docs/terraform-notes.md`](docs/terraform-notes.md) for a deeper walkthrough of each resource, key Terraform concepts, and gotchas encountered while building this.