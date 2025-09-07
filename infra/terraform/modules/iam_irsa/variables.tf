variable "aws_region" { 
    type = string 
}

variable "cluster_name" { 
    type = string 
}

variable "environment" { 
    type = string
    default = "dev" 
}

variable "external_secrets_namespace" { 
    type = string
    default = "externalsecrets" 
}

variable "external_secrets_sa" { 
    type = string
    default = "external-secrets"
}

variable "external_secrets_resources" { 
    type = list(string)
    default = [] 
}

variable "external_secrets_arn_wildcard" { 
    type = bool
    default = false 
}

variable "tags" { 
    type = map(string)
    default = {} 
}

variable "oidc_provider_url" {
  description = "The OIDC provider URL of the EKS cluster."
  type        = string
}

variable "oidc_provider_thumbprint" {
  description = "The thumbprint of the OIDC provider's root certificate."
  type        = string
}
