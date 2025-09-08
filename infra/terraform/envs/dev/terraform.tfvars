# AWS Configuration
aws_region  = "us-west-2"
aws_profile = "" # Or specify a profile, e.g., "my-dev-profile"

# Terraform Remote State Configuration
# IMPORTANT: Replace these with your actual S3 bucket and DynamoDB table names
tfstate_bucket     = "your-dev-tf-state-bucket"
tfstate_lock_table = "your-dev-tf-locks-table"
