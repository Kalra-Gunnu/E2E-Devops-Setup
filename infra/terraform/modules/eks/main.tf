module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  # It's a best practice to pin to a major version to avoid unexpected breaking changes
  version = ">= 19.0.0"

  # --- CORRECTED ARGUMENTS ---
  name               = var.cluster_name       # Renamed from cluster_name
  kubernetes_version = var.cluster_version    # Renamed from cluster_version
  # 'manage_aws_auth_configmap' is removed. The module now handles auth via access entries.

  vpc_id                  = var.vpc_id
  subnet_ids              = var.private_subnet_ids # Note: This is for both control plane and nodes by default

  eks_managed_node_groups = var.eks_managed_node_groups
  
  # This new setting is recommended. It automatically gives the IAM identity
  # that creates the cluster admin permissions, which is often what you want.
  enable_cluster_creator_admin_permissions = true

  tags = merge(var.tags, { Environment = var.environment })
}