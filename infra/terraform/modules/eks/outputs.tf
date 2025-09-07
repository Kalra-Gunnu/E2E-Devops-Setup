
output "name" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name # Note: The public module's output is 'cluster_name'
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  value = module.eks.cluster_certificate_authority_data
}


output "oidc_provider_url" {
  description = "The OIDC provider URL of the EKS cluster, for use with IRSA."
  # Use try() to safely access the output regardless of its name
  value       = try(module.eks.oidc_provider_url, module.eks.cluster_oidc_issuer_url, "")
}

output "oidc_provider_thumbprint" {
  description = "The thumbprint of the OIDC provider's root certificate."
  # Use try() here as well for safety
  value       = try(module.eks.oidc_provider_thumbprint, module.eks.cluster_oidc_thumbprint, "")
}