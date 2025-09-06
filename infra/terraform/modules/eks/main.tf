module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 19.0.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids         = var.private_subnet_ids
  vpc_id          = var.vpc_id

  eks_managed_node_groups = var.eks_managed_node_groups

  manage_aws_auth_configmap = true

  tags = merge(var.tags, { Environment = var.environment })
}

# Expose outputs normalized for parent
output "cluster_name" {
  value = module.eks.cluster_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  value = module.eks.cluster_certificate_authority_data
}