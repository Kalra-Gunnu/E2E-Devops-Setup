locals {
  env = "prod"
}

# VPC
module "vpc" {
  source  = "../../modules/vpc"
  name    = "app-${local.env}"
  cidr_block = "10.10.0.0/16"
  azs     = ["us-west-2a","us-west-2b","us-west-2c"]
  public_subnet_count = 3
  private_subnet_count = 3
  tags = {
    Environment = local.env
    Project     = "sample-app"
  }
}

# ECR
module "ecr" {
  source = "../../modules/ecr"
  repositories = ["payment","project","user","frontend"]
  tags = { Environment = local.env }
}

# EKS
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "app-${local.env}"
  cluster_version    = "1.27"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  environment        = local.env

  # Replaced 'node_groups' with 'eks_managed_node_groups'
  eks_managed_node_groups = {
    # On-demand instances for core applications
    app = {
      desired_size = 3
      max_size     = 5
      min_size     = 2
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND" # Explicitly setting ON_DEMAND
    },
    # Spot instances for cost savings on workloads that can handle interruptions
    spot = {
      desired_size = 1
      max_size     = 3
      min_size     = 0
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }

  tags = {
    Environment = local.env
  }
}

# IAM / IRSA for ExternalSecrets and other controllers
module "iam_irsa" {
  source = "../../modules/iam_irsa"
  cluster_name = module.eks.cluster_name
  environment = local.env
  tags = { Environment = local.env }
  external_secrets_arn_wildcard = false
  external_secrets_resources = [
    "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:/app/*"
  ]
}

data "aws_caller_identity" "current" {}
