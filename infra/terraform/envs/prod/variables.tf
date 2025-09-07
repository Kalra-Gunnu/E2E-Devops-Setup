variable "aws_region" { 
    type = string 
}

variable "aws_profile" {
  description = "The AWS profile to use for authentication. Leave blank to use default credentials."
  type        = string
  default     = ""
}

variable "env_name" {
  description = "The name of the environment (e.g., prod, dev)."
  type        = string
  # No default, as this should be explicitly set for each environment.
}

variable "tfstate_bucket" {
  description = "The name of the S3 bucket for storing Terraform remote state."
  type        = string
  # No default, as this must be a unique name.
}

variable "tfstate_lock_table" {
  description = "The name of the DynamoDB table for Terraform state locking."
  type        = string
  # No default, as this must be a unique name.
}