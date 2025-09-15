variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "The AWS profile to use for authentication. Leave blank for default."
  type        = string
  default     = ""
}

variable "tfstate_bucket" {
  description = "The S3 bucket for storing Terraform state."
  type        = string
}

variable "tfstate_lock_table" {
  description = "The DynamoDB table for state locking."
  type        = string
}

variable "oidc_provider_thumbprint" {
  description = "The thumbprint for the OIDC provider."
  type        = string
  
}