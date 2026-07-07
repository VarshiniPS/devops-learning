# -----------------------------------------------------------------------------
# EC2 INSTANCE
#
# The actual server. Placed in the public subnet and attached to the security
# group defined in security.tf. key_name is conditional — if no key pair name
# is supplied via variables, we pass null so Terraform launches the instance
# without SSH key access rather than erroring on an empty string.
# -----------------------------------------------------------------------------

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name != "" ? var.key_name : null

  tags = {
    Name = "${var.project_name}-ec2"
  }
}
