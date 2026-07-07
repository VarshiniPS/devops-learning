# -----------------------------------------------------------------------------
# PROVIDER CONFIGURATION
#
# Pins the Terraform CLI and AWS provider versions, and configures which
# region the AWS provider talks to (set via var.aws_region in terraform.tfvars).
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
