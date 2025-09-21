output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repo_urls
}

output "ecr_repository_names" {
  description = "ECR repository names"
  value       = module.ecr.repo_names
}