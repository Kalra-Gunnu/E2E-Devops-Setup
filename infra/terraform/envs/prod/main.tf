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

# IAM / IRSA for ExternalSecrets
/*
module "iam_irsa" {
  source = "../../modules/iam_irsa"
  aws_region = var.aws_region
  cluster_name = module.eks.name
  
  # --- THE CRITICAL FIX ---
  # Pass the values directly from the EKS module outputs
  oidc_provider_url        = module.eks.oidc_provider_url
  oidc_provider_thumbprint = module.eks.oidc_provider_thumbprint # The EKS module provides this output
  
  # ... (other variables like external_secrets_namespace, etc.)
    # Define the Kubernetes namespace for the External Secrets service account.
  external_secrets_namespace = "external-secrets"

  # Define the name of the Kubernetes service account for External Secrets.
  external_secrets_sa = "external-secrets-sa"

  # Tell the module not to use a wildcard for the IAM policy resource.
  external_secrets_arn_wildcard = false

  # Provide the list of specific secrets the role should have access to.
  external_secrets_resources = [
    "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:/app/*"
  ]
  tags = { Environment = local.env }
}
*/

data "aws_caller_identity" "current" {}
