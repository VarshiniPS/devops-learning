# -----------------------------------------------------------------------------
# INPUT VARIABLES
#
# Declares every configurable input for this project. Actual values are
# assigned in terraform.tfvars, which Terraform loads automatically.
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used as a prefix for tagging all resources"
  type        = string
  default     = "learning-project"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2023, us-east-1)"
  type        = string
  default     = "ami-0c101f26f147fa7fd"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair to allow SSH access (leave blank if none)"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0"
}
