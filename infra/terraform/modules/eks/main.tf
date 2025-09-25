module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  # It's a best practice to pin to a major version to avoid unexpected breaking changes
  version = "21.3.1"

  # --- CORRECTED ARGUMENTS ---
  name    = var.cluster_name       # Renamed from cluster_name
  kubernetes_version = var.cluster_version    # Renamed from cluster_version

  vpc_id                  = var.vpc_id
  subnet_ids              = var.public_subnet_ids # Note: This is for both control plane and nodes by default

  create_kms_key = false

  encryption_config = {
    provider_key_arn = "arn:aws:kms:us-west-2:975050024946:key/*" # Add your KMS key ARN here if you set create_kms_key to true
  }

  eks_managed_node_groups = var.eks_managed_node_groups
    enable_cluster_creator_admin_permissions = true


  tags = merge(var.tags, { Environment = var.environment })
}