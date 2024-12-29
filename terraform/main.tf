terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  required_version = ">=1.3.7"
}

# Default provider for CloudGuru AWS sandbox environment
provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias      = "personal"
  region     = var.aws_region
  access_key = var.personal_aws_access_key
  secret_key = var.personal_aws_secret_key
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

# VPC Module in CloudGuru AWS sandbox
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name                          = "shodapp-vpc"
  cidr                          = var.vpc_cidr
  azs                           = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets               = var.private_subnets
  public_subnets                = var.public_subnets
  enable_nat_gateway            = false
  enable_vpn_gateway            = false
  enable_dns_hostnames          = true
  enable_dns_support            = true
  manage_default_network_acl    = false
  manage_default_security_group = false
  map_public_ip_on_launch       = true
  tags = {
    Name = "shodapp-eks-vpc"
  }
  public_subnet_tags = {
    "Name"                                  = "public"
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/shodapp-cluster" = "shared"
  }

  private_subnet_tags = {
    "Name"                                  = "private"
    "kubernetes.io/role/internal-elb"       = "1"
    "kubernetes.io/cluster/shodapp-cluster" = "shared"
  }
}



# Security Group in CloudGuru AWS sandbox
resource "aws_security_group" "Allow_services" {
  name        = "PROD"
  description = "global rule"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "All traffic_in"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "traffic in HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "traffic in HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All traffic_out"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}