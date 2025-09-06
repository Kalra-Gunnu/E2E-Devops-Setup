variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "aws_profile" {
  description = "Optional AWS CLI profile"
  type        = string
  default     = ""
}

variable "env_name" {
  description = "Environment name: dev/staging/prod"
  type        = string
  default     = "dev"
}

variable "tfstate_bucket" {
  description = "S3 bucket for terraform remote state"
  type        = string
  default     = "app-tf-state-<REPLACE_ME>"
}

variable "tfstate_lock_table" {
  description = "DynamoDB table for terraform state lock"
  type        = string
  default     = "app-tf-locks-<REPLACE_ME>"
}