output "vpc_id" {
  description = "VPC id"
  value       = module.vpc.vpc_id
}

output "eks_cluster_id" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "ecr_repos" {
  description = "ECR repository names"
  value       = module.ecr.repo_urls
}