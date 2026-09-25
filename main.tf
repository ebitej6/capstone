terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
  profile = "jjosh"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs = [
    "${var.aws_region}a",
    "${var.aws_region}b"
  ]

  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  public_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
resource "aws_security_group" "app" {
  name        = "${var.app_name}-security-group"
  description = "Security group allowing HTTP and HTTPS traffic"
  vpc_id      = module.vpc.vpc_id

  # HTTP
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-security-group"
    Environment = var.environment
  }
}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  cluster_security_group_additional_rules = {
    app_ingress = {
      description              = "Allow application traffic"
      protocol                 = "tcp"
      from_port                = 80
      to_port                  = 443
      type                     = "ingress"
      source_security_group_id = aws_security_group.app.id
    }
  }
  eks_managed_node_groups = {
    application = {

      instance_types = [
        var.node_instance_type
      ]

      min_size     = var.node_count
      max_size     = var.node_count + 1
      desired_size = var.node_count

      subnet_ids = module.vpc.private_subnets
      labels = {
        Environment = var.environment
        Application = var.app_name
      }

      tags = {
        Name        = "${var.project_name}-worker"
        Environment = var.environment
      }
    }
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}