# -----------------------------------------------------------------------------
# PUBLIC SUBNET
#
# A slice of the VPC's IP range. `map_public_ip_on_launch = true` means any
# instance launched into this subnet automatically gets a public IP — this is
# one of two things (along with the route to the Internet Gateway below) that
# makes this subnet "public."
# -----------------------------------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# -----------------------------------------------------------------------------
# INTERNET GATEWAY
#
# Attached to the VPC (not the subnet) — this is the VPC's door to the public
# internet. On its own it does nothing; a route table must point traffic at it.
# -----------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# -----------------------------------------------------------------------------
# ROUTE TABLE + ASSOCIATION
#
# Defines the rule "anything not destined for the VPC's own CIDR range
# (0.0.0.0/0) should be sent out through the Internet Gateway," then attaches
# that rule to the public subnet. This is the second piece (with
# map_public_ip_on_launch above) that makes the subnet genuinely "public."
# -----------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
