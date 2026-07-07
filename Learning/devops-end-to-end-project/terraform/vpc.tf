# -----------------------------------------------------------------------------
# VPC
#
# The Virtual Private Cloud is the top-level, isolated network container that
# everything else in this project (subnet, gateway, route table, security
# group, EC2 instance) lives inside of.
# -----------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # required for internal DNS resolution
  enable_dns_hostnames = true # required so EC2 instances get DNS hostnames

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
