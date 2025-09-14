provider "aws" {
  region = var.aws_region
  # Optionally set profile:
  profile = var.aws_profile != "" ? var.aws_profile : null
}