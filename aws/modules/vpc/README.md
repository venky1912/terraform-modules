# Terraform AWS VPC Module

This module creates a VPC with public and private subnets, route tables, an internet gateway, and a NAT gateway in AWS.

## Usage

```hcl
module "vpc" {
  source = "./terraform-modules/aws/modules/vpc"

  region          = "us-east-1"
  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
